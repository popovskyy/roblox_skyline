--!strict
-- Local background music: a calm playlist on the roof, tense drones below. Crossfades when the zone changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local MusicConfig = require(ReplicatedStorage.Shared:WaitForChild("MusicConfig"))

local MusicController = {}

local player = Players.LocalPlayer
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

-- Music has its own SoundGroup so it can be balanced against effects in one place.
local musicGroup = Instance.new("SoundGroup")
musicGroup.Name = "Music"
musicGroup.Volume = 1
musicGroup.Parent = SoundService

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
	sound.SoundGroup = musicGroup
	sound.Parent = SoundService
	current = sound
	sound.Ended:Once(function()
		if current == sound and currentSet == setName then
			playNext(setName)
		end
	end)
	sound:Play()
	TweenService:Create(sound, TweenInfo.new(MusicConfig.FadeSeconds), {
		Volume = MusicConfig.Volume,
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
	player:GetAttributeChangedSignal("Zone"):Connect(onZoneChanged)
	applyZone()
end

return MusicController
