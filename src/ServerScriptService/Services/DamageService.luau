--!strict
-- All damage to players goes through here. A hit that would kill leaves the player downed instead:
-- they lie on the ground for as long as it takes until a teammate holding a Bandage lifts them up
-- (later also a Robux self-revive, see MonetizationConfig). When nobody is left standing the match is lost.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Locale = require(ReplicatedStorage.Shared.Locale)
local SfxService = require(script.Parent.SfxService)
local CharacterUtil = require(script.Parent.CharacterUtil)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Net)
local MonetizationService = require(script.Parent.MonetizationService)
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

local function clearDowned(player: Player, restore: boolean)
	local state = downed[player]
	if not state then
		return
	end
	downed[player] = nil
	player:SetAttribute("Downed", nil)
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

type Listener = () -> ()
local allDownListeners: { Listener } = {}

-- Fires once when every player in the server is down: the match is lost.
function DamageService.OnAllDown(listener: Listener)
	table.insert(allDownListeners, listener)
end

local function checkAllDown()
	if #Players:GetPlayers() == 0 then
		return
	end
	for _, player in Players:GetPlayers() do
		-- A player between characters (respawning) is not lying down, so they do not end the match.
		if not downed[player] then
			return
		end
	end
	for _, listener in allDownListeners do
		task.spawn(listener)
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

	player:SetAttribute("Downed", true)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Net.Notify(other, { "downed.someone", player.DisplayName }, "warning")
		end
	end
	checkAllDown()
end

-- Lifts a downed player back up. Used by teammates with a Bandage and by the future Robux self-revive.
function DamageService.Revive(player: Player): boolean
	local state = downed[player]
	if not state then
		return false
	end
	local humanoid = state.character:FindFirstChildOfClass("Humanoid")
	clearDowned(player, true)
	if humanoid then
		humanoid.Health = math.max(humanoid.Health, GameConfig.ReviveHealth)
	end
	return true
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
	if amount >= 5 then
		SfxService.PlayAtPlayer("Hurt", player, 0.7)
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
	DamageService.Revive(target)
	SfxService.PlayAtPlayer("Bandage", target)
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
		-- The last one standing leaving also ends the match for the others.
		task.defer(checkAllDown)
	end)
	MonetizationService.RegisterProductHandler("SelfRevive", function(player)
		return DamageService.Revive(player)
	end)
end

return DamageService
