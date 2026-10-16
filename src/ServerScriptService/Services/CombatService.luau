--!strict
-- Melee combat. A weapon is in the player's hands only while it is selected in the hotbar (Equip remote);
-- selecting it again puts it away. The client only asks to swing; the server checks the cooldown and
-- hits zombies in front of the player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local CharacterUtil = require(script.Parent.CharacterUtil)
local DamageService = require(script.Parent.DamageService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local PropLibrary = require(script.Parent.Parent.PropLibrary)
local RateLimiter = require(script.Parent.RateLimiter)
local ZombieService = require(script.Parent.ZombieService)

local CombatService = {}

local TOOL_NAME = "Weapon"
local lastSwing: { [Player]: number } = {}
local held: { [Player]: string } = {}
local equipped: { [Player]: string } = {}

local MESHES: { [string]: { prop: string, length: number } } = {
	Club = { prop = "WeaponClub", length = 3.4 },
	Pipe = { prop = "WeaponPipe", length = 3.7 },
	Machete = { prop = "WeaponMachete", length = 3.4 },
}

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

-- The weapon in the player's hands, if they still carry it.
local function equippedWeapon(player: Player): ItemDefinitions.ItemDef?
	local id = equipped[player]
	local data = PlayerDataService.Get(player)
	if not id or not data or (data.inventory[id] or 0) <= 0 then
		return nil
	end
	local def = ItemDefinitions.Get(id)
	return if def and def.weapon then def else nil
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

local function makeTool(weaponId: string): Tool
	local look = LOOKS[weaponId] or LOOKS.Club
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = ""
	tool:SetAttribute("WeaponId", weaponId)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	if attachMesh(tool, handle, weaponId) then
		-- The mesh is the look; the handle is just the point the hand holds.
		handle.Size = Vector3.new(0.3, 0.3, 0.3)
		handle.Transparency = 1
		tool.Grip = CFrame.new()
	else
		handle.Size = look.size
		handle.Color = look.color
		handle.Material = look.material
		tool.Grip = CFrame.new(0, 0, look.size.Z / 2 - 0.4)
	end
	return tool
end

-- Puts the right weapon in the player's hands. Cheap to call often.
local function refreshTool(player: Player)
	local character = player.Character
	if not character or not CharacterUtil.GetHumanoid(player) then
		return
	end
	local def = equippedWeapon(player)
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
	local def = equippedWeapon(player)
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

-- Hotbar selection: equip this weapon, or put it away when it is already in hand (or itemId is nil).
local function equip(player: Player, itemId: any)
	local def = if type(itemId) == "string" then ItemDefinitions.Get(itemId) else nil
	if not def or not def.weapon or equipped[player] == itemId then
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
