--!strict
-- Resource nodes, loot crates and rubble. Floor loot is party-shared: one pickup / crate open /
-- rubble clear empties that node for everyone on the server. Unique tools still go only to the
-- picker, but the pile disappears for the whole party.
--
-- Node attributes:  NodeId, ItemId, Amount, Unique?, RequiresUpgrade?, RequiresRubble?
-- Rubble attributes: RubbleId, RequiresTool?, RewardItem?, RequiresUpgrade?

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local SfxService = require(script.Parent.SfxService)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local MatchStatsService = require(script.Parent.MatchStatsService)
local StateSyncService = require(script.Parent.StateSyncService)
local ZombieService = require(script.Parent.ZombieService)

local ResourceService = {}

type PlayerNodes = {
	seenGold: boolean, -- opened a gold or diamond crate this match (bad-luck protection)
	holdStart: number?, -- when the player started holding a locked crate's prompt
	holdCrate: Instance?,
}

local state: { [Player]: PlayerNodes } = {}
-- Shared match state: one clear / pickup / open for the whole party.
local clearedRubble: { [string]: boolean } = {}
local openedCrates: { [string]: boolean } = {}
local depletedNodes: { [string]: boolean } = {}
-- One-shot toast: Scrap (металобрухт) ≠ Crowbar (лом).
local scrapHinted: { [Player]: boolean } = {}

local function getState(player: Player): PlayerNodes
	local s = state[player]
	if not s then
		s = { seenGold = false }
		state[player] = s
	end
	return s
end

local function syncEveryone()
	for _, other in Players:GetPlayers() do
		StateSyncService.Request(other)
	end
end

-- Checks the access attributes a node or rubble may carry. Returns a reason when access is denied.
function ResourceService.CheckAccess(player: Player, object: Instance): any
	local data = PlayerDataService.Get(player)
	if not data then
		return "err.notLoaded"
	end
	local requiredUpgrade = object:GetAttribute("RequiresUpgrade")
	if type(requiredUpgrade) == "string" and not data.upgrades[requiredUpgrade] then
		return "res.zoneLocked"
	end
	local requiredRubble = object:GetAttribute("RequiresRubble")
	if type(requiredRubble) == "string" and not clearedRubble[requiredRubble] then
		return "res.blocked"
	end
	return nil
end

function ResourceService.IsTaken(player: Player, node: Instance): boolean
	local nodeId = node:GetAttribute("NodeId")
	if type(nodeId) ~= "string" then
		return true
	end
	-- Crates and resource piles share one emptied map for the whole party.
	if depletedNodes[nodeId] or openedCrates[nodeId] then
		return true
	end
	if node:GetAttribute("Unique") == true then
		local data = PlayerDataService.Get(player)
		return data ~= nil and data.uniqueNodesTaken[nodeId] == true
	end
	return false
end

function ResourceService.Collect(player: Player, node: BasePart): (boolean, any)
	local data = PlayerDataService.Get(player)
	local nodeId = node:GetAttribute("NodeId")
	local itemId = node:GetAttribute("ItemId")
	local amount = node:GetAttribute("Amount")
	if not data or type(nodeId) ~= "string" or not ItemDefinitions.IsValid(itemId) then
		return false, nil
	end
	if not InventoryService.IsPositiveInt(amount) then
		warn("[Resource] Misconfigured node", node:GetFullName())
		return false, nil
	end
	if ResourceService.IsTaken(player, node) then
		return false, "res.empty"
	end
	local denied = ResourceService.CheckAccess(player, node)
	if denied then
		return false, denied
	end
	local id = itemId :: string
	local count = amount :: number
	local unique = node:GetAttribute("Unique") == true
	local def = ItemDefinitions.Get(id)
	-- One of each tool is enough; keys are used up on locked crates, so they stack.
	local isTool = def ~= nil and not def.storable
	if unique and isTool and InventoryService.GetCount(player, id) > 0 then
		return false, "res.alreadyHave"
	end
	if not InventoryService.CanAdd(player, id, count) then
		return false, "res.full"
	end

	-- Party-shared: first picker empties the pile for everyone.
	depletedNodes[nodeId] = true
	if unique then
		data.uniqueNodesTaken[nodeId] = true
		PlayerDataService.MarkDirty(player)
	end
	InventoryService.Add(player, id, count)
	SfxService.Play("Pickup", node.Position, 0.8)
	syncEveryone()
	if id == "Scrap" and not scrapHinted[player] then
		scrapHinted[player] = true
		Net.Notify(player, "hint.scrapNotCrowbar", "info")
	end
	return true, nil
