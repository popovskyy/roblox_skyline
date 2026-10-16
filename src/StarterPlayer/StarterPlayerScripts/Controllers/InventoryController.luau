--!strict
-- Always-visible inventory hotbar along the bottom of the screen and the storage panel opened from the roof crate.
-- Clicking a slot (or pressing its number key) uses Medkit / Food; other items just show their name.
-- Buttons only send requests; the server decides and the next snapshot redraws the lists.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local ClientState = require(script.Parent.ClientState)
local ItemSlot = require(script.Parent.ItemSlot)
local UIKit = require(script.Parent.UIKit)

local InventoryController = {}

local player = Players.LocalPlayer
local C = UIKit.Colors
local remotes: Folder

local SLOT_COUNT = 10
local SLOT_SIZE = if UserInputService.TouchEnabled then 50 else 60
local SLOT_GAP = 6
local NUMBER_KEYS = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
	Enum.KeyCode.Zero,
}

local weightLabel: TextLabel
local weightFill: Frame
local slots: { ItemSlot.Slot } = {}
local slotItems: { [number]: string } = {}
local tooltip: TextLabel
local tooltipToken = 0
local storagePanel: Frame
local storageList: Frame
local storageHeader: TextLabel

local USE_LABELS: { [string]: string } = {
	Medkit = "Використати",
	Food = "З'їсти",
}

local function clearRows(list: Frame)
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function makeWindow(
	name: string,
	title: string,
	size: UDim2,
	position: UDim2,
	anchor: Vector2
): (Frame, Frame, TextLabel)
	local screen = UIKit.Screen()
	local panel = UIKit.Panel({
		Name = name,
		AnchorPoint = anchor,
		Position = position,
		Size = size,
		Visible = false,
		BackgroundTransparency = 0.05,
		Parent = screen,
	})
	UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(size.X.Offset, 520), Parent = panel })
	UIKit.Padding(12).Parent = panel
	local header = UIKit.Label({
		Size = UDim2.new(1, -40, 0, 26),
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		Parent = panel,
	})
	local close = UIKit.Button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(32, 32),
		Text = "✕",
		Parent = panel,
	})
	close.Activated:Connect(function()
		panel.Visible = false
	end)
	local list = UIKit.New("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 1, -40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	})
	UIKit.New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	return panel, list, header
end

local function renderInventory(s: { [string]: any })
	local weight = s.weight or 0
	local maxWeight = math.max(s.maxWeight or 1, 1)
	weightLabel.Text = ("Вага %d / %d"):format(weight, maxWeight)
	weightFill.Size = UDim2.fromScale(math.clamp(weight / maxWeight, 0, 1), 1)
	weightFill.BackgroundColor3 = if weight >= maxWeight then C.warn else C.good

	-- Owned items fill the slots in a fixed order; the rest stay empty.
	table.clear(slotItems)
	local index = 0
	for _, itemId in ItemDefinitions.Order do
		local count = s.inventory and s.inventory[itemId] or 0
		if count > 0 and index < SLOT_COUNT then
			index += 1
			slotItems[index] = itemId
		end
	end
	for i, slot in slots do
		local itemId = slotItems[i]
		local count = if itemId and s.inventory then s.inventory[itemId] or 0 else 0
		slot.set(itemId, count, false)
	end
end

local function showTooltip(text: string)
	tooltipToken += 1
	local token = tooltipToken
	tooltip.Text = text
	tooltip.Visible = true
	task.delay(2.5, function()
		if tooltipToken == token then
			tooltip.Visible = false
		end
	end)
end

local function activateSlot(i: number)
	local itemId = slotItems[i]
	local def = if itemId then ItemDefinitions.Get(itemId) else nil
	if not def then
		return
	end
	local s = ClientState.Get()
	local count = s and s.inventory and s.inventory[def.id] or 0
	local useLabel = USE_LABELS[def.id]
	if useLabel then
		(remotes:FindFirstChild(RemoteNames.UseItem) :: RemoteEvent):FireServer(def.id)
		showTooltip(("%s %s · %s"):format(def.icon, def.displayName, useLabel))
	else
		showTooltip(("%s %s ×%d · %s"):format(def.icon, def.displayName, count, def.description))
	end
end

local function buildHotbar(screen: ScreenGui)
	local width = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_GAP
	local holder = UIKit.New("Frame", {
		Name = "Hotbar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(width, SLOT_SIZE + 26),
		BackgroundTransparency = 1,
		Parent = screen,
	})

	weightLabel = UIKit.Label({
		Size = UDim2.fromOffset(120, 16),
		Text = "Вага 0 / 20",
		TextSize = 13,
		TextColor3 = C.muted,
		TextStrokeTransparency = 0.5,
		Parent = holder,
	})
	local bar = UIKit.New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 5),
		Size = UDim2.new(1, -130, 0, 6),
		BackgroundColor3 = C.panelLight,
		BorderSizePixel = 0,
		Parent = holder,
	}, { UIKit.Corner(3) })
	weightFill = UIKit.New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.good,
		BorderSizePixel = 0,
		Parent = bar,
	}, { UIKit.Corner(3) })

	local row = UIKit.New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, SLOT_SIZE),
		BackgroundTransparency = 1,
		Parent = holder,
	})
	UIKit.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, SLOT_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})
	for i = 1, SLOT_COUNT do
		local slot = ItemSlot.New(row, SLOT_SIZE, i)
		slots[i] = slot
		if not UserInputService.TouchEnabled then
			UIKit.Label({
				Position = UDim2.fromOffset(5, 2),
				Size = UDim2.fromOffset(14, 14),
				Text = tostring(i % 10),
				TextSize = 11,
				TextColor3 = C.muted,
				Parent = slot.frame,
			})
		end
		slot.frame.Activated:Connect(function()
			activateSlot(i)
		end)
	end

	tooltip = UIKit.Label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -6),
		Size = UDim2.new(1.4, 0, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextStrokeTransparency = 0.3,
		Visible = false,
		Parent = holder,
	})
