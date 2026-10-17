--!strict
-- Controller hints (docs/design/HUD_SPEC.md, section 5): a small panel bottom-right with the buttons that matter
-- (RT hit / use, Y flashlight, D-pad up medkit, D-pad down food) and LB / RB plates beside the hotbar.
-- Glyphs come from GetImageForKeyCode, so a PlayStation pad shows its own symbols. Only while the last
-- input was a gamepad; the panel fades after a minute of play.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local GamepadHintsController = {}

local T = Theme.Colors
local SHOW_SECONDS = 60

local panel: Frame
local plates: { GuiObject } = {}
local expired = false

local function glyph(parent: Instance, key: Enum.KeyCode, size: number, order: number?): ImageLabel
	local image = ""
	pcall(function()
		image = UserInputService:GetImageForKeyCode(key)
	end)
	return UIKit.New("ImageLabel", {
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		Image = image,
		LayoutOrder = order or 0,
		Parent = parent,
	})
end

local function usingGamepad(): boolean
	local last = UserInputService:GetLastInputType()
	return string.sub(last.Name, 1, 7) == "Gamepad"
end

local function update()
	local pad = usingGamepad()
	panel.Visible = pad and not expired
	for _, plate in plates do
		plate.Visible = pad
	end
end

local function plate(hotbar: GuiObject, key: Enum.KeyCode, position: UDim2)
	local frame = UIKit.New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = position,
		Size = UDim2.fromOffset(50, 34),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Visible = false,
		Parent = hotbar,
	}, { UIKit.Corner(8) })
	local image = glyph(frame, key, 26)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	table.insert(plates, frame)
end

function GamepadHintsController.Start()
	local screen = UIKit.Screen()
	panel = UIKit.New("Frame", {
		Name = "GamepadHints",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Visible = false,
		Parent = screen,
	}, { UIKit.Corner(10) })
	UIKit.Padding(10).Parent = panel
	UIKit.New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	local rows = {
		{ Enum.KeyCode.ButtonR2, "pad.hit" },
		{ Enum.KeyCode.ButtonY, "pad.light" },
		{ Enum.KeyCode.DPadUp, "pad.medkit" },
		{ Enum.KeyCode.DPadDown, "pad.food" },
	}
	for i, r in rows do
		local row = UIKit.New("Frame", {
			Size = UDim2.fromOffset(0, 28),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			LayoutOrder = i,
			Parent = panel,
		})
		UIKit.New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = row,
		})
		glyph(row, r[1], 28, 1)
		local label = UIKit.Label({
			Size = UDim2.fromOffset(0, 22),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = Lang.T(r[2]),
			FontFace = Theme.Semi,
			TextSize = 16,
			TextColor3 = T.Cream,
			TextWrapped = false,
			LayoutOrder = 2,
			Parent = row,
		})
		Lang.Changed:Connect(function()
			label.Text = Lang.T(r[2])
		end)
	end

	-- LB / RB beside the hotbar (it exists once InventoryController has started).
	task.spawn(function()
		local hotbar = screen:WaitForChild("Hotbar", 30)
		if hotbar and hotbar:IsA("GuiObject") then
			plate(hotbar, Enum.KeyCode.ButtonL1, UDim2.new(0, -58, 0.5, 0))
			plate(hotbar, Enum.KeyCode.ButtonR1, UDim2.new(1, 72, 0.5, 0))
			update()
		end
	end)

	UserInputService.LastInputTypeChanged:Connect(update)
	update()
	task.delay(SHOW_SECONDS, function()
		expired = true
		update()
	end)
end

-- The menu brings the hints back.
function GamepadHintsController.ShowAgain()
	expired = false
	update()
end

return GamepadHintsController
