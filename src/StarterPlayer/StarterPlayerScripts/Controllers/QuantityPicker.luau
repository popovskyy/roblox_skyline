--!strict
-- "How many?" window for splitting a stack: dropping, moving to or from the chest, crafting several.
-- Big − / + buttons and 1 / half / all shortcuts so it works with a finger, a mouse or a gamepad.
--   QuantityPicker.Open(titleText, iconImage, max, onConfirm)

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local QuantityPicker = {}

local T = Theme.Colors
local gui: ScreenGui? = nil

local function close()
	if gui then
		gui:Destroy()
		gui = nil
	end
	GuiService.SelectedObject = nil
end

local function button(parent: Instance, text: string, size: UDim2, primary: boolean?): TextButton
	local b = UIKit.Button({
		Size = size,
		Text = text,
		FontFace = Theme.Display,
		TextSize = 22,
		BackgroundColor3 = if primary then T.Cream else T.PanelSolid,
		TextColor3 = if primary then T.PanelSolid else T.Cream,
		Parent = parent,
	})
	UIKit.New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = T.Stroke,
		Transparency = 0.65,
		Parent = b,
	})
	return b
end

function QuantityPicker.IsOpen(): boolean
	return gui ~= nil
end

function QuantityPicker.Open(title: string, icon: string?, max: number, onConfirm: (amount: number) -> ())
	close()
	if max <= 0 then
		return
	end
	local amount = max
	local screen = UIKit.New("ScreenGui", {
		Name = "SkylineQuantity",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 40,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	gui = screen
	local dim = UIKit.New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		Text = "",
		AutoButtonColor = false,
		Parent = screen,
	})
	dim.Activated:Connect(close)
	local panel = UIKit.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(340, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.PanelSolid,
		BorderSizePixel = 0,
		Parent = screen,
	}, { UIKit.Corner(12) })
	UIKit.Padding(16).Parent = panel
	UIKit.New("UIListLayout", {
		Padding = UDim.new(0, 12),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = panel,
	})

	local head = UIKit.New("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = panel,
	})
	if icon and icon ~= "" then
		UIKit.New("ImageLabel", {
			Size = UDim2.fromOffset(36, 36),
			BackgroundTransparency = 1,
			Image = icon,
			Parent = head,
		})
	end
	UIKit.Label({
		Position = UDim2.fromOffset(if icon and icon ~= "" then 46 else 0, 0),
		Size = UDim2.new(1, -46, 1, 0),
		Text = title,
		FontFace = Theme.Bold,
		TextSize = 18,
		TextColor3 = T.Cream,
		Parent = head,
	})

	-- − [ number ] +
	local row = UIKit.New("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = panel,
	})
	local minus = button(row, "-", UDim2.fromOffset(64, 56))
	local plus = button(row, "+", UDim2.fromOffset(64, 56))
	plus.AnchorPoint = Vector2.new(1, 0)
	plus.Position = UDim2.fromScale(1, 0)
	local number = UIKit.Label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(1, -150, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Display,
		TextSize = 34,
		TextColor3 = T.AmberText,
		Parent = row,
	})
	local function show()
		number.Text = ("%d / %d"):format(amount, max)
	end
	show()

	-- Long presses on − / + repeat, so big stacks are quick.
	local function stepper(b: TextButton, delta: number)
		local held = false
		b.InputBegan:Connect(function(input)
			local kind = input.UserInputType
			if kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseButton1 then
				return
			end
			held = true
			amount = math.clamp(amount + delta, 1, max)
			show()
			task.delay(0.4, function()
				while held do
					amount = math.clamp(amount + delta, 1, max)
					show()
					task.wait(0.07)
				end
			end)
		end)
		b.InputEnded:Connect(function()
			held = false
		end)
		-- Gamepad A on a selected button.
		b.Activated:Connect(function(_, count)
			if UserInputService.GamepadEnabled and count == 1 and not held then
				amount = math.clamp(amount + delta, 1, max)
				show()
			end
		end)
	end
	stepper(minus, -1)
	stepper(plus, 1)

	local quick = UIKit.New("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = panel,
	})
	UIKit.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = quick,
	})
	for _, choice in { { "1", 1 }, { "½", math.max(1, math.floor(max / 2)) }, { Lang.T("qty.all"), max } } do
		local b = button(quick, choice[1] :: string, UDim2.fromOffset(92, 44))
		b.TextSize = 18
		b.Activated:Connect(function()
			amount = choice[2] :: number
			show()
		end)
	end

	local actions = UIKit.New("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = panel,
	})
	UIKit.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 10),
		Parent = actions,
	})
	local cancel = button(actions, Lang.T("qty.cancel"), UDim2.new(0.4, -5, 1, 0))
	cancel.TextSize = 17
	cancel.Activated:Connect(close)
	local ok = button(actions, Lang.T("qty.ok"), UDim2.new(0.6, -5, 1, 0), true)
	ok.TextSize = 17
	ok.Activated:Connect(function()
		local chosen = amount
		close()
		onConfirm(chosen)
	end)
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = ok
	end
end

-- Gamepad B / Escape closes it.
UserInputService.InputBegan:Connect(function(input)
	if gui and (input.KeyCode == Enum.KeyCode.ButtonB or input.KeyCode == Enum.KeyCode.Escape) then
		close()
	end
end)

return QuantityPicker
