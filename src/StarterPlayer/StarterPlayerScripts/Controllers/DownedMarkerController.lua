--!strict
-- Screen-edge + world markers for downed teammates (dir + meters). Cap closest 2; mobile-readable.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Theme"))
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local DownedMarkerController = {}

local player = Players.LocalPlayer
local MAX_SHOW = 2
local MAX_DIST = 250
local AMBER = Color3.fromRGB(255, 196, 64)

type Marker = {
	userId: number,
	billboard: BillboardGui,
	label: TextLabel,
	edge: Frame,
	edgeLabel: TextLabel,
}

local markers: { [number]: Marker } = {}
local screen: ScreenGui

local function destroyMarker(userId: number)
	local m = markers[userId]
	if not m then
		return
	end
	markers[userId] = nil
	m.billboard:Destroy()
	m.edge:Destroy()
end

local function ensureMarker(other: Player): Marker
	local existing = markers[other.UserId]
	if existing then
		return existing
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DownedMarker_" .. other.UserId
	billboard.Size = UDim2.fromOffset(160, 90)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = MAX_DIST
	billboard.Parent = player:WaitForChild("PlayerGui")

	local arrow = Instance.new("TextLabel")
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromScale(1, 0.45)
	arrow.Text = "▼"
	arrow.TextScaled = true
	arrow.FontFace = Theme.Display
	arrow.TextColor3 = AMBER
	arrow.TextStrokeTransparency = 0.25
	arrow.Parent = billboard

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, 0.45)
	label.Size = UDim2.fromScale(1, 0.55)
	label.TextScaled = true
	label.FontFace = Theme.Bold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.25
	label.Parent = billboard

	local edge = UIKit.New("Frame", {
		Name = "DownedEdge_" .. other.UserId,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = Color3.fromRGB(18, 16, 14),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 20,
		Parent = screen,
	}, { UIKit.Corner(8) })
	local edgeLabel = UIKit.Label({
		Size = UDim2.fromScale(1, 1),
		Text = "◀",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 22,
		TextColor3 = AMBER,
		FontFace = Theme.Display,
		ZIndex = 21,
		Parent = edge,
	})

	local m: Marker = {
		userId = other.UserId,
		billboard = billboard,
		label = label,
		edge = edge,
		edgeLabel = edgeLabel,
	}
	markers[other.UserId] = m
	return m
end

local function rootOf(p: Player): BasePart?
	local character = p.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

function DownedMarkerController.Start()
	screen = UIKit.Screen()
	local clock = 0
	RunService.RenderStepped:Connect(function(dt)
		clock += dt
		local myRoot = rootOf(player)
		local camera = Workspace.CurrentCamera
		if not myRoot or not camera then
			for id in markers do
				destroyMarker(id)
			end
			return
		end

		type Candidate = { player: Player, root: BasePart, dist: number }
		local list: { Candidate } = {}
		for _, other in Players:GetPlayers() do
			if other ~= player and other:GetAttribute("Downed") == true then
				local root = rootOf(other)
				if root then
					local dist = (root.Position - myRoot.Position).Magnitude
					if dist <= MAX_DIST then
						table.insert(list, { player = other, root = root, dist = dist })
					end
				end
			end
		end
		table.sort(list, function(a, b)
			return a.dist < b.dist
		end)

		local keep: { [number]: boolean } = {}
		for i = 1, math.min(MAX_SHOW, #list) do
			local c = list[i]
			keep[c.player.UserId] = true
			local m = ensureMarker(c.player)
			m.billboard.Adornee = c.root
			m.billboard.Enabled = true
			local meters = math.floor(c.dist)
			local name = string.sub(c.player.DisplayName, 1, 10)
			m.label.Text = Lang.T("marker.downed", name, meters)
			-- Gentle pulse when close.
			local pulse = if c.dist < 30 then 0.85 + 0.15 * math.sin(clock * math.pi * 2) else 1
			m.billboard.Size = UDim2.fromOffset(160 * pulse, 90 * pulse)

			local screenPos, onScreen = camera:WorldToViewportPoint(c.root.Position + Vector3.new(0, 3, 0))
			local viewport = camera.ViewportSize
			if onScreen and screenPos.Z > 0 then
				m.edge.Visible = false
			else
				-- Edge chevron toward off-screen teammate.
				local dir = Vector2.new(screenPos.X - viewport.X / 2, screenPos.Y - viewport.Y / 2)
				if dir.Magnitude < 1 then
					dir = Vector2.new(0, -1)
				end
				dir = dir.Unit
				local margin = 36
				local edgePos = Vector2.new(viewport.X / 2, viewport.Y / 2) + dir * (math.min(viewport.X, viewport.Y) * 0.42)
				edgePos = Vector2.new(
					math.clamp(edgePos.X, margin, viewport.X - margin),
					math.clamp(edgePos.Y, margin + 40, viewport.Y - margin)
				)
				m.edge.Position = UDim2.fromOffset(edgePos.X, edgePos.Y)
				m.edge.Visible = true
				m.edgeLabel.Text = Lang.T("marker.downed", name, meters)
				m.edge.Size = UDim2.fromOffset(120, 40)
			end
		end
		for id in markers do
			if not keep[id] then
				destroyMarker(id)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(leaving)
		destroyMarker(leaving.UserId)
	end)
end

return DownedMarkerController
