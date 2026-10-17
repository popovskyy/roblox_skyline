--!strict
-- Square inventory slot: item icon in the middle, count in the corner.
-- Uses def.iconImage when an uploaded icon exists, otherwise the emoji placeholder.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local UIKit = require(script.Parent.UIKit)

local ItemSlot = {}

local C = UIKit.Colors
-- Dark worn slots with a thin cream edge, to match the cream item icons.
local EMPTY_COLOR = Color3.fromRGB(20, 21, 23)
local FILLED_COLOR = Color3.fromRGB(27, 28, 30)
local CREAM = Color3.fromRGB(233, 223, 198)

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
	frame.BackgroundTransparency = 0.12
	local stroke = UIKit.New("UIStroke", {
		Thickness = 1.5,
		Color = CREAM,
		Transparency = 0.8,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = frame,
	})
	local emoji = UIKit.Label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromScale(0.6, 0.6),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Bold,
		Text = "",
		Parent = frame,
	})
	local image = UIKit.New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.82, 0.82),
		BackgroundTransparency = 1,
		Visible = false,
		ScaleType = Enum.ScaleType.Fit,
		Parent = frame,
	})
	local countLabel = UIKit.Label({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -5, 1, -3),
		Size = UDim2.fromOffset(40, 20),
		TextXAlignment = Enum.TextXAlignment.Right,
		FontFace = Theme.Display,
		TextSize = 16,
		TextStrokeTransparency = 0.4,
		Text = "",
		Parent = frame,
	})

	local function set(itemId: string?, count: number, selected: boolean)
		local def = if itemId then ItemDefinitions.Get(itemId) else nil
		if not def or count <= 0 then
			frame.BackgroundColor3 = EMPTY_COLOR
			stroke.Color = CREAM
			stroke.Transparency = 0.85
			stroke.Thickness = 1.5
			emoji.Text = ""
			image.Visible = false
			countLabel.Text = ""
			return
		end
		local rarityColor = if def.rarity then Theme.Rarity[def.rarity] else nil
		if rarityColor then
			-- Weapons always wear their rarity colour; in hand the edge thickens and the slot takes its tint.
			frame.BackgroundColor3 = if selected then FILLED_COLOR:Lerp(rarityColor, 0.22) else FILLED_COLOR
			stroke.Color = rarityColor
			stroke.Transparency = if selected then 0 else 0.15
			stroke.Thickness = if selected then 3 else 2
		else
			frame.BackgroundColor3 = FILLED_COLOR
			-- The item in hand gets a bright amber edge; the rest a faint cream one.
			stroke.Color = if selected then C.accent else CREAM
			stroke.Transparency = if selected then 0 else 0.6
			stroke.Thickness = if selected then 2.5 else 1.5
		end
		if def.iconImage then
			image.Image = def.iconImage
			image.ImageColor3 = def.iconTint or Color3.new(1, 1, 1)
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
