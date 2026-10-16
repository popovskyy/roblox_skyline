--!strict
-- Inventory panel (key I or the button) and the storage panel opened from the roof crate.
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
local SLOT_SIZE = 72

local inventoryPanel: Frame
local weightLabel: TextLabel
local weightFill: Frame
local slots: { ItemSlot.Slot } = {}
local slotItems: { [number]: string } = {}
local selectedItem: string? = nil
local detailName: TextLabel
local detailText: TextLabel
local useButton: TextButton
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
	if selectedItem and not table.find(slotItems, selectedItem) then
		selectedItem = nil
	end
	for i, slot in slots do
		local itemId = slotItems[i]
		local count = if itemId and s.inventory then s.inventory[itemId] or 0 else 0
		slot.set(itemId, count, itemId ~= nil and itemId == selectedItem)
	end

	local def = if selectedItem then ItemDefinitions.Get(selectedItem) else nil
	if def then
		local count = s.inventory and s.inventory[def.id] or 0
		detailName.Text = ("%s %s  ×%d"):format(def.icon, def.displayName, count)
		detailText.Text = ("%s\nВага: %d за штуку"):format(def.description, def.weight)
		local useLabel = USE_LABELS[def.id]
		useButton.Visible = useLabel ~= nil
		useButton.Text = useLabel or ""
	else
		detailName.Text = if index == 0 then "Рюкзак порожній" else "Вибери предмет"
		detailText.Text = ""
		useButton.Visible = false
	end
end

local function buildInventory(screen: ScreenGui)
	local gridWidth = SLOT_COUNT / 2 * SLOT_SIZE + (SLOT_COUNT / 2 - 1) * 8
	inventoryPanel = UIKit.Panel({
		Name = "Inventory",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.fromOffset(gridWidth + 24, 340),
		BackgroundTransparency = 0.08,
		Visible = false,
		Parent = screen,
	})
	UIKit.Padding(12).Parent = inventoryPanel

	UIKit.Label({
		Size = UDim2.new(1, -40, 0, 24),
		Text = "Рюкзак",
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		Parent = inventoryPanel,
	})
	local close = UIKit.Button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(30, 30),
		Text = "✕",
		Parent = inventoryPanel,
	})
	close.Activated:Connect(function()
		inventoryPanel.Visible = false
	end)

	weightLabel = UIKit.Label({
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 18),
		Text = "Вага 0 / 20",
		TextSize = 14,
		TextColor3 = C.muted,
		Parent = inventoryPanel,
	})
	local bar = UIKit.New("Frame", {
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = C.panelLight,
		BorderSizePixel = 0,
		Parent = inventoryPanel,
	}, { UIKit.Corner(3) })
	weightFill = UIKit.New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.good,
		BorderSizePixel = 0,
		Parent = bar,
	}, { UIKit.Corner(3) })

	local grid = UIKit.New("Frame", {
		Position = UDim2.fromOffset(0, 66),
		Size = UDim2.new(1, 0, 0, SLOT_SIZE * 2 + 8),
		BackgroundTransparency = 1,
		Parent = inventoryPanel,
	})
	UIKit.New("UIGridLayout", {
		CellSize = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	for i = 1, SLOT_COUNT do
		local slot = ItemSlot.New(grid, SLOT_SIZE, i)
		slots[i] = slot
		slot.frame.Activated:Connect(function()
			local itemId = slotItems[i]
			selectedItem = if itemId == selectedItem then nil else itemId
			local s = ClientState.Get()
			if s then
				renderInventory(s)
			end
		end)
	end

	local detailTop = 66 + SLOT_SIZE * 2 + 16
	detailName = UIKit.Label({
		Position = UDim2.fromOffset(0, detailTop),
		Size = UDim2.new(1, -130, 0, 22),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		Text = "",
		Parent = inventoryPanel,
	})
	detailText = UIKit.Label({
		Position = UDim2.fromOffset(0, detailTop + 24),
		Size = UDim2.new(1, -130, 0, 48),
		TextSize = 13,
		TextColor3 = C.muted,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "",
		Parent = inventoryPanel,
	})
	useButton = UIKit.Button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, detailTop + 6),
		Size = UDim2.fromOffset(120, 40),
		Text = "",
		BackgroundColor3 = Color3.fromRGB(60, 100, 60),
		Visible = false,
		Parent = inventoryPanel,
	})
	useButton.Activated:Connect(function()
		if selectedItem then
			(remotes:FindFirstChild(RemoteNames.UseItem) :: RemoteEvent):FireServer(selectedItem)
		end
	end)
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

function InventoryController.Toggle()
	inventoryPanel.Visible = not inventoryPanel.Visible
	local s = ClientState.Get()
	if inventoryPanel.Visible and s then
		renderInventory(s)
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

	buildInventory(screen)
	storagePanel, storageList, storageHeader = makeWindow(
		"Storage",
		"Сховище",
		UDim2.new(0, 470, 0.7, 0),
		UDim2.fromScale(0.5, 0.5),
		Vector2.new(0.5, 0.5)
	)

	local openButton = UIKit.Button({
		Name = "InventoryButton",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -12),
		Size = UDim2.fromOffset(160, 44),
		Text = if UserInputService.TouchEnabled then "Інвентар" else "Інвентар (I)",
		Parent = screen,
	})
	openButton.Activated:Connect(InventoryController.Toggle)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.I then
			InventoryController.Toggle()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			inventoryPanel.Visible = false
			storagePanel.Visible = false
		end
	end)

	ClientState.Changed:Connect(function(s)
		if inventoryPanel.Visible then
			renderInventory(s)
		end
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
