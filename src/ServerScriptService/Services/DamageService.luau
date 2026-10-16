--!strict
-- All damage to players goes through here. A hit that would kill leaves the player downed instead:
-- they lie on the ground, a teammate holding a Bandage can lift them up, and if nobody does before the
-- bleed-out timer ends they die for real and respawn on the roof (PlayerLifecycleService handles that).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Locale = require(ReplicatedStorage.Shared.Locale)
local CharacterUtil = require(script.Parent.CharacterUtil)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Net)
local RateLimiter = require(script.Parent.RateLimiter)

local DamageService = {}

type DownedState = {
	character: Model,
	prompt: ProximityPrompt,
	walkSpeed: number,
	jumpHeight: number,
	token: number,
}

local downed: { [Player]: DownedState } = {}
local tokens = 0
local PROMPT_NAME = "RevivePrompt"

function DamageService.IsDowned(player: Player): boolean
	return downed[player] ~= nil
end

local function othersAlive(player: Player): boolean
	for _, other in Players:GetPlayers() do
		if other ~= player and not downed[other] and CharacterUtil.GetHumanoid(other) then
			return true
		end
	end
	return false
end

local function clearDowned(player: Player, restore: boolean)
	local state = downed[player]
	if not state then
		return
	end
	downed[player] = nil
	player:SetAttribute("Downed", nil)
	player:SetAttribute("BleedOut", nil)
	if state.prompt.Parent then
		state.prompt:Destroy()
	end
	local humanoid = state.character:FindFirstChildOfClass("Humanoid")
	if humanoid and restore then
		humanoid.PlatformStand = false
		humanoid.WalkSpeed = state.walkSpeed
		humanoid.JumpHeight = state.jumpHeight
	end
end

local function bleedOut(player: Player, state: DownedState)
	if downed[player] ~= state then
		return
	end
	clearDowned(player, false)
	local humanoid = state.character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end

local function goDown(player: Player, humanoid: Humanoid)
	local character = humanoid.Parent :: Model
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		humanoid.Health = 0
		return
	end
	tokens += 1
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.ActionText = Locale.T("en", "revive.action")
	prompt.ObjectText = player.DisplayName
	prompt:SetAttribute("ActionKey", "revive.action")
	prompt:SetAttribute("ReviveUserId", player.UserId)
	prompt.HoldDuration = GameConfig.ReviveHoldSeconds
	prompt.MaxActivationDistance = GameConfig.PromptActivationDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	local state: DownedState = {
		character = character,
		prompt = prompt,
		walkSpeed = humanoid.WalkSpeed,
		jumpHeight = humanoid.JumpHeight,
		token = tokens,
	}
	downed[player] = state
	humanoid.Health = 1
	humanoid.WalkSpeed = 0
	humanoid.JumpHeight = 0
	humanoid.PlatformStand = true -- the body topples over and lies there

	local seconds = if othersAlive(player) then GameConfig.BleedOutSeconds else GameConfig.SoloBleedOutSeconds
	player:SetAttribute("Downed", true)
	player:SetAttribute("BleedOut", seconds)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Net.Notify(other, { "downed.someone", player.DisplayName }, "warning")
		end
	end
	task.spawn(function()
		local left = seconds
		while left > 0 and downed[player] == state do
			task.wait(1)
			left -= 1
			if downed[player] == state then
				player:SetAttribute("BleedOut", left)
			end
		end
		bleedOut(player, state)
	end)
end

-- Damage a player. Never kills outright: a lethal hit leaves them downed.
function DamageService.Damage(player: Player, amount: number)
	if amount <= 0 or downed[player] then
		return
	end
	local humanoid = CharacterUtil.GetHumanoid(player)
	if not humanoid then
		return
	end
	if humanoid.Health - amount > 1 then
		humanoid:TakeDamage(amount)
	else
		goDown(player, humanoid)
	end
end

local function tryRevive(prompt: ProximityPrompt, rescuer: Player)
	if prompt.Name ~= PROMPT_NAME then
		return
	end
	local userId = prompt:GetAttribute("ReviveUserId")
	local target = if type(userId) == "number" then Players:GetPlayerByUserId(userId) else nil
	local state = target and downed[target]
	if not target or not state or target == rescuer or downed[rescuer] then
		return
	end
	if not RateLimiter.Allow(rescuer, "Revive", 1) then
		return
	end
	local root = prompt.Parent
	if
		not root
		or not root:IsA("BasePart")
		or not CharacterUtil.IsNear(rescuer, root, GameConfig.InteractionDistance)
	then
		Net.Notify(rescuer, "err.tooFar", "warning")
		return
	end
	if not InventoryService.Remove(rescuer, "Bandage", 1) then
		Net.Notify(rescuer, "revive.needBandage", "warning")
		return
	end
	local humanoid = state.character:FindFirstChildOfClass("Humanoid")
	clearDowned(target, true)
	if humanoid then
		humanoid.Health = math.max(humanoid.Health, GameConfig.ReviveHealth)
	end
	Net.Notify(target, { "revive.revivedBy", rescuer.DisplayName }, "success")
	Net.Notify(rescuer, { "revive.youRevived", target.DisplayName }, "success")
end

-- A fresh character is never downed.
function DamageService.OnCharacterAdded(player: Player)
	clearDowned(player, false)
end

function DamageService.Start()
	ProximityPromptService.PromptTriggered:Connect(tryRevive)
	Players.PlayerRemoving:Connect(function(player)
		clearDowned(player, false)
	end)
end

return DamageService
