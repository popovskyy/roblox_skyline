--!strict
-- Tiny helpers for building UI in code with a consistent look.

local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Theme"))
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local UIKit = {}

UIKit.Colors = {
	panel = Color3.fromRGB(22, 24, 28),
	panelLight = Color3.fromRGB(38, 41, 47),
	text = Color3.fromRGB(235, 235, 235),
	muted = Color3.fromRGB(165, 168, 175),
	accent = Color3.fromRGB(255, 196, 64),
	good = Color3.fromRGB(110, 210, 120),
	warn = Color3.fromRGB(255, 170, 60),
	bad = Color3.fromRGB(235, 80, 70),
	health = Color3.fromRGB(200, 60, 60),
	toxic = Color3.fromRGB(140, 230, 80),
}

function UIKit.New(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

function UIKit.Corner(radius: number?): UICorner
	return UIKit.New("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

function UIKit.Padding(px: number): UIPadding
	return UIKit.New("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
	})
end

function UIKit.Panel(props: { [string]: any }): Frame
	local merged = {
		BackgroundColor3 = UIKit.Colors.panel,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
	}
	for k, v in props do
		merged[k] = v
	end
	return UIKit.New("Frame", merged, { UIKit.Corner(10) })
end

function UIKit.Label(props: { [string]: any }): TextLabel
	local merged = {
		BackgroundTransparency = 1,
		FontFace = Theme.Body,
		TextColor3 = UIKit.Colors.text,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}
	for k, v in props do
		merged[k] = v
	end
	return UIKit.New("TextLabel", merged)
end

function UIKit.Button(props: { [string]: any }): TextButton
	local merged = {
		BackgroundColor3 = UIKit.Colors.panelLight,
		BorderSizePixel = 0,
		FontFace = Theme.Bold,
		TextColor3 = UIKit.Colors.text,
		TextSize = 18,
		AutoButtonColor = true,
	}
	for k, v in props do
		merged[k] = v
	end
	return UIKit.New("TextButton", merged, { UIKit.Corner(8) })
end

-- Single ScreenGui shared by all controllers.
local screen: ScreenGui? = nil
function UIKit.Screen(): ScreenGui
	if screen then
		return screen
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = UIKit.New("ScreenGui", {
		Name = "SkylineUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})
	-- Scale the whole UI down on small screens (phones) and keep it 1:1 on PC, tablets and TVs.
	local scale = UIKit.New("UIScale", { Parent = gui })
	local function updateScale()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local viewport = camera.ViewportSize
		if UserInputService.TouchEnabled then
			-- Phones and tablets: keep buttons finger-sized without letting panels cover the screen.
			scale.Scale = math.clamp(math.min(viewport.X / 900, viewport.Y / 480), 0.65, 1)
		else
			scale.Scale = math.clamp(math.min(viewport.X / 1280, viewport.Y / 720), 0.8, 1.2)
		end
	end
	updateScale()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale)
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end
	screen = gui
	return gui
end

return UIKit
