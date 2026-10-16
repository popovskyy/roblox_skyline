--!strict
-- Input for interactions: ProximityPrompts handle E / gamepad / tapping the prompt; touch devices also get
-- a big "Взаємодія" button for the closest prompt. F (or a touch button) toggles the flashlight.

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local ClientState = require(script.Parent.ClientState)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local InteractionController = {}

local shownPrompts: { ProximityPrompt } = {}
local holding: ProximityPrompt? = nil
local interactButton: TextButton? = nil
local flashlightButton: TextButton? = nil

local function currentPrompt(): ProximityPrompt?
	-- The most recently shown prompt is the one the player is facing.
	for i = #shownPrompts, 1, -1 do
		local prompt = shownPrompts[i]
		if prompt.Parent and prompt.Enabled then
			return prompt
		end
	end
	return nil
end

local function refreshButton()
	local button = interactButton
	if not button then
		return
	end
	local prompt = currentPrompt()
	button.Visible = prompt ~= nil
	if prompt then
		button.Text = prompt.ActionText
	end
end

local function toggleFlashlight(remotes: Folder)
	(remotes:FindFirstChild(RemoteNames.ToggleFlashlight) :: RemoteEvent):FireServer()
end

function InteractionController.Start(remotes: Folder)
	ProximityPromptService.PromptShown:Connect(function(prompt)
		table.insert(shownPrompts, prompt)
		refreshButton()
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		local index = table.find(shownPrompts, prompt)
		if index then
			table.remove(shownPrompts, index)
		end
		if holding == prompt then
			holding = nil
		end
		refreshButton()
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		-- F on keyboard, Y on a gamepad.
		if not processed and (input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.ButtonY) then
			toggleFlashlight(remotes)
		end
	end)

	if UserInputService.TouchEnabled then
		local screen = UIKit.Screen()
		local button = UIKit.Button({
			Name = "InteractButton",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -24, 1, -180),
			Size = UDim2.fromOffset(150, 70),
			Text = "",
			TextSize = 18,
			BackgroundColor3 = Color3.fromRGB(70, 110, 160),
			Visible = false,
			Parent = screen,
		})
		button.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				local prompt = currentPrompt()
				if prompt then
					holding = prompt
					prompt:InputHoldBegin()
				end
			end
		end)
		button.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				local prompt = holding
				holding = nil
				if prompt and prompt.Parent then
					prompt:InputHoldEnd()
				end
			end
		end)
		Lang.Bind(button, "ui.interact")
		interactButton = button

		local flash = UIKit.Button({
			Name = "FlashlightButton",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -24, 1, -260),
			Size = UDim2.fromOffset(110, 48),
			Text = "",
			Visible = false,
			Parent = screen,
		})
		flash.Activated:Connect(function()
			toggleFlashlight(remotes)
		end)
		Lang.Bind(flash, "ui.flashlight")
		flashlightButton = flash
		ClientState.Changed:Connect(function(s)
			if flashlightButton then
				flashlightButton.Visible = s.inventory ~= nil and (s.inventory.Flashlight or 0) > 0
			end
		end)
	end

	-- Prompt texts change when the state changes (e.g. an upgrade gets built).
	ClientState.Changed:Connect(refreshButton)
end

return InteractionController
