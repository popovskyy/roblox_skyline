--!strict
-- Always-visible inventory hotbar along the bottom of the screen, the resource pouch above it and the storage
-- panel opened from the roof chest. Selecting a slot (click, tap or number key) takes that item in hand and
-- selecting it again puts it away; what a tap does with it is up to CombatController. Building resources
-- never take a slot: they are only counted in the pouch.
-- Buttons only send requests; the server decides and the next snapshot redraws the lists.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local ClientState = require(script.Parent.ClientState)
local ItemSlot = require(script.Parent.ItemSlot)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local InventoryController = {}

local player = Players.LocalPlayer
local C = UIKit.Colors
local remotes: Folder

local touch = UIKit.IsTouch()
local T = Theme.Colors
-- Phone: 6 slots (5 on narrow screens) between the thumbstick and the jump button. PC / console: 8.
local function slotCountFor(): number
	if not touch then
		return 8
	end
	local camera = workspace.CurrentCamera
	return if camera and camera.ViewportSize.X < 760 then 5 else 6
end
local SLOT_COUNT = slotCountFor()
local SLOT_SIZE = if touch then 54 else 68
local SLOT_GAP = if touch then 6 else 8
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
local bagButton: TextButton
local page = 1
-- Hotbar position (across pages) -> item; may have holes. slotOf is the reverse.
local ownedItems: { [number]: string } = {}
local slotOf: { [string]: number } = {}
local slots: { ItemSlot.Slot } = {}
local slotItems: { [number]: string } = {}
local tooltip: TextLabel
local tooltipToken = 0
local storagePanel: Frame
local storageList: Frame
local storageHeader: TextLabel
local pouch: Frame

local USE_LABELS: { [string]: string } = {
	Medkit = "ui.use",
	Food = "ui.eat",
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
	UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(size.X.Offset, 640), Parent = panel })
	UIKit.Padding(12).Parent = panel
	local header = UIKit.Label({
		Size = UDim2.new(1, -40, 0, 26),
		Text = "",
		FontFace = Theme.Bold,
		TextSize = 18,
		Parent = panel,
	})
	Lang.Bind(header, title)
	local close = UIKit.Button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(32, 32),
		Text = "X",
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

-- Holding a slot or a pouch counter for half a second drops it on the ground for teammates.
local HOLD_TO_DROP = 0.5
local suppressActivate = false

local function dropItem(itemId: string, amount: number | string)
	local remote = remotes:FindFirstChild(RemoteNames.DropItem) :: RemoteEvent?
	if remote then
		remote:FireServer(itemId, amount)
	end
end

local function holdToDrop(target: GuiObject, itemFor: () -> string?, amount: number | string)
	local token = 0
	target.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseButton1 then
			return
		end
		token += 1
		local mine = token
		task.delay(HOLD_TO_DROP, function()
			local itemId = itemFor()
			if token == mine and itemId then
				suppressActivate = true
				dropItem(itemId, amount)
			end
		end)
	end)
	target.InputEnded:Connect(function()
		token += 1
	end)
end

local function pouchChip(def: ItemDefinitions.ItemDef, count: number, order: number)
	local chip = UIKit.New("Frame", {
		Name = def.id,
		Size = UDim2.fromOffset(0, if touch then 28 else 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = if count > 0 then 0.35 else 0.6,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = pouch,
	}, {
		UIKit.Corner(6),
		UIKit.New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 10) }),
		UIKit.New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	if count > 0 then
		chip.Active = true
		holdToDrop(chip, function()
			return def.id
		end, 1)
	end
	local dim = if count > 0 then 0 else 0.5
	UIKit.New("ImageLabel", {
		Size = UDim2.fromOffset(if touch then 16 else 18, if touch then 16 else 18),
		BackgroundTransparency = 1,
		Image = def.iconImage or "",
		ImageTransparency = dim,
		LayoutOrder = 1,
		Parent = chip,
	})
	if not touch then
		UIKit.Label({
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = Lang.T("item." .. def.id .. ".name"),
			TextSize = 15,
			TextColor3 = T.CreamDim,
			TextTransparency = dim,
			TextWrapped = false,
			LayoutOrder = 2,
			Parent = chip,
		})
	end
	UIKit.Label({
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = tostring(count),
		FontFace = Theme.Display,
		TextSize = if touch then 17 else 18,
		TextColor3 = T.Cream,
		TextTransparency = dim,
		TextWrapped = false,
		LayoutOrder = 3,
		Parent = chip,
	})
