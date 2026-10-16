--!strict
-- One-shot 3D sound effects played by the server, so everyone nearby hears them.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundConfig = require(ReplicatedStorage.Shared.SoundConfig)

local SfxService = {}

-- Plays `name` at a part (follows it) or at a world position.
function SfxService.Play(name: string, at: BasePart | Vector3, volume: number?)
	local list = SoundConfig.Sounds[name]
	if not list or #list == 0 then
		return
	end
	local holder: Instance
	if typeof(at) == "Vector3" then
		local attachment = Instance.new("Attachment")
		attachment.WorldPosition = at
		attachment.Parent = workspace.Terrain
		holder = attachment
		Debris:AddItem(attachment, 8)
	else
		holder = at
	end
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(list[math.random(1, #list)])
	sound.Volume = (volume or 1) * SoundConfig.Volume
	sound.RollOffMaxDistance = SoundConfig.MaxDistance
	sound.RollOffMinDistance = 6
	sound.PlaybackSpeed = 1 + (math.random() - 0.5) * 0.12 -- a little variation so repeats do not sound robotic
	sound.Parent = holder
	sound:Play()
	Debris:AddItem(sound, 8)
end

-- Plays at the player's character, if they have one.
function SfxService.PlayAtPlayer(name: string, player: Player, volume: number?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		SfxService.Play(name, root, volume)
	end
end

return SfxService