end

-- Open the doorway on the server. Client-only CanCollide was leaving an invisible wall on some devices
-- (SoftRubble dress makes the host transparent while it still collides until this runs).
local function openClearedRubble(rubble: BasePart)
	rubble.CanCollide = false
	rubble.CanQuery = false
	rubble.Transparency = 1
	for _, d in rubble:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.Transparency = 1
		end
		if d:IsA("ProximityPrompt") then
			d.Enabled = false
		end
		if d:IsA("SurfaceGui") then
			d.Enabled = false
		end
		if d:IsA("Light") then
			d.Enabled = false
		end
	end
end

function ResourceService.ClearRubble(player: Player, rubble: BasePart): (boolean, any)
	local rubbleId = rubble:GetAttribute("RubbleId")
	if type(rubbleId) ~= "string" then
		return false, nil
	end
	if clearedRubble[rubbleId] then
		return false, nil
	end
	local denied = ResourceService.CheckAccess(player, rubble)
	if denied then
		return false, denied
	end
	local tool = rubble:GetAttribute("RequiresTool")
	if type(tool) == "string" and not InventoryService.Has(player, tool, 1) then
		return false, "rubble.needCrowbar"
	end

	clearedRubble[rubbleId] = true
	openClearedRubble(rubble)
	SfxService.Play("Rubble", rubble.Position)
	local reward = rubble:GetAttribute("RewardItem")
	if ItemDefinitions.IsValid(reward) and InventoryService.GetCount(player, reward :: string) == 0 then
		-- The reward is a tool the player needs, so it ignores the weight limit.
		InventoryService.ForceAdd(player, reward :: string, 1)
		Net.Notify(player, { "rubble.found", Locale.Item(reward :: string) }, "success")
	end
	-- Everyone's world updates: the pile disappears for all players.
	syncEveryone()
	return true, nil
end

-- Loot crates: rolled when opened. Shared: one open empties the crate for every teammate.
-- Attributes: NodeId, Tier (Common/Rare/Gold/Diamond), RequiresUpgrade?, RequiresRubble?
local function rollLoot(player: Player, tier: string): { [string]: number }
	local loot: { [string]: number } = {}
	local tierTable = GameConfig.LootTables[tier]
	if not tierTable then
		return loot
	end
	for _, entry in tierTable do
		if not entry.chance or math.random() < entry.chance then
			local def = ItemDefinitions.Get(entry.item)
			local amount = math.random(entry.min, entry.max)
			-- One of each weapon is enough; a duplicate turns into scrap.
			if def and def.weapon and InventoryService.GetCount(player, entry.item) > 0 then
				loot.Scrap = (loot.Scrap or 0) + 2
			elseif def then
				loot[entry.item] = (loot[entry.item] or 0) + amount
			end
		end
	end
	return loot
end

local Loot = GameConfig.Loot

local function tierIndex(tier: string): number
	return table.find(Loot.TierOrder, tier) or 1
end

-- Floor number from a node id like "F3_Crate_1".
local function crateLevel(nodeId: string): number
	return tonumber(string.match(nodeId, "^F(%d+)_")) or 1
end

-- The tier this player actually gets: the crate's own, bumped to gold by bad-luck protection,
-- or one tier better by a lucky roll at the end of the hold.
local function finalTier(s: PlayerNodes, tier: string, level: number): string
	local index = tierIndex(tier)
	if not s.seenGold and level >= Loot.PityFloor and index < tierIndex("Gold") then
		return "Gold"
	end
	if index < #Loot.TierOrder and math.random() < Loot.UpgradeChance then
		return Loot.TierOrder[index + 1]
	end
	return tier
end

