--!strict
-- Melee combat. Every player holds the best weapon they carry (a Tool the server keeps in their hands);
-- the client only asks to swing, the server checks the cooldown and hits zombies in front of the player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local CharacterUtil = require(script.Parent.CharacterUtil)
local DamageService = require(script.Parent.DamageService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local ZombieService = require(script.Parent.ZombieService)

local CombatService = {}

local TOOL_NAME = "Weapon"
local lastSwing: { [Player]: number } = {}
local held: { [Player]: string } = {}

-- Simple shapes for each weapon so it reads in the hand without any mesh assets.
local LOOKS: { [string]: { size: Vector3, color: Color3, material: Enum.Material } } = {
	Club = { size = Vector3.new(0.5, 0.5, 3.4), color = Color3.fromRGB(120, 84, 52), material = Enum.Material.Wood },
	Pipe = { size = Vector3.new(0.4, 0.4, 3.8), color = Color3.fromRGB(130, 135, 140), material = Enum.Material.Metal },
	Machete = {
		size = Vector3.new(0.15, 0.7, 3.6),
		color = Color3.fromRGB(200, 205, 212),
		material = Enum.Material.Metal,
	},
}

local function bestWeapon(player: Player): ItemDefinitions.ItemDef?
	local data = PlayerDataService.Get(player)
	return data and ItemDefinitions.BestWeapon(data.inventory)
end

local function makeTool(weaponId: string): Tool
	local look = LOOKS[weaponId] or LOOKS.Club
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = weaponId
	tool:SetAttribute("WeaponId", weaponId)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = look.size
	handle.Color = look.color
	handle.Material = look.material
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	-- Hold it by one end, pointing forward.
	tool.Grip = CFrame.new(0, 0, look.size.Z / 2 - 0.4) * CFrame.Angles(0, 0, 0)
	return tool
end

-- Puts the right weapon in the player's hands. Cheap to call often.
local function refreshTool(player: Player)
	local character = player.Character
	if not character or not CharacterUtil.GetHumanoid(player) then
		return
	end
	local def = bestWeapon(player)
	local current = character:FindFirstChild(TOOL_NAME)
	if not def then
		if current then
			current:Destroy()
		end
		held[player] = nil
		return
	end
	if current and current:GetAttribute("WeaponId") == def.id then
		return
	end
	if current then
		current:Destroy()
	end
	-- Anything sitting in the Backpack (Roblox moves unequipped tools there) is ours too; clear it.
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, t in backpack:GetChildren() do
			if t.Name == TOOL_NAME then
				t:Destroy()
			end
		end
	end
	makeTool(def.id).Parent = character
	held[player] = def.id
end

local function swing(player: Player)
	if DamageService.IsDowned(player) then
		return
	end
	local def = bestWeapon(player)
	local weapon = def and def.weapon
	local root = CharacterUtil.GetRoot(player)
	if not def or not weapon or not root then
		return
	end
	local now = os.clock()
	if lastSwing[player] and now - lastSwing[player] < weapon.cooldown then
		return
	end
	lastSwing[player] = now

	-- The classic Animate script plays a slash when a StringValue "toolanim" appears in the held tool.
	local tool = player.Character and player.Character:FindFirstChild(TOOL_NAME)
	if tool then
		local anim = Instance.new("StringValue")
		anim.Name = "toolanim"
		anim.Value = "Slash"
		anim.Parent = tool
		task.delay(0.3, function()
			anim:Destroy()
		end)
	end

	local look = root.CFrame.LookVector
	for _, z in ZombieService.All() do
		if z.humanoid.Health > 0 then
			local offset = z.root.Position - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if flat.Magnitude <= weapon.range and math.abs(offset.Y) < 5 then
				local facing = if flat.Magnitude > 0.1 then look:Dot(flat.Unit) else 1
				if facing > 0.2 then
					z.humanoid:TakeDamage(weapon.damage)
					-- A little shove so hits feel solid.
					z.root.AssemblyLinearVelocity += flat.Unit * 25 + Vector3.new(0, 8, 0)
				end
			end
		end
	end
end

function CombatService.OnCharacterAdded(player: Player)
	held[player] = nil
	task.defer(refreshTool, player)
end

function CombatService.Start()
	Net.Get(RemoteNames.Attack).OnServerEvent:Connect(swing)
	-- Inventory changes (a found Pipe, a crafted Machete) swap the weapon in hand within a second.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				refreshTool(player)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
		held[player] = nil
	end)
end

return CombatService