end

local function pageCount(): number
	local last = 0
	for index in ownedItems do
		last = math.max(last, index)
	end
	return math.max(1, math.ceil(last / SLOT_COUNT))
end

local function renderInventory(s: { [string]: any })
	local weight = s.weight or 0
	local maxWeight = math.max(s.maxWeight or 1, 1)
	weightLabel.Text = Lang.T("hud.weight", weight, maxWeight)
	weightLabel.TextColor3 = if weight >= maxWeight then T.Amber else T.CreamDim

	-- Owned items keep the slot they first landed in and a new item takes the first free slot, so getting
	-- something never pushes another item off the visible page (paged when there are more than slots).
	-- Building resources are only counted in the pouch.
	for _, child in pouch:GetChildren() do
		if child:IsA("Frame") and child.Name ~= "Weight" then
			child:Destroy()
		end
	end
	local owned: { [string]: boolean } = {}
	for order, itemId in ItemDefinitions.Order do
		local count = s.inventory and s.inventory[itemId] or 0
		local def = ItemDefinitions.Items[itemId]
		if def.resource then
			pouchChip(def, count, order)
		elseif count > 0 then
			owned[itemId] = true
		end
	end
	for itemId, index in slotOf do
		if not owned[itemId] then
			slotOf[itemId] = nil
			ownedItems[index] = nil
		end
	end
	-- An item left on a later page moves into a gap on the first page, so it is never hidden behind "+".
	local overflow: { number } = {}
	for index in ownedItems do
		if index > SLOT_COUNT then
			table.insert(overflow, index)
		end
	end
	table.sort(overflow)
	for _, from in overflow do
		local to = 1
		while to <= SLOT_COUNT and ownedItems[to] do
			to += 1
		end
		if to > SLOT_COUNT then
			break
		end
		local itemId = ownedItems[from]
		ownedItems[from] = nil
		ownedItems[to] = itemId
		slotOf[itemId] = to
	end
	for _, itemId in ItemDefinitions.Order do
		if owned[itemId] and not slotOf[itemId] then
			local index = 1
			while ownedItems[index] do
				index += 1
			end
			slotOf[itemId] = index
			ownedItems[index] = itemId
		end
	end
	local pages = pageCount()
	page = math.clamp(page, 1, pages)
	bagButton.Visible = pages > 1
	bagButton.Text = ("+ %d/%d"):format(page, pages)
	table.clear(slotItems)
	for i = 1, SLOT_COUNT do
		slotItems[i] = ownedItems[(page - 1) * SLOT_COUNT + i]
	end
	for i, slot in slots do
		local itemId = slotItems[i]
		local count = if itemId and s.inventory then s.inventory[itemId] or 0 else 0
		slot.set(itemId, count, itemId ~= nil and itemId == player:GetAttribute("Equipped"))
	end
end

