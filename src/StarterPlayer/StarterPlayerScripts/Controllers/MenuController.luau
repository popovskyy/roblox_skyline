--!strict
-- The ☰ menu (ui/HUD_SPEC.md, section 6): Resume, How to play, Leave run. Leaving asks first and only
-- goes after holding the button for 1.5 s, so nobody quits a run by accident. Keys M / Tab open it.

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local HapticService = game:GetService("HapticService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local MenuController = {}

local T = Theme.Colors
local HOLD_SECONDS = 1.5
local touch = UIKit.IsTouch()

local remotes: Folder
local menuPanel: Frame
local dialog: Frame
local dim: TextButton

-- Set by ClientMain: shows the story / how-to card again.
MenuController.ShowHowTo = function() end

local function bindText(label: TextLabel | TextButton, key: string)
	label.Text = Lang.T(key)
	Lang.Changed:Connect(function()
		label.Text = Lang.T(key)
	end)
end

local function closeAll()
	menuPanel.Visible = false
	dialog.Visible = false
	dim.Visible = false
	GuiService.SelectedObject = nil
end

local function openMenu()
	dim.Visible = true
	menuPanel.Visible = true
	dialog.Visible = false
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = menuPanel:FindFirstChild("Resume") :: GuiObject?
	end
end

local function toggleMenu()
	if menuPanel.Visible or dialog.Visible then
		closeAll()
	else
		openMenu()
	end
end

local function menuButton(parent: Instance, name: string, key: string, order: number, danger: boolean?): TextButton
	local button = UIKit.Button({
		Name = name,
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = if danger then T.PanelSolid elseif order == 1 then T.Cream else T.PanelSolid,
		TextColor3 = if danger then T.DangerText elseif order == 1 then T.PanelSolid else T.Cream,
		FontFace = Theme.Bold,
		TextSize = if touch then 16 else 17,
		LayoutOrder = order,
		Parent = parent,
	})
	UIKit.New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = if danger then T.Danger else T.Stroke,
		Transparency = if danger then 0.2 else 0.65,
		Thickness = 1.5,
		Parent = button,
	})
	bindText(button, key)
	return button
end

local function buildMenu()
	local top = UIKit.TopScreen()
	local size = if touch then 40 else 48
	local open = UIKit.Button({
		Name = "MenuButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = if touch then UDim2.new(1, -8, 0, 6) else UDim2.new(1, -24, 0, 12),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.35,
		Text = "☰",
		TextSize = 22,
		TextColor3 = T.Cream,
		Parent = top,
	})
	open.Activated:Connect(toggleMenu)

	dim = UIKit.New("TextButton", {
		Name = "MenuDim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 30,
		Parent = UIKit.FullScreen(),
	})
	dim.Activated:Connect(closeAll)

	menuPanel = UIKit.New("Frame", {
		Name = "Menu",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, if touch then 16 else 32, 0.5, 0),
		Size = UDim2.fromOffset(250, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.PanelSolid,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 31,
		Parent = UIKit.FullScreen(),
	}, { UIKit.Corner(12) })
	UIKit.Padding(14).Parent = menuPanel
	UIKit.New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = menuPanel })
	local title = UIKit.Label({
		Size = UDim2.new(1, 0, 0, 30),
		FontFace = Theme.Display,
		TextSize = 24,
		TextColor3 = T.Cream,
		LayoutOrder = 0,
		Parent = menuPanel,
	})
	bindText(title, "menu.title")
	menuButton(menuPanel, "Resume", "menu.resume", 1).Activated:Connect(closeAll)
	menuButton(menuPanel, "HowTo", "menu.howTo", 2).Activated:Connect(function()
		closeAll()
		MenuController.ShowHowTo()
	end)
	UIKit.New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = T.Stroke,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		LayoutOrder = 3,
		Parent = menuPanel,
	})
	menuButton(menuPanel, "Leave", "menu.leave", 4, true).Activated:Connect(function()
		menuPanel.Visible = false
		dialog.Visible = true
		if UserInputService.GamepadEnabled then
			GuiService.SelectedObject = dialog:FindFirstChild("Stay", true) :: GuiObject?
		end
	end)
end

local function buildDialog()
	dialog = UIKit.New("Frame", {
		Name = "LeaveDialog",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(420, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.PanelSolid,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 31,
		Parent = UIKit.FullScreen(),
	}, { UIKit.Corner(12) })
	UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(420, 400), Parent = dialog })
	UIKit.Padding(20).Parent = dialog
	UIKit.New("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = dialog })
	local title = UIKit.Label({
		Size = UDim2.new(1, 0, 0, 32),
		FontFace = Theme.Display,
		TextSize = 26,
		TextColor3 = T.Cream,
		LayoutOrder = 1,
		Parent = dialog,
	})
	bindText(title, "leave.title")
	local body = UIKit.Label({
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		FontFace = Theme.Semi,
		TextSize = 16,
		TextColor3 = T.CreamDim,
		LayoutOrder = 2,
		Parent = dialog,
	})
	bindText(body, "leave.body")

	local buttons = UIKit.New("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = dialog,
	})
	UIKit.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 10),
		Parent = buttons,
	})
	local stay = UIKit.Button({
		Name = "Stay",
		Size = UDim2.new(0.58, -5, 1, 0),
		BackgroundColor3 = T.Cream,
		TextColor3 = T.PanelSolid,
		FontFace = Theme.Bold,
		TextSize = 17,
		Parent = buttons,
	})
	bindText(stay, "leave.stay")
	stay.Activated:Connect(closeAll)

	-- Hold to leave: a dark red fill grows left to right; letting go early resets it.
	local leave = UIKit.Button({
		Name = "HoldLeave",
		Size = UDim2.new(0.42, -5, 1, 0),
		BackgroundColor3 = T.PanelSolid,
		TextColor3 = T.DangerText,
		FontFace = Theme.Bold,
		TextSize = 15,
		AutoButtonColor = false,
		ClipsDescendants = true,
		Parent = buttons,
	})
	UIKit.New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = T.Danger,
		Thickness = 1.5,
		Parent = leave,
	})
	bindText(leave, "leave.hold")
	local fill = UIKit.New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromHex("A3352A"),
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = leave,
	})
	local holding = false
	local function release()
		holding = false
		fill.Size = UDim2.fromScale(0, 1)
		pcall(function()
			HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
		end)
	end
	local function press()
		if holding then
			return
		end
		holding = true
		pcall(function()
			HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0.4)
		end)
		local started = os.clock()
		while holding do
			local t = (os.clock() - started) / HOLD_SECONDS
			fill.Size = UDim2.fromScale(math.min(t, 1), 1)
			if t >= 1 then
				release()
				closeAll()
				local remote = remotes:FindFirstChild(RemoteNames.ReturnToLobby) :: RemoteEvent?
				if remote then
					remote:FireServer()
				end
				return
			end
			RunService.RenderStepped:Wait()
		end
	end
	leave.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if
			kind == Enum.UserInputType.MouseButton1
			or kind == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			task.spawn(press)
		end
	end)
	leave.InputEnded:Connect(function(input)
		local kind = input.UserInputType
		if
			kind == Enum.UserInputType.MouseButton1
			or kind == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			release()
		end
	end)
	leave.MouseLeave:Connect(release)
end

function MenuController.Start(remoteFolder: Folder)
	remotes = remoteFolder
	buildMenu()
	buildDialog()
	ContextActionService:BindAction("SkylineMenu", function(_, state)
		if state == Enum.UserInputState.Begin then
			toggleMenu()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.M, Enum.KeyCode.Tab)
end

return MenuController
