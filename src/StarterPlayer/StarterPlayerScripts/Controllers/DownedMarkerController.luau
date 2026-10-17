--!strict
-- Where a downed teammate lies: a red marker over them (visible through walls) with name and distance,
-- and an arrow on the screen edge pointing at them while they are off screen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local DownedMarkerController = {}

local player = Players.LocalPlayer
local T = Theme.Colors
local STUDS_TO_METRES = 0.28

type Marker = { billboard: BillboardGui, label: TextLabel, arrow: Frame }
local markers: { [Player]: Marker } = {}

local function makeMarker(other: Player): Marker
	local billboard = UIKit.New("BillboardGui", {
		Name = "DownedMarker_" .. other.Name,
		Size = UDim2.fromOffset(200, 64),
		StudsOffsetWorldSpace = Vector3.new(0, 4, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local dot = UIKit.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = T.Danger,
		BorderSizePixel = 0,
		Parent = billboard,
	}, { UIKit.Corner(15) })
	UIKit.Label({
		Size = UDim2.fromScale(1, 1),
		Text = "!",
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Display,
		TextSize = 22,
		TextColor3 = T.Cream,
		Parent = dot,
	})
	local label = UIKit.Label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 34),
		Size = UDim2.new(1, 0, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Bold,
		TextSize = 16,
		TextColor3 = T.DangerText,
		TextStrokeTransparency = 0.3,
		Parent = billboard,
	})
	-- Edge arrow: a red circle with "!" that slides along the screen border.
	local arrow = UIKit.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = T.Danger,
		BorderSizePixel = 0,
		Visible = false,
		Parent = UIKit.FullScreen(),
	}, { UIKit.Corner(20) })
	UIKit.Label({
		Size = UDim2.fromScale(1, 1),
		Text = "!",
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Display,
		TextSize = 24,
		TextColor3 = T.Cream,
		Parent = arrow,
	})
	return { billboard = billboard, label = label, arrow = arrow }
end

local function remove(other: Player)
	local marker = markers[other]
	if marker then
		marker.billboard:Destroy()
		marker.arrow:Destroy()
		markers[other] = nil
	end
end

local function update()
	local camera = workspace.CurrentCamera
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			local down = other:GetAttribute("Downed") == true and root ~= nil and root:IsA("BasePart")
			if not down then
				remove(other)
			else
				local marker = markers[other] or makeMarker(other)
				markers[other] = marker
				local part = root :: BasePart
				marker.billboard.Adornee = part
				marker.billboard.Enabled = true
				local metres = if myRoot and myRoot:IsA("BasePart")
					then math.floor((part.Position - myRoot.Position).Magnitude * STUDS_TO_METRES + 0.5)
					else 0
				marker.label.Text = other.DisplayName .. "  ·  " .. Lang.T("downed.meters", metres)
				-- Off screen (or behind the camera): show the edge arrow instead.
				local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
				local viewport = camera.ViewportSize
				if onScreen then
					marker.arrow.Visible = false
				else
					local center = viewport / 2
					local dir = Vector2.new(screenPos.X, screenPos.Y) - center
					if screenPos.Z < 0 then
						dir = -dir
					end
					if dir.Magnitude < 1 then
						dir = Vector2.new(0, 1)
					end
					local margin = 36
					local scale = math.min(
						(center.X - margin) / math.max(math.abs(dir.X), 1e-3),
						(center.Y - margin) / math.max(math.abs(dir.Y), 1e-3)
					)
					local at = center + dir * scale
					marker.arrow.Position = UDim2.fromOffset(at.X, at.Y)
					marker.arrow.Visible = player:GetAttribute("MatchOver") ~= true
				end
			end
		end
	end
	for other in markers do
		if other.Parent ~= Players then
			remove(other)
		end
	end
end

function DownedMarkerController.Start()
	local accumulator = 0
	RunService.RenderStepped:Connect(function(dt)
		accumulator += dt
		if accumulator < 0.05 then
			return
		end
		accumulator = 0
		update()
	end)
	Players.PlayerRemoving:Connect(remove)
end

return DownedMarkerController