-- The name of what was just taken in hand, above its slot, for 1.5 s (weapons in their rarity colour).
local function showTooltip(text: string, slotIndex: number?, color: Color3?)
	tooltipToken += 1
	local token = tooltipToken
	tooltip.Text = text
	tooltip.TextColor3 = color or T.AmberText
	local index = slotIndex or math.ceil(SLOT_COUNT / 2)
	local x = (index - 0.5) * SLOT_SIZE + (index - 1) * SLOT_GAP
	tooltip.Position = UDim2.fromOffset(x, if touch then -42 else -48)
	tooltip.TextTransparency = 0
	tooltip.BackgroundTransparency = 0.2
	local stroke = tooltip:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0
		stroke.Color = color or T.Amber
	end
	tooltip.Visible = true
	task.delay(1.5, function()
		if tooltipToken ~= token then
			return
		end
		local info = TweenInfo.new(0.4)
		TweenService:Create(tooltip, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		if stroke then
			TweenService:Create(stroke, info, { Transparency = 1 }):Play()
		end
	end)
end

-- Gamepad shortcut: D-pad up uses a medkit, D-pad down eats food.
local function useItem(itemId: string)
	local remote = remotes:FindFirstChild(RemoteNames.UseItem) :: RemoteEvent
	remote:FireServer(itemId)
end

local function activateSlot(i: number)
	local itemId = slotItems[i]
	local def = if itemId then ItemDefinitions.Get(itemId) else nil
	if not def then
		return
	end
	local s = ClientState.Get()
	local count = s and s.inventory and s.inventory[def.id] or 0
	-- Take it in hand, or put it away when it is already there.
	local equipRemote = remotes:FindFirstChild(RemoteNames.Equip) :: RemoteEvent
	equipRemote:FireServer(def.id)
	if player:GetAttribute("Equipped") == def.id then
		return
	end
	local useLabel = USE_LABELS[def.id]
	local name = Lang.T("item." .. def.id .. ".name")
	if useLabel then
		showTooltip(("%s · %s"):format(name, Lang.T(useLabel)), i)
	elseif def.weapon then
		showTooltip(Lang.ItemWithRarity(def.id), i, if def.rarity then Theme.Rarity[def.rarity] else nil)
	else
		showTooltip(if count > 1 then ("%s ×%d"):format(name, count) else name, i)
	end
end

-- Gamepad: L1 / R1 (or D-pad left / right) step through the hotbar and take that item in hand.
local gamepadSlot = 0
local function stepSlot(direction: number)
	-- Slots can have holes (an item used up keeps the others in place); step over the filled ones.
	local filled: { number } = {}
	for i = 1, SLOT_COUNT do
		if slotItems[i] then
			table.insert(filled, i)
		end
	end
	local count = #filled
	if count == 0 then
		return
	end
	local held = player:GetAttribute("Equipped")
	local current = 0
	for n, i in filled do
		if slotItems[i] == held then
			current = n
		end
	end
	if current == 0 then
		current = table.find(filled, gamepadSlot) or 0
	end
	local nextAt = ((current - 1 + direction) % count) + 1
	if current == 0 then
		nextAt = if direction > 0 then 1 else count
	end
	gamepadSlot = filled[nextAt]
	activateSlot(gamepadSlot)
end

local function buildHotbar(screen: ScreenGui)
	local rowWidth = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_GAP
	local holder = UIKit.New("Frame", {
		Name = "Hotbar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, if touch then -10 else -24),
		Size = UDim2.fromOffset(rowWidth, SLOT_SIZE),
		BackgroundTransparency = 1,
		Parent = screen,
	})

	local row = UIKit.New("Frame", {
		Size = UDim2.fromScale(1, 1),
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
		if not touch then
			UIKit.Label({
				Position = UDim2.fromOffset(6, 3),
				Size = UDim2.fromOffset(14, 16),
				Text = tostring(i),
				FontFace = Theme.Display,
				TextSize = 14,
				TextColor3 = T.Muted,
				Parent = slot.frame,
			})
		end
		slot.frame.Activated:Connect(function()
			if suppressActivate then
				-- The press was a hold that dropped the item.
				suppressActivate = false
				return
			end
			activateSlot(i)
		end)
		holdToDrop(slot.frame, function()
			return slotItems[i]
		end, "all")
	end

	-- "More" button right of the slots: flips to the next page of items.
	bagButton = UIKit.Button({
		Name = "Bag",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(1, SLOT_GAP, 1, 0),
		Size = UDim2.fromOffset(if touch then 44 else 56, SLOT_SIZE),
		BackgroundColor3 = T.Slot,
		BackgroundTransparency = 0.18,
		Text = "+",
		FontFace = Theme.Display,
		TextSize = 15,
		TextColor3 = T.Cream,
		Visible = false,
		Parent = holder,
	})
	bagButton.Activated:Connect(function()
		page += 1
		if page > pageCount() then
			page = 1
		end
		local s = ClientState.Get()
		if s then
			renderInventory(s)
		end
	end)

	-- Pouch (resources) and carry weight, centred above the slots.
	pouch = UIKit.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -6),
		Size = UDim2.fromOffset(0, if touch then 28 else 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = holder,
	})
	UIKit.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = pouch,
	})
	local weightChip = UIKit.New("Frame", {
		Name = "Weight",
		Size = UDim2.fromOffset(0, if touch then 28 else 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		LayoutOrder = 100,
		Parent = pouch,
	}, { UIKit.Corner(6), UIKit.New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
	weightLabel = UIKit.Label({
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "",
		FontFace = Theme.Semi,
		TextSize = if touch then 15 else 16,
		TextColor3 = T.CreamDim,
		TextWrapped = false,
		Parent = weightChip,
	})

	-- Name of the item just taken in hand, floating above its slot.
	tooltip = UIKit.Label({
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Bold,
		TextSize = if touch then 15 else 17,
		TextColor3 = T.AmberText,
		TextWrapped = false,
		Visible = false,
		ZIndex = 3,
		Parent = holder,
	})
	UIKit.Corner(6).Parent = tooltip
	UIKit.New("UIStroke", { Color = T.Amber, Thickness = 1.5, Parent = tooltip })
	UIKit.New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = tooltip })

	-- Nothing to hold while lying down.
	local function updateDowned()
		holder.Visible = player:GetAttribute("Downed") ~= true
	end
	player:GetAttributeChangedSignal("Downed"):Connect(updateDowned)
	updateDowned()
end

local function transfer(direction: string, itemId: string, amount: number)
	local remote = remotes:FindFirstChild(RemoteNames.StorageTransfer) :: RemoteEvent
	remote:FireServer(direction, itemId, amount)
end

local CHEST_SLOT = 76

-- One labelled grid of item slots. Tapping a slot moves the whole stack to the other side.
local function storageSection(
	order: number,
	titleKey: string,
	emptyKey: string,
	counts: { [string]: number },
	onTap: (itemId: string, count: number) -> ()
)
	local section = UIKit.New("Frame", {
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = storageList,
	})
	UIKit.New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = section })
	UIKit.Label({
		Size = UDim2.new(1, 0, 0, 26),
		Text = Lang.T(titleKey),
		FontFace = Theme.Heading,
		TextSize = 22,
		LayoutOrder = 1,
		Parent = section,
	})
	local grid = UIKit.New("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = section,
	})
	UIKit.New("UIGridLayout", {
		CellSize = UDim2.fromOffset(CHEST_SLOT, CHEST_SLOT),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	local any = false
	for i, itemId in ItemDefinitions.Order do
		local def = ItemDefinitions.Items[itemId]
		local count = counts[itemId] or 0
		if def.storable and count > 0 then
			any = true
			local slot = ItemSlot.New(grid, CHEST_SLOT, i)
			slot.set(itemId, count, false)
			slot.frame.Activated:Connect(function()
				onTap(itemId, count)
			end)
		end
	end
	if not any then
		UIKit.Label({
			Size = UDim2.new(1, 0, 0, 30),
			Text = Lang.T(emptyKey),
			TextColor3 = C.muted,
			LayoutOrder = 3,
			Parent = section,
		})
	end
end

local function renderStorage(s: { [string]: any })
	storageHeader.Text =
		Lang.T("ui.storageHeader", s.storageWeight or 0, s.storageCapacity or 0, s.weight or 0, s.maxWeight or 0)
	clearRows(storageList)
	UIKit.New(
		"Frame",
		{ Size = UDim2.new(1, -8, 0, 24), BackgroundTransparency = 1, LayoutOrder = 0, Parent = storageList },
		{
			UIKit.Label({
				Size = UDim2.fromScale(1, 1),
				Text = Lang.T("ui.chestHint"),
				TextColor3 = C.muted,
				TextSize = 15,
			}),
		}
	)
	storageSection(1, "ui.backpack", "ui.emptyBackpack", s.inventory or {}, function(itemId, count)
		transfer("Deposit", itemId, count)
	end)
	storageSection(2, "ui.storage", "ui.emptyChest", s.storage or {}, function(itemId, count)
		transfer("Withdraw", itemId, count)
	end)
end

-- "+N" over the pouch counter when loot flies into it, with a little bump of the counter.
function InventoryController.FlashPouch(itemId: string, amount: number)
	local chip = pouch:FindFirstChild(itemId)
	local holder = pouch.Parent :: GuiObject
	local x = if chip and chip:IsA("GuiObject")
		then chip.AbsolutePosition.X - holder.AbsolutePosition.X + chip.AbsoluteSize.X / 2
		else 20
	local popup = UIKit.Label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromOffset(x, -30),
		Size = UDim2.fromOffset(80, 24),
		Text = "+" .. tostring(amount),
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Display,
		TextSize = 22,
		TextColor3 = C.good,
		TextStrokeTransparency = 0.3,
		Parent = holder,
	})
	TweenService:Create(popup, TweenInfo.new(0.9), { Position = UDim2.fromOffset(x, -60), TextTransparency = 1 }):Play()
	task.delay(1, function()
		popup:Destroy()
	end)
	if chip and chip:IsA("GuiObject") then
		local scale = chip:FindFirstChildOfClass("UIScale") or UIKit.New("UIScale", { Parent = chip })
		scale.Scale = 1.35
		TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end

