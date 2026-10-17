--!strict
-- Flashlight: the server owns the on/off state, the battery and the light on the character.
-- The battery drains while on and charges next to the player's built Generator.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local CharacterUtil = require(script.Parent.CharacterUtil)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateSyncService = require(script.Parent.StateSyncService)

local FlashlightService = {}

local BEAM_NAME = "FlashlightBeam"
local TICK = 0.5

local isOn: { [Player]: boolean } = {}
local generatorPart: BasePart? = nil

function FlashlightService.SetGeneratorPart(part: BasePart)
	generatorPart = part
end

local function getBeam(player: Player, create: boolean): SpotLight?
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return nil
	end
	local beam = head:FindFirstChild(BEAM_NAME)
	if beam and beam:IsA("SpotLight") then
		return beam
	end
	if not create then
		return nil
	end
	local light = Instance.new("SpotLight")
	light.Name = BEAM_NAME
	light.Brightness = 3
	light.Range = 40
	light.Angle = 70
	light.Face = Enum.NormalId.Front
	light.Shadows = true
	light.Color = Color3.fromRGB(255, 240, 210)
	light.Enabled = false
	light.Parent = head
	return light
end

local function apply(player: Player)
	local on = isOn[player] == true
	player:SetAttribute("FlashlightOn", on)
	local beam = getBeam(player, on)
	if beam then
		beam.Enabled = on
	end
end

function FlashlightService.SetOn(player: Player, on: boolean)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end
	if on then
		if not InventoryService.Has(player, "Flashlight", 1) then
			Net.Notify(player, "flash.none", "warning")
			return
		end
		if data.flashlightCharge <= 0 then
			Net.Notify(player, "flash.empty", "warning")
			return
		end
	end
	isOn[player] = on
	apply(player)
end

function FlashlightService.Toggle(player: Player)
	FlashlightService.SetOn(player, not isOn[player])
end

-- Called after a respawn so the new character gets the light again.
function FlashlightService.OnCharacterAdded(player: Player)
	isOn[player] = false
	apply(player)
end

local function nearGenerator(player: Player): boolean
	local data = PlayerDataService.Get(player)
	return data ~= nil
		and data.upgrades.Generator == true
		and generatorPart ~= nil
		and CharacterUtil.IsNear(player, generatorPart, GameConfig.FlashlightChargeRadius)
end

local function tick(player: Player, dt: number)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end
	local before = math.floor(data.flashlightCharge)
	if isOn[player] then
		if not InventoryService.Has(player, "Flashlight", 1) then
			isOn[player] = false
			apply(player)
		else
			data.flashlightCharge = math.max(0, data.flashlightCharge - dt)
			if data.flashlightCharge <= 0 then
				isOn[player] = false
				apply(player)
				Net.Notify(player, "flash.drained", "warning")
			end
		end
	elseif InventoryService.Has(player, "Flashlight", 1) and nearGenerator(player) then
		local max = GameConfig.FlashlightBatterySeconds
		if data.flashlightCharge < max then
			data.flashlightCharge = math.min(max, data.flashlightCharge + GameConfig.FlashlightChargePerSecond * dt)
			if data.flashlightCharge >= max then
				Net.Notify(player, "flash.full", "success")
			end
		end
	end
	local after = math.floor(data.flashlightCharge)
	if after ~= before then
		player:SetAttribute("FlashlightCharge", after)
		PlayerDataService.MarkDirty(player)
		-- The HUD reads the attribute every second; a full snapshot is only needed at the ends of the range.
		if after == 0 or after == GameConfig.FlashlightBatterySeconds then
			StateSyncService.Request(player)
		end
	end
end

function FlashlightService.Init()
	StateSyncService.RegisterProvider(function(player, snapshot)
		local data = PlayerDataService.Get(player)
		snapshot.flashlightCharge = if data then math.floor(data.flashlightCharge) else 0
		snapshot.flashlightMax = GameConfig.FlashlightBatterySeconds
		if data then
			player:SetAttribute("FlashlightCharge", math.floor(data.flashlightCharge))
		end
	end)
end

function FlashlightService.Start()
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < TICK then
			return
		end
		local step = accumulator
		accumulator = 0
		for _, player in Players:GetPlayers() do
			tick(player, step)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		isOn[player] = nil
	end)
end

return FlashlightService