end

local function transfer(direction: string, itemId: string, amount: number)
	(remotes:FindFirstChild(RemoteNames.StorageTransfer) :: RemoteEvent):FireServer(direction, itemId, amount)
end

local function renderStorage(s: { [string]: any })
	storageHeader.Text = ("Сховище %d / %d   ·   рюкзак %d / %d"):format(
		s.storageWeight or 0,
		s.storageCapacity or 0,
		s.weight or 0,
		s.maxWeight or 0
	)
	clearRows(storageList)
	for order, itemId in ItemDefinitions.Order do
		local def = ItemDefinitions.Items[itemId]
		if def.storable then
			local carried = s.inventory and s.inventory[itemId] or 0
			local stored = s.storage and s.storage[itemId] or 0
			local row = UIKit.New("Frame", {
				Size = UDim2.new(1, -8, 0, 48),
				BackgroundColor3 = C.panelLight,
				BorderSizePixel = 0,
				LayoutOrder = order,
				Parent = storageList,
			}, { UIKit.Corner(6), UIKit.Padding(6) })
			UIKit.Label({
				Size = UDim2.new(1, -230, 1, 0),
				Text = ("%s %s\nз собою %d · у сховищі %d"):format(
					def.icon,
					def.displayName,
					carried,
					stored
				),
				TextSize = 14,
				Parent = row,
			})
			local buttons = {
				{ text = "→ 1", direction = "Deposit", amount = 1, enabled = carried > 0 },
				{ text = "→ всі", direction = "Deposit", amount = math.max(carried, 1), enabled = carried > 0 },
				{ text = "← 1", direction = "Withdraw", amount = 1, enabled = stored > 0 },
				{ text = "← всі", direction = "Withdraw", amount = math.max(stored, 1), enabled = stored > 0 },
			}
			for i, info in buttons do
				local button = UIKit.Button({
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -(4 - i) * 56, 0.5, 0),
					Size = UDim2.fromOffset(52, 34),
					Text = info.text,
					TextSize = 13,
					BackgroundColor3 = if info.enabled then C.panelLight else C.panel,
					TextColor3 = if info.enabled then C.text else C.muted,
					Parent = row,
				})
				button.Activated:Connect(function()
					if info.enabled then
						transfer(info.direction, itemId, info.amount)
					end
				end)
			end
		end
	end
end

function InventoryController.OpenStorage()
	storagePanel.Visible = true
	local s = ClientState.Get()
	if s then
		renderStorage(s)
	end
end

function InventoryController.Start(remoteFolder: Folder)
	remotes = remoteFolder
	local screen = UIKit.Screen()

	buildHotbar(screen)
	storagePanel, storageList, storageHeader = makeWindow(
		"Storage",
		"Сховище",
		UDim2.new(0, 470, 0.7, 0),
		UDim2.fromScale(0.5, 0.5),
		Vector2.new(0.5, 0.5)
	)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local slotIndex = table.find(NUMBER_KEYS, input.KeyCode)
		if slotIndex then
			activateSlot(slotIndex)
		elseif input.KeyCode == Enum.KeyCode.Escape then
			storagePanel.Visible = false
		end
	end)

	ClientState.Changed:Connect(function(s)
		renderInventory(s)
		if storagePanel.Visible then
			renderStorage(s)
		end
	end)

	-- Close the storage window once the player walks away from the crate.
	task.spawn(function()
		while true do
			task.wait(0.5)
			if storagePanel.Visible then
				local world = workspace:FindFirstChild("GeneratedWorld")
				local interactables = world and world:FindFirstChild("Interactables")
				local crate = interactables and interactables:FindFirstChild("StorageCrate")
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if
					not crate
					or not root
					or ((crate :: BasePart).Position - (root :: BasePart).Position).Magnitude > 20
				then
					storagePanel.Visible = false
				end
			end
		end
	end)
end

return InventoryController
