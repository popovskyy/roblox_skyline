--!strict
-- Square inventory slot: item icon in the middle, count in the corner.
-- Uses def.iconImage when an uploaded icon exists, otherwise the emoji placeholder.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local UIKit = require(script.Parent.UIKit)

local ItemSlot = {}

local T = Theme.Colors
-- Theme.Slot / Stroke for empty and non-weapon slots; rarity stroke comes from Theme.Rarity.
local EMPTY_COLOR = T.Slot
local FILLED_COLOR = Color3.fromRGB(27, 28, 30)
local CREAM = T.Stroke

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
	-- Slightly solid fill so icon/count stay readable over the world on touch devices.
	frame.BackgroundTransparency = 0.08
	local stroke = UIKit.New("UIStroke", {
		Thickness = 1,
		Color = CREAM,
		Transparency = 0.65,
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
		TextSize = 17,
		TextStrokeTransparency = 0.4,
		Text = "",
		Parent = frame,
	})

	local function set(itemId: string?, count: number, selected: boolean)
		local def = if itemId then ItemDefinitions.Get(itemId) else nil
		if not def or count <= 0 then
			frame.BackgroundColor3 = EMPTY_COLOR
			frame.BackgroundTransparency = 0.08
			stroke.Color = CREAM
			stroke.Transparency = 0.65
			stroke.Thickness = 1
			emoji.Text = ""
			image.Visible = false
			countLabel.Text = ""
			return
		end
		-- Selected (in hand) slots get a near-opaque plate under the amber / rarity rim.
		frame.BackgroundTransparency = if selected then 0.02 else 0.06
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
			stroke.Color = if selected then T.Amber else CREAM
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
