--!strict
-- Terminal note and the ending screen. The note sits at the top and never blocks movement.

local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Theme"))
local UserInputService = game:GetService("UserInputService")

local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local TutorialController = {}

local C = UIKit.Colors

local notePanel: Frame
local noteTitle: TextLabel
local noteBody: TextLabel
local noteFooter: TextLabel
local endingPanel: Frame
local endingTitle: TextLabel
local endingBody: TextLabel
local endingFooter: TextLabel

local function buildNote(screen: ScreenGui)
	notePanel = UIKit.Panel({
		Name = "Note",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 72),
		Size = UDim2.fromScale(0.6, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = screen,
	})
	UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(560, 400), Parent = notePanel })
	UIKit.Padding(14).Parent = notePanel
	UIKit.New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = notePanel })
	noteTitle = UIKit.Label({
		Size = UDim2.new(1, -40, 0, 24),
		FontFace = Theme.Bold,
		TextSize = 18,
		TextColor3 = C.good,
		LayoutOrder = 1,
		Parent = notePanel,
	})
	noteBody = UIKit.Label({
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 16,
		LayoutOrder = 2,
		Parent = notePanel,
	})
	noteFooter = UIKit.Label({
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = 14,
		TextColor3 = C.accent,
		LayoutOrder = 3,
		Parent = notePanel,
	})
	local close = UIKit.Button({
		Size = UDim2.fromOffset(120, 34),
		Text = "",
		LayoutOrder = 4,
		Parent = notePanel,
	})
	Lang.Bind(close, "ui.close")
	close.Activated:Connect(function()
		notePanel.Visible = false
	end)
end

local function buildEnding(screen: ScreenGui)
	endingPanel = UIKit.New("Frame", {
		Name = "Ending",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.25,
		Visible = false,
		ZIndex = 10,
		Parent = screen,
	})
	local box = UIKit.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.8, 0, 0, 260),
		BackgroundTransparency = 1,
		ZIndex = 11,
		Parent = endingPanel,
	})
	UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(640, 300), Parent = box })
	UIKit.New("UIListLayout", {
		Padding = UDim.new(0, 12),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = box,
	})
	endingTitle = UIKit.Label({
		Size = UDim2.new(1, 0, 0, 50),
		FontFace = Theme.Display,
		TextSize = 36,
		TextColor3 = C.accent,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		ZIndex = 11,
		Parent = box,
	})
	endingBody = UIKit.Label({
		Size = UDim2.new(1, 0, 0, 70),
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		ZIndex = 11,
		Parent = box,
	})
	endingFooter = UIKit.Label({
		Size = UDim2.new(1, 0, 0, 24),
		TextSize = 14,
		TextColor3 = C.muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 3,
		ZIndex = 11,
		Parent = box,
	})
	local continueButton = UIKit.Button({
		Size = UDim2.fromOffset(180, 44),
		Text = "",
		LayoutOrder = 4,
		ZIndex = 11,
		Parent = box,
	})
	Lang.Bind(continueButton, "ui.continue")
	continueButton.Activated:Connect(function()
		endingPanel.Visible = false
	end)
end

function TutorialController.ShowNote(payload: any)
	if type(payload) ~= "table" then
		return
	end
	-- Note texts arrive as Locale messages and are rendered in the reader's language.
	local title = Lang.Format(payload.title)
	local body = Lang.Format(payload.body)
	local footer = Lang.Format(payload.footer)
	if payload.kind == "ending" then
		endingTitle.Text = title
		endingBody.Text = body
		endingFooter.Text = footer
		endingPanel.Visible = true
	else
		noteTitle.Text = title
		noteBody.Text = body
		noteFooter.Text = footer
		notePanel.Visible = true
	end
end

function TutorialController.Start()
	local screen = UIKit.Screen()
	buildNote(screen)
	buildEnding(screen)
	-- B on a gamepad (or Escape) closes the note and the ending screen.
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.ButtonB or input.KeyCode == Enum.KeyCode.Escape then
			notePanel.Visible = false
			endingPanel.Visible = false
		end
	end)
end

return TutorialController
