--!strict
-- End-of-match results: win or loss title, then what the player did (floors, chests, zombies, buildings,
-- lifts) appearing one row at a time with tokens counting up, the win bonus and the saved total.
-- The server sends the summary (ShowResults) and, once saved, a second message with the new total.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundConfig = require(ReplicatedStorage.Shared:WaitForChild("SoundConfig"))
local Theme = require(ReplicatedStorage.Shared.Theme)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local ResultsController = {}

local C = UIKit.Colors
local CREAM = Color3.fromRGB(233, 223, 198)
local TOKEN = Color3.fromRGB(255, 196, 64)

local overlay: Frame? = nil
local totalLabel: TextLabel? = nil
local pendingTotal: number? = nil

local function tick(name: string, volume: number)
	local ids = SoundConfig.Sounds[name]
	if not ids then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(ids[math.random(1, #ids)])
	sound.Volume = volume
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

-- Counts a label from 0 up to `target` with a ticking sound.
local function countUp(label: TextLabel, target: number, format: (n: number) -> string, seconds: number)
	if target <= 0 then
		label.Text = format(0)
		return
	end
	local started = os.clock()
	local shown = -1
	while true do
		local t = math.min((os.clock() - started) / seconds, 1)
		local value = math.floor(target * (1 - (1 - t) ^ 3) + 0.5)
		if value ~= shown then
			shown = value
			label.Text = format(value)
		end
		if t >= 1 then
			break
		end
		task.wait()
	end
end

local function showTotal(total: number)
	local label = totalLabel
	if label then
		label.Text = Lang.T("results.total", total)
		label.Visible = true
	else
		pendingTotal = total
	end
end

local function show(result: { [string]: any })
	if overlay then
		overlay:Destroy()
	end
	totalLabel = nil
	local won = result.won == true
	local screen = UIKit.Screen()
	local root = UIKit.New("Frame", {
		Name = "Results",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(8, 8, 9),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = screen,
	})
	overlay = root
	TweenService:Create(root, TweenInfo.new(0.5), { BackgroundTransparency = 0.25 }):Play()

	local panel = UIKit.Panel({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 520, 0.92, 0),
		BackgroundColor3 = Color3.fromRGB(18, 19, 21),
		BackgroundTransparency = 0.05,
		ZIndex = 21,
		Parent = root,
	})
	UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(520, 470), Parent = panel })
	UIKit.New("UIStroke", { Color = CREAM, Transparency = 0.7, Thickness = 1.5, Parent = panel })
	UIKit.Padding(18).Parent = panel
	UIKit.New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })

	UIKit.Label({
		Size = UDim2.new(1, 0, 0, 48),
		Text = Lang.T(if won then "ending.title" else "gameover.title"),
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Display,
		TextSize = 40,
		TextColor3 = if won then C.good else Color3.fromRGB(255, 120, 110),
		LayoutOrder = 1,
		ZIndex = 22,
		Parent = panel,
	})
	UIKit.Label({
		Size = UDim2.new(1, 0, 0, 22),
		Text = Lang.T(if won then "ending.footer" else "results.lostSub"),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = C.muted,
		TextSize = 16,
		LayoutOrder = 2,
		ZIndex = 22,
		Parent = panel,
	})

	local function row(order: number, left: string, right: string?, color: Color3?): (TextLabel, TextLabel)
		local frame = UIKit.New("Frame", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Visible = false,
			ZIndex = 22,
			Parent = panel,
		})
		local l = UIKit.Label({
			Size = UDim2.fromScale(0.68, 1),
			Text = left,
			TextSize = 19,
			TextColor3 = CREAM,
			ZIndex = 22,
			Parent = frame,
		})
		local r = UIKit.Label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromScale(0.32, 1),
			Text = right or "",
			TextXAlignment = Enum.TextXAlignment.Right,
			FontFace = Theme.Display,
			TextSize = 22,
			TextColor3 = color or TOKEN,
			ZIndex = 22,
			Parent = frame,
		})
		return l, r
	end

	local rows = if type(result.rows) == "table" then result.rows else {}
	local built: { { frame: GuiObject, left: TextLabel, right: TextLabel, value: number, tokens: number, key: string } } =
		{}
	for i, data in rows do
		local left, right = row(10 + i, "", "")
		table.insert(built, {
			frame = left.Parent :: GuiObject,
			left = left,
			right = right,
			value = tonumber(data.value) or 0,
			tokens = tonumber(data.tokens) or 0,
			key = tostring(data.key),
		})
	end
	local bonusLeft, bonusRight = row(30, "", "", C.good)
	if type(result.bestTier) == "string" then
		local bestLeft = row(31, Lang.T("results.best", Lang.T("loot." .. result.bestTier)), nil)
		bestLeft.TextColor3 = C.muted;
		(bestLeft.Parent :: GuiObject).Visible = true
	end
	local earned = UIKit.Label({
		Size = UDim2.new(1, 0, 0, 56),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Display,
		TextSize = 44,
		TextColor3 = TOKEN,
		LayoutOrder = 40,
		ZIndex = 22,
		Parent = panel,
	})
	local total = UIKit.Label({
		Size = UDim2.new(1, 0, 0, 24),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 17,
		TextColor3 = C.muted,
		Visible = false,
		LayoutOrder = 41,
		ZIndex = 22,
		Parent = panel,
	})
	totalLabel = total
	local close = UIKit.Button({
		Size = UDim2.new(1, 0, 0, 40),
		Text = "OK",
		TextSize = 20,
		LayoutOrder = 50,
		ZIndex = 22,
		Parent = panel,
	})
	close.Activated:Connect(function()
		root:Destroy()
		if overlay == root then
			overlay = nil
			totalLabel = nil
		end
	end)
	if pendingTotal then
		showTotal(pendingTotal)
		pendingTotal = nil
	end

	task.spawn(function()
		task.wait(0.8)
		for _, r in built do
			r.frame.Visible = true
			r.left.Text = ("%s: %d"):format(Lang.T(r.key), r.value)
			tick("Click", 0.4)
			countUp(r.right, r.tokens, function(n)
				return "+" .. n
			end, 0.45)
			task.wait(0.25)
		end
		local multiplier = tonumber(result.multiplier) or 1
		if multiplier > 1 then
			(bonusLeft.Parent :: GuiObject).Visible = true
			bonusLeft.Text = Lang.T("results.winBonus", multiplier)
			bonusRight.Text = "×" .. multiplier
			tick("LootUpgrade", 0.6)
			task.wait(0.4)
		end
		local tokens = tonumber(result.tokens) or 0
		countUp(earned, tokens, function(n)
			return Lang.T("results.earned", n)
		end, 1.2)
		tick("Success", 0.6)
		local scale = UIKit.New("UIScale", { Scale = 1.25, Parent = earned })
		TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)
end

function ResultsController.Start(remotes: Folder)
	local remote = remotes:WaitForChild("ShowResults") :: RemoteEvent
	remote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		if type(payload.totalTokens) == "number" then
			showTotal(payload.totalTokens)
		else
			show(payload)
		end
	end)
end

return ResultsController
