--!strict
-- Class perks that live on this client: a Medic holds revive prompts half as long, a Mechanic sees
-- resource nodes nearby glowing through walls.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classes = require(ReplicatedStorage.Shared.Classes)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Theme = require(ReplicatedStorage.Shared.Theme)

local ClassController = {}

local player = Players.LocalPlayer
local highlights: { [BasePart]: Highlight } = {}

local function clearHighlights()
	for part, highlight in highlights do
		highlight:Destroy()
		highlights[part] = nil
	end
end

-- Mechanic: untaken resource nodes within range get an amber outline visible through walls.
local function updateGlow()
	local def = Classes.Of(player)
	local range = def and def.seeResources
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local world = workspace:FindFirstChild(GameConfig.World.FolderName)
	local folder = world and world:FindFirstChild("Interactables")
	if not range or not root or not root:IsA("BasePart") or not folder then
		clearHighlights()
		return
	end
	local seen: { [BasePart]: boolean } = {}
	for _, d in folder:GetChildren() do
		if d:IsA("BasePart") and d:GetAttribute("InteractType") == "Resource" then
			local prompt = d:FindFirstChildOfClass("ProximityPrompt")
			local available = prompt ~= nil and prompt.Enabled
			if available and (d.Position - root.Position).Magnitude <= range then
				seen[d] = true
				if not highlights[d] then
					local highlight = Instance.new("Highlight")
					highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					highlight.FillTransparency = 0.85
					highlight.FillColor = Theme.Colors.Amber
					highlight.OutlineColor = Theme.Colors.Amber
					highlight.Adornee = d
					highlight.Parent = d
					highlights[d] = highlight
				end
			end
		end
	end
	for part, highlight in highlights do
		if not seen[part] then
			highlight:Destroy()
			highlights[part] = nil
		end
	end
end

function ClassController.Start()
	-- Medic: revive prompts are held half as long (the prompt's own hold time, set on this client).
	ProximityPromptService.PromptShown:Connect(function(prompt)
		if prompt:GetAttribute("ReviveUserId") == nil then
			return
		end
		local def = Classes.Of(player)
		local base = prompt:GetAttribute("BaseHold")
		if type(base) ~= "number" then
			base = prompt.HoldDuration
			prompt:SetAttribute("BaseHold", base)
		end
		prompt.HoldDuration = base / (if def and def.reviveSpeed then def.reviveSpeed else 1)
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			updateGlow()
		end
	end)
end

return ClassController
