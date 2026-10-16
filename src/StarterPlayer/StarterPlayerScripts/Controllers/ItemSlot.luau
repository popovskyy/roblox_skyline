--!strict
-- Square inventory slot: item icon in the middle, count in the corner.
-- Uses def.iconImage when an uploaded icon exists, otherwise the emoji placeholder.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local UIKit = require(script.Parent.UIKit)

local ItemSlot = {}

local C = UIKit.Colors
local EMPTY_COLOR = Color3.fromRGB(32, 34, 39)
local FILLED_COLOR = Color3.fromRGB(46, 49, 56)

export type Slot = {
	frame: TextButton,
	set: (itemId: string?, count: number, selected: boolean) -> (),
}

function ItemSlot.New(parent: Instance, size: number, layoutOrder: number): Slot
	local frame = UIKit.New("TextButton", {
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = EMPTY_COLOR,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = layoutOrder,
		Parent = parent,
	}, { UIKit.Corner(8) })
	local stroke = UIKit.New("UIStroke", {
		Thickness = 2,
		Color = Color3.fromRGB(60, 63, 70),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = frame,
	})
	local emoji = UIKit.Label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromScale(0.62, 0.62),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Enum.Font.GothamBold,
		Text = "",
		Parent = frame,
	})
	local image = UIKit.New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromScale(0.62, 0.62),
		BackgroundTransparency = 1,
		Visible = false,
		ScaleType = Enum.ScaleType.Fit,
		Parent = frame,
	})
	local countLabel = UIKit.Label({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -5, 1, -3),
		Size = UDim2.fromOffset(40, 16),
		TextXAlignment = Enum.TextXAlignment.Right,
		Font = Enum.Font.GothamBlack,
		TextSize = 14,
		TextStrokeTransparency = 0.4,
		Text = "",
		Parent = frame,
	})

	local function set(itemId: string?, count: number, selected: boolean)
		local def = if itemId then ItemDefinitions.Get(itemId) else nil
		if not def or count <= 0 then
			frame.BackgroundColor3 = EMPTY_COLOR
			stroke.Color = Color3.fromRGB(60, 63, 70)
			emoji.Text = ""
			image.Visible = false
			countLabel.Text = ""
			return
		end
		frame.BackgroundColor3 = FILLED_COLOR
		stroke.Color = if selected then C.accent else def.color
		stroke.Thickness = if selected then 3 else 2
		if def.iconImage then
			image.Image = def.iconImage
			image.Visible = true
			emoji.Text = ""
		else
			image.Visible = false
			emoji.Text = def.icon
		end
		countLabel.Text = if count > 1 then tostring(count) else ""
	end

	set(nil, 0, false)
	return { frame = frame, set = set }
end

return ItemSlot
