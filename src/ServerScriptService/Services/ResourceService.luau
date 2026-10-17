--!strict
-- Resource nodes and rubble. Node state is kept per player, so co-op players never take each other's loot.
-- Resources are handed out only after every server check passes.
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
	depleted: { [string]: boolean }, -- normal nodes, refilled on roof return
	opened: { [string]: boolean }, -- loot crates, opened once per match
	seenGold: boolean, -- opened a gold or diamond crate this match (bad-luck protection)
	holdStart: number?, -- when the player started holding a locked crate's prompt
	holdCrate: Instance?,
}

local state: { [Player]: PlayerNodes } = {}
-- Rubble is shared: once anyone clears a pile it is gone for the whole team.
local clearedRubble: { [string]: boolean } = {}
-- One-shot toast: Scrap (металобрухт) ≠ Crowbar (лом).
local scrapHinted: { [Player]: boolean } = {}

local function getState(player: Player): PlayerNodes
	local s = state[player]
	if not s then
		s = { depleted = {}, opened = {}, seenGold = false }
		state[player] = s
	end
	return s
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
	if node:GetAttribute("Unique") == true then
		local data = PlayerDataService.Get(player)
		return data ~= nil and data.uniqueNodesTaken[nodeId] == true
	end
	return getState(player).depleted[nodeId] == true
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

	if unique then
		data.uniqueNodesTaken[nodeId] = true
		PlayerDataService.MarkDirty(player)
	else
		getState(player).depleted[nodeId] = true
	end
	InventoryService.Add(player, id, count)
	SfxService.Play("Pickup", node.Position, 0.8)
	StateSyncService.Request(player)
	Net.Notify(player, { "res.collected", Locale.Item(id), count }, "success")
	if id == "Scrap" and not scrapHinted[player] then
		scrapHinted[player] = true
		Net.Notify(player, "hint.scrapNotCrowbar", "info")
	end
	return true, nil
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
	SfxService.Play("Rubble", rubble.Position)
	local reward = rubble:GetAttribute("RewardItem")
	if ItemDefinitions.IsValid(reward) and InventoryService.GetCount(player, reward :: string) == 0 then
		-- The reward is a tool the player needs, so it ignores the weight limit.
		InventoryService.ForceAdd(player, reward :: string, 1)
		Net.Notify(player, { "rubble.found", Locale.Item(reward :: string) }, "success")
	else
		Net.Notify(player, "rubble.cleared", "success")
	end
	-- Everyone's world updates: the pile disappears for all players.
	for _, other in Players:GetPlayers() do
		StateSyncService.Request(other)
	end
	return true, nil
end

-- Loot crates: rolled when opened, refilled on roof return like resource nodes.
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
	if s.opened[nodeId] then
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
	s.opened[nodeId] = true
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
	elseif useKey then
		Net.Notify(player, "loot.keyUsed", "info")
	end
	for id, amount in loot do
		InventoryService.ForceAdd(player, id, amount)
	end
	StateSyncService.Request(player)
	-- Everyone sees the burst; only the opener gets the items flying out. Gold and diamond get a banner.
	Net.Get(RemoteNames.LootOpened):FireAllClients(crate, tier, final, player.UserId, player.DisplayName, loot)
	return true, nil
end

-- A fresh match on this server: every node, crate and rubble pile is back.
function ResourceService.ResetMatch(player: Player)
	state[player] = nil
	table.clear(clearedRubble)
	StateSyncService.Request(player)
end

-- Called when the player comes back up to the roof (crates stay opened).
function ResourceService.OnReturnedToRoof(player: Player)
	if not GameConfig.ResetNodesOnRoofReturn then
		return
	end
	local s = getState(player)
	if next(s.depleted) then
		table.clear(s.depleted)
		StateSyncService.Request(player)
	end
end

function ResourceService.Init()
	StateSyncService.RegisterProvider(function(player, snapshot)
		local s = getState(player)
		local data = PlayerDataService.Get(player)
		local depleted = table.clone(s.depleted)
		for nodeId in s.opened do
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
