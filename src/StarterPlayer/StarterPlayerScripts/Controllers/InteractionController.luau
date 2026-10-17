--!strict
-- Input for interactions: ProximityPrompts handle E / gamepad / tapping the prompt; touch devices also get
-- a round action button for the closest prompt. F / Y (or a round touch button) toggles the flashlight.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientState = require(script.Parent.ClientState)
local UIKit = require(script.Parent.UIKit)

local InteractionController = {}

local shownPrompts: { ProximityPrompt } = {}
local holding: ProximityPrompt? = nil
local interactButton: Frame? = nil
local interactCaption: TextLabel? = nil

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
	button.Visible = prompt ~= nil and Players.LocalPlayer:GetAttribute("Downed") ~= true
	if prompt and interactCaption then
		interactCaption.Text = prompt.ActionText
	end
end

local function toggleFlashlight(remotes: Folder)
	local remote = remotes:FindFirstChild(RemoteNames.ToggleFlashlight) :: RemoteEvent
	remote:FireServer()
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
		local T = Theme.Colors
		local screen = UIKit.Screen()
		-- Round action button (docs/design/HUD_SPEC.md, section 4): only while a prompt is near, its action above it,
		-- an amber fill grows while holding.
		local holder = UIKit.New("Frame", {
			Name = "ActionButton",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -111, 1, -42),
			Size = UDim2.fromOffset(64, 64),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = screen,
		})
		local button = UIKit.New("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = T.Panel,
			BackgroundTransparency = 0.2,
			Text = "",
			AutoButtonColor = false,
			Active = true,
			Parent = holder,
		}, { UIKit.Corner(32) })
		UIKit.New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = T.Amber,
			Thickness = 3,
			Parent = button,
		})
		local fill = UIKit.New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0, 0),
			BackgroundColor3 = T.Amber,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Parent = button,
		}, { UIKit.Corner(32) })
		-- A small cream ring in the middle: "press here".
		local dot = UIKit.New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			ZIndex = 2,
			Parent = button,
		}, { UIKit.Corner(9) })
		UIKit.New("UIStroke", { Color = T.Cream, Thickness = 2.5, Parent = dot })
		local caption = UIKit.Label({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 0, -6),
			Size = UDim2.fromOffset(0, 24),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = T.PanelSolid,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Text = "",
			FontFace = Theme.Bold,
			TextSize = 15,
			TextColor3 = T.Cream,
			TextStrokeColor3 = Color3.fromRGB(12, 10, 8),
			TextStrokeTransparency = 0.25,
			TextWrapped = false,
			Parent = holder,
		})
		UIKit.Corner(6).Parent = caption
		UIKit.New("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			Parent = caption,
		})
		local holdToken = 0
		button.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				local prompt = currentPrompt()
				if prompt then
					holding = prompt
					prompt:InputHoldBegin()
					holdToken += 1
					local token = holdToken
					local duration = math.max(prompt.HoldDuration, 0.05)
					local started = os.clock()
					task.spawn(function()
						while holdToken == token and holding == prompt do
							local t = math.min((os.clock() - started) / duration, 1)
							fill.Size = UDim2.fromScale(t, t)
							RunService.RenderStepped:Wait()
						end
						fill.Size = UDim2.fromScale(0, 0)
					end)
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
				holdToken += 1
				fill.Size = UDim2.fromScale(0, 0)
				if prompt and prompt.Parent then
					prompt:InputHoldEnd()
				end
			end
		end)
		interactButton = holder
		interactCaption = caption

		-- Flashlight: a round button above the jump button, only while carrying one.
		local flashlight = ItemDefinitions.Get("Flashlight")
		local flash = UIKit.New("ImageButton", {
			Name = "FlashlightButton",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -36, 1, -110),
			Size = UDim2.fromOffset(48, 48),
			BackgroundColor3 = T.Panel,
			BackgroundTransparency = 0.25,
			Image = if flashlight and flashlight.iconImage then flashlight.iconImage else "",
			ImageColor3 = T.Cream,
			Visible = false,
			Parent = screen,
		}, { UIKit.Corner(24) })
		local flashStroke = UIKit.New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = T.Stroke,
			Transparency = 0.65,
			Thickness = 1.5,
			Parent = flash,
		})
		flash.Activated:Connect(function()
			toggleFlashlight(remotes)
		end)
		local function updateFlash()
			local s = ClientState.Get()
			local has = s ~= nil and s.inventory ~= nil and (s.inventory.Flashlight or 0) > 0
			flash.Visible = has and Players.LocalPlayer:GetAttribute("Downed") ~= true
			local on = Players.LocalPlayer:GetAttribute("FlashlightOn") == true
			flash.ImageColor3 = if on then T.AmberText else T.Cream
			flashStroke.Color = if on then T.Amber else T.Stroke
			flashStroke.Transparency = if on then 0 else 0.65
		end
		ClientState.Changed:Connect(updateFlash)
		Players.LocalPlayer:GetAttributeChangedSignal("FlashlightOn"):Connect(updateFlash)
		Players.LocalPlayer:GetAttributeChangedSignal("Downed"):Connect(function()
			updateFlash()
			refreshButton()
		end)
	end

	-- Prompt texts change when the state changes (e.g. an upgrade gets built).
	ClientState.Changed:Connect(refreshButton)
end

return InteractionController