function InventoryController.OpenStorage()
	storagePanel.Visible = true
	local s = ClientState.Get()
	if s then
		renderStorage(s)
	end
	-- Gamepads navigate menus through the selected object, so focus the first button.
	if UserInputService.GamepadEnabled then
		local first = storageList:FindFirstChildWhichIsA("TextButton", true)
		if first then
			GuiService.SelectedObject = first
		end
	end
end

function InventoryController.Start(remoteFolder: Folder)
	remotes = remoteFolder
	local screen = UIKit.Screen()

	buildHotbar(screen)
	storagePanel, storageList, storageHeader =
		makeWindow("Storage", "ui.storage", UDim2.new(0, 560, 0.8, 0), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local slotIndex = table.find(NUMBER_KEYS, input.KeyCode)
		if slotIndex and slotIndex <= SLOT_COUNT then
			activateSlot(slotIndex)
		elseif
			input.KeyCode == Enum.KeyCode.G or input.KeyCode == Enum.KeyCode.ButtonB and not storagePanel.Visible
		then
			-- G / B: drop what is in hand for a teammate.
			local held = player:GetAttribute("Equipped")
			if type(held) == "string" then
				dropItem(held, "all")
			end
		elseif input.KeyCode == Enum.KeyCode.ButtonR1 or input.KeyCode == Enum.KeyCode.DPadRight then
			stepSlot(1)
		elseif input.KeyCode == Enum.KeyCode.ButtonL1 or input.KeyCode == Enum.KeyCode.DPadLeft then
			stepSlot(-1)
		elseif input.KeyCode == Enum.KeyCode.DPadUp then
			useItem("Medkit")
		elseif input.KeyCode == Enum.KeyCode.DPadDown then
			useItem("Food")
		elseif input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			if storagePanel.Visible then
				storagePanel.Visible = false
				GuiService.SelectedObject = nil
			end
		end
	end)

	-- Highlight the slot of the weapon in hand.
	player:GetAttributeChangedSignal("Equipped"):Connect(function()
		local s = ClientState.Get()
		if s then
			renderInventory(s)
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
