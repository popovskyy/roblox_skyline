--!strict
-- Local background music: a calm playlist on the roof, tense drones below. Crossfades when the zone changes.
-- A small button in the top-right corner mutes it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local MusicConfig = require(ReplicatedStorage.Shared:WaitForChild("MusicConfig"))
local UIKit = require(script.Parent.UIKit)

local MusicController = {}

local player = Players.LocalPlayer
local muted = false
local currentSet: string? = nil
local current: Sound? = nil
local indices: { [string]: number } = {}

local function playlistFor(zone: any): string
	if zone == "Roof" or zone == "NeighborRoof" or zone == nil then
		return "Roof"
	end
	return "Below"
end

local function fadeOut(sound: Sound)
	local tween = TweenService:Create(sound, TweenInfo.new(MusicConfig.FadeSeconds), { Volume = 0 })
	tween.Completed:Once(function()
		sound:Destroy()
	end)
	tween:Play()
end

local playNext: (setName: string) -> ()

playNext = function(setName: string)
	local list = (MusicConfig :: any)[setName] :: { number }
	if not list or #list == 0 then
		return
	end
	local index = (indices[setName] or math.random(1, #list) - 1) % #list + 1
	indices[setName] = index

	if current then
		fadeOut(current)
	end
	local sound = Instance.new("Sound")
	sound.Name = "Music"
	sound.SoundId = "rbxassetid://" .. tostring(list[index])
	sound.Volume = 0
	sound.Looped = false
	sound.Parent = SoundService
	current = sound
	sound.Ended:Once(function()
		if current == sound and currentSet == setName then
			playNext(setName)
		end
	end)
	sound:Play()
	TweenService:Create(sound, TweenInfo.new(MusicConfig.FadeSeconds), {
		Volume = if muted then 0 else MusicConfig.Volume,
	}):Play()
end

local function applyZone()
	local setName = playlistFor(player:GetAttribute("Zone"))
	if setName ~= currentSet then
		currentSet = setName
		playNext(setName)
	end
end

-- Walking around the top of the stairs flips the zone back and forth, so wait until it settles.
local function onZoneChanged()
	task.delay(3, applyZone)
end

function MusicController.Start()
	local button = UIKit.Button({
		Name = "MusicToggle",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(44, 44),
		Text = "♪",
		TextSize = 22,
		Parent = UIKit.Screen(),
	})
	button.Activated:Connect(function()
		muted = not muted
		button.Text = if muted then "✕♪" else "♪"
		if current then
			current.Volume = if muted then 0 else MusicConfig.Volume
		end
	end)

	player:GetAttributeChangedSignal("Zone"):Connect(onZoneChanged)
	applyZone()
end

return MusicController
