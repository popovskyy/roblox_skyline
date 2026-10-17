--!strict
-- What the player holds, and melee combat. The item selected in the hotbar (Equip remote) is in the
-- player's hands; selecting it again puts it away. Only weapons swing: the client asks, the server checks
-- the cooldown and hits zombies in front of the player. Resources never go into the hands.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local SfxService = require(script.Parent.SfxService)
local CharacterUtil = require(script.Parent.CharacterUtil)
local DamageService = require(script.Parent.DamageService)
local MatchStatsService = require(script.Parent.MatchStatsService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local PropLibrary = require(script.Parent.Parent.PropLibrary)
local RateLimiter = require(script.Parent.RateLimiter)
local ZombieService = require(script.Parent.ZombieService)

local CombatService = {}

local TOOL_NAME = "Held"
local lastSwing: { [Player]: number } = {}
local held: { [Player]: string } = {}
local equipped: { [Player]: string } = {}

local MESHES: { [string]: { prop: string, length: number } } = {
	Club = { prop = "WeaponClub", length = 3.4 },
	Pipe = { prop = "WeaponPipe", length = 3.7 },
	Machete = { prop = "WeaponMachete", length = 3.4 },
}

-- Simple shapes for everything without a mesh, so it reads in the hand.
local LOOKS: { [string]: { size: Vector3, color: Color3, material: Enum.Material } } = {
	Food = { size = Vector3.new(0.6, 0.8, 0.6), color = Color3.fromRGB(170, 60, 45), material = Enum.Material.Metal },
	Medkit = {
		size = Vector3.new(0.9, 0.6, 0.4),
		color = Color3.fromRGB(225, 222, 210),
		material = Enum.Material.Plastic,
	},
	Bandage = {
		size = Vector3.new(0.5, 0.5, 0.5),
		color = Color3.fromRGB(230, 220, 195),
		material = Enum.Material.Fabric,
	},
	Flashlight = {
		size = Vector3.new(0.35, 0.35, 1.2),
		color = Color3.fromRGB(60, 62, 66),
		material = Enum.Material.Metal,
	},
	Crowbar = { size = Vector3.new(0.2, 0.2, 3.2), color = Color3.fromRGB(150, 45, 40), material = Enum.Material.Metal },
	Club = { size = Vector3.new(0.5, 0.5, 3.4), color = Color3.fromRGB(120, 84, 52), material = Enum.Material.Wood },
	Pipe = { size = Vector3.new(0.4, 0.4, 3.8), color = Color3.fromRGB(130, 135, 140), material = Enum.Material.Metal },
	Machete = {
		size = Vector3.new(0.15, 0.7, 3.6),
		color = Color3.fromRGB(200, 205, 212),
		material = Enum.Material.Metal,
	},
}

-- The item in the player's hands, if they still carry it.
local function equippedItem(player: Player): ItemDefinitions.ItemDef?
	local id = equipped[player]
	local data = PlayerDataService.Get(player)
	if not id or not data or (data.inventory[id] or 0) <= 0 then
		return nil
	end
	return ItemDefinitions.Get(id)
end

local function equippedWeapon(player: Player): ItemDefinitions.ItemDef?
	local def = equippedItem(player)
	return if def and def.weapon then def else nil
end

-- Where the held item sits relative to the right hand. A weapon comes out of the fist like a real grip
-- (forward and a little up while the arm hangs), not as an extension of the arm.
local WEAPON_IN_HAND = CFrame.new(0, -0.25, -0.05) * CFrame.Angles(math.rad(20), 0, 0)
local ITEM_IN_HAND = CFrame.new(0, -0.35, -0.15)

-- Tool.Grip that puts the handle at `inHand` in the hand's space, whatever the rig's grip attachment is.
local function gripFor(character: Model, inHand: CFrame): CFrame
	local hand = character:FindFirstChild("RightHand")
	local attachment = hand and hand:FindFirstChild("RightGripAttachment")
	local attach = if attachment and attachment:IsA("Attachment") then attachment.CFrame else CFrame.new()
	-- handle = hand * attach * Grip:Inverse() = hand * inHand
	return inHand:Inverse() * attach
end

-- Lines the Blender mesh up with the tool: grip marker on the handle, the weapon pointing forward.
local function attachMesh(tool: Tool, handle: BasePart, weaponId: string): boolean
	local info = MESHES[weaponId]
	local model = info and PropLibrary.Raw(info.prop, false)
	if not model then
		return false
	end
	local grip: BasePart? = nil
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and string.find(part.Name, "_Grip_") then
			grip = part
		end
	end
	local boxCFrame, boxSize = model:GetBoundingBox()
	local longest = math.max(boxSize.X, boxSize.Y, boxSize.Z)
	model.WorldPivot = boxCFrame
	model:ScaleTo(info.length / longest)
	local center = model:GetBoundingBox().Position
	local gripPos = if grip then grip.Position else center
	local along = (center - gripPos)
	local forward = if along.Magnitude > 0.05 then along.Unit else boxCFrame.LookVector
	-- Rotate so `forward` matches the handle's look vector, then move the grip onto the handle.
	local current = CFrame.lookAt(gripPos, gripPos + forward)
	local target = handle.CFrame
	local delta = target * current:Inverse()
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			part.CFrame = delta * part.CFrame
			part.Anchored = false
			part.Massless = true
			part.CanCollide = false
			part.CanQuery = false
			if part == grip then
				part.Transparency = 1
			end
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = part
			weld.Parent = part
			part.Parent = tool
		end
	end
	model:Destroy()
	return true
end

local function makeTool(character: Model, def: ItemDefinitions.ItemDef): Tool
	local weaponId = def.id
	local look = LOOKS[weaponId]
		or { size = Vector3.new(0.6, 0.6, 0.6), color = def.color, material = Enum.Material.Plastic }
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	-- Clients handle tap / click / R2 themselves (CombatController.attackInput).
	tool.ManualActivationOnly = true
	tool.ToolTip = ""
	tool:SetAttribute("ItemId", weaponId)
	tool:SetAttribute("Weapon", def.weapon ~= nil)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	if attachMesh(tool, handle, weaponId) then
		-- The mesh is the look; the handle is just the point the hand holds.
		handle.Size = Vector3.new(0.3, 0.3, 0.3)
		handle.Transparency = 1
		tool.Grip = gripFor(character, WEAPON_IN_HAND)
	else
		handle.Size = look.size
		handle.Color = look.color
		handle.Material = look.material
		local inHand = if def.weapon or weaponId == "Crowbar"
			then WEAPON_IN_HAND * CFrame.new(0, 0, -(look.size.Z / 2 - 0.4))
			else ITEM_IN_HAND
		tool.Grip = gripFor(character, inHand)
	end
	return tool
end

-- Puts the selected item in the player's hands. Cheap to call often.
local function refreshTool(player: Player)
	local character = player.Character
	if not character or not CharacterUtil.GetHumanoid(player) then
		return
	end
	-- Used up the last one: it is no longer selected (picking up more does not put it back in hand).
	if equipped[player] and not equippedItem(player) then
		equipped[player] = nil
		player:SetAttribute("Equipped", nil)
	end
	local def = if DamageService.IsDowned(player) then nil else equippedItem(player)
	local current = character:FindFirstChild(TOOL_NAME)
	if not def then
		if current then
			current:Destroy()
		end
		held[player] = nil
		return
	end
	if current and current:GetAttribute("ItemId") == def.id then
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
	makeTool(character, def).Parent = character
	held[player] = def.id
end

local function swing(player: Player)
	if DamageService.IsDowned(player) then
		return
	end
	local def = equippedWeapon(player)
	local root = CharacterUtil.GetRoot(player)
	if not root then
		return
	end
	-- Nothing in hand: punch. Holding a non-weapon item: the tap uses the item instead.
	if not def and equippedItem(player) then
		return
	end
	local weapon = if def and def.weapon then def.weapon else GameConfig.Fists
	local now = os.clock()
	-- A little slack so swings that arrive bunched up by lag still count.
	if lastSwing[player] and now - lastSwing[player] < weapon.cooldown - 0.12 then
		return
	end
	lastSwing[player] = now
	-- The swing animation is played by the swinging player's client (it replicates to everyone).

	SfxService.Play("Swing", root, 0.8)
	local look = root.CFrame.LookVector
	for _, z in ZombieService.All() do
		if z.humanoid.Health > 0 then
			local offset = z.root.Position - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if flat.Magnitude <= weapon.range and math.abs(offset.Y) < 5 then
				local facing = if flat.Magnitude > 0.1 then look:Dot(flat.Unit) else 1
				if facing > 0.2 then
					local wasAlive = z.humanoid.Health > 0
					z.humanoid:TakeDamage(weapon.damage)
					if wasAlive and z.humanoid.Health <= 0 then
						MatchStatsService.KilledZombie(player)
					end
					SfxService.Play("HitBlunt", z.root)
					-- A little shove so hits feel solid.
					local push = if flat.Magnitude > 0.1 then flat.Unit else look
					z.root.AssemblyLinearVelocity += push * 25 + Vector3.new(0, 8, 0)
				end
			end
		end
	end
end

function CombatService.OnCharacterAdded(player: Player)
	held[player] = nil
	task.defer(refreshTool, player)
end

-- Hotbar selection: take this item in hand, or put it away when it is already there (or itemId is nil).
local function equip(player: Player, itemId: any)
	local def = if type(itemId) == "string" then ItemDefinitions.Get(itemId) else nil
	if not def or def.resource or equipped[player] == itemId then
		equipped[player] = nil
	else
		local data = PlayerDataService.Get(player)
		if not data or (data.inventory[def.id] or 0) <= 0 then
			return
		end
		equipped[player] = def.id
	end
	player:SetAttribute("Equipped", equipped[player])
	refreshTool(player)
end

function CombatService.Start()
	Net.Get(RemoteNames.Attack).OnServerEvent:Connect(swing)
	Net.Get(RemoteNames.Equip).OnServerEvent:Connect(function(player, itemId)
		if RateLimiter.Allow(player, "Equip", 0.2) then
			equip(player, itemId)
		end
	end)
	-- Losing the equipped weapon (game reset) clears the hands within a second.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				refreshTool(player)
				-- Teammates' downed screens show who can lift them.
				local data = PlayerDataService.Get(player)
				player:SetAttribute("HasBandage", data ~= nil and (data.inventory.Bandage or 0) > 0)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
		held[player] = nil
		equipped[player] = nil
	end)
end

return CombatService