function ResourceService.OpenCrate(player: Player, crate: BasePart): (boolean, any)
	local data = PlayerDataService.Get(player)
	local nodeId = crate:GetAttribute("NodeId")
	local tier = crate:GetAttribute("Tier")
	if not data or type(nodeId) ~= "string" or type(tier) ~= "string" then
		return false, nil
	end
	local s = getState(player)
	if openedCrates[nodeId] or depletedNodes[nodeId] then
		return false, "loot.empty"
	end
	local denied = ResourceService.CheckAccess(player, crate)
	if denied then
		return false, denied
	end

	-- Locked (diamond) crates: a key opens them quietly; otherwise a full crowbar break-in.
	local useKey = false
	local breakIn = false
	if crate:GetAttribute("Locked") == true then
		if InventoryService.Has(player, "Key", 1) then
			useKey = true
		elseif
			InventoryService.Has(player, "Crowbar", 1)
			and s.holdCrate == crate
			and s.holdStart
			and os.clock() - s.holdStart >= Loot.BreakInSeconds - 0.5
		then
			breakIn = true
		else
			return false, "loot.locked"
		end
	end

	local level = crateLevel(nodeId)
	local final = finalTier(s, tier, level)
	local loot = rollLoot(player, final)
	if InventoryService.WeightOf(loot) > InventoryService.GetCapacity(player) - InventoryService.GetWeight(player) then
		return false, "res.full"
	end
	if useKey and not InventoryService.Remove(player, "Key", 1) then
		return false, "loot.locked"
	end
	openedCrates[nodeId] = true
	depletedNodes[nodeId] = true
	s.holdStart = nil
	s.holdCrate = nil
	if tierIndex(final) >= tierIndex("Gold") then
		s.seenGold = true
	end
	MatchStatsService.OpenedChest(player, final)
	SfxService.Play("CrateOpen", crate.Position)
	if breakIn then
		SfxService.Play("BreakIn", crate.Position)
		ZombieService.Alert(crate.Position, Loot.BreakInNoiseRadius, Loot.BreakInAlertSeconds)
		Net.Notify(player, "loot.breakIn", "warning")
	end
	for id, amount in loot do
		InventoryService.ForceAdd(player, id, amount)
	end
	-- Everyone sees the crate empty; only the opener gets the items.
	syncEveryone()
	Net.Get(RemoteNames.LootOpened):FireAllClients(crate, tier, final, player.UserId, player.DisplayName, loot)
	return true, nil
end

-- A fresh match on this server: every node, crate and rubble pile is back.
function ResourceService.ResetMatch(player: Player)
	state[player] = nil
	table.clear(clearedRubble)
	table.clear(openedCrates)
	table.clear(depletedNodes)
	StateSyncService.Request(player)
end

-- Called when the player comes back up to the roof (shared piles stay emptied — no roof refill).
function ResourceService.OnReturnedToRoof(_player: Player)
	if not GameConfig.ResetNodesOnRoofReturn then
		return
	end
	-- Shared scarcity: even with the flag on, do not refill party-emptied piles mid-match.
end

function ResourceService.Init()
	StateSyncService.RegisterProvider(function(player, snapshot)
		local data = PlayerDataService.Get(player)
		local depleted = table.clone(depletedNodes)
		for nodeId in openedCrates do
			depleted[nodeId] = true
		end
		snapshot.depletedNodes = depleted
		snapshot.clearedRubble = table.clone(clearedRubble)
		snapshot.uniqueNodesTaken = if data then table.clone(data.uniqueNodesTaken) else {}
	end)
	Players.PlayerRemoving:Connect(function(player)
		state[player] = nil
		scrapHinted[player] = nil
	end)
	-- Timing the crowbar break-in on locked crates.
	ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
		local crate = prompt.Parent
		if crate and crate:GetAttribute("Locked") == true then
			local s = getState(player)
			s.holdStart = os.clock()
			s.holdCrate = crate
		end
	end)
	ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt, player)
		local s = getState(player)
		if s.holdCrate == prompt.Parent then
			-- Triggered fires before HoldEnded, so keep the timing a moment for OpenCrate.
			task.delay(0.2, function()
				if s.holdCrate == prompt.Parent then
					s.holdStart = nil
					s.holdCrate = nil
				end
			end)
		end
	end)
end

return ResourceService
