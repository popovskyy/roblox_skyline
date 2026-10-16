--!strict
-- Inventory panel (key I or the button) and the storage panel opened from the roof crate.
-- Buttons only send requests; the server decides and the next snapshot redraws the lists.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local ClientState = require(script.Parent.ClientState)
local UIKit = require(script.Parent.UIKit)

local InventoryController = {}

local player = Players.LocalPlayer
local C = UIKit.Colors
local remotes: Folder

local inventoryPanel: Frame
local inventoryList: Frame
local inventoryHeader: TextLabel
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
	inventoryHeader.Text = ("Інвентар · вага %d / %d"):format(s.weight or 0, s.maxWeight or 0)
	clearRows(inventoryList)
	local any = false
	for order, itemId in ItemDefinitions.Order do
		local count = s.inventory and s.inventory[itemId] or 0
		if count > 0 then
			any = true
			local def = ItemDefinitions.Items[itemId]
			local row = UIKit.New("Frame", {
				Size = UDim2.new(1, -8, 0, 44),
				BackgroundColor3 = C.panelLight,
				BorderSizePixel = 0,
				LayoutOrder = order,
				Parent = inventoryList,
			}, { UIKit.Corner(6), UIKit.Padding(6) })
			UIKit.Label({
				Size = UDim2.new(1, -120, 1, 0),
				Text = ("%s ×%d   (вага %d)"):format(def.displayName, count, def.weight * count),
				TextSize = 15,
				Parent = row,
			})
			local useLabel = USE_LABELS[itemId]
			if useLabel then
				local button = UIKit.Button({
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.fromOffset(112, 32),
					Text = useLabel,
					TextSize = 14,
					BackgroundColor3 = Color3.fromRGB(60, 90, 60),
					Parent = row,
				})
				button.Activated:Connect(function()
					(remotes:FindFirstChild(RemoteNames.UseItem) :: RemoteEvent):FireServer(itemId)
				end)
			end
		end
	end
	if not any then
		UIKit.New("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = inventoryList }, {
			UIKit.Label({ Size = UDim2.fromScale(1, 1), Text = "Порожньо", TextColor3 = C.muted }),
		})
	end
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
				Text = ("%s\nз собою %d · у сховищі %d"):format(def.displayName, carried, stored),
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

	inventoryPanel, inventoryList, inventoryHeader = makeWindow(
		"Inventory",
		"Інвентар",
		UDim2.new(0, 360, 0.6, 0),
		UDim2.new(0, 12, 0.5, 0),
		Vector2.new(0, 0.5)
	)
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
