--!strict
-- What each player did this match (deepest floor, chests, zombies, buildings, teammates lifted) and the
-- tokens it is worth. Tokens are paid out once per player per match: on a loss, a win, or leaving early,
-- saved through MetaProgress and shown on the results screen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MetaProgress = require(ReplicatedStorage.Shared.MetaProgress)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local Net = require(script.Parent.Net)

local MatchStatsService = {}

type Stats = {
	floor: number,
	chests: { [string]: number },
	zombies: number,
	builds: number,
	revives: number,
	bestTier: string?,
	paid: boolean,
}

local T = GameConfig.Tokens
local TIER_ORDER = GameConfig.Loot.TierOrder
local stats: { [Player]: Stats } = {}

local function get(player: Player): Stats
	local s = stats[player]
	if not s then
		s = { floor = 0, chests = {}, zombies = 0, builds = 0, revives = 0, paid = false }
		stats[player] = s
	end
	return s
end

function MatchStatsService.ReachedZone(player: Player, zone: string)
	local level = tonumber(string.match(zone, "^Floor0*(%d+)$"))
	if level then
		local s = get(player)
		s.floor = math.max(s.floor, level)
	end
end

function MatchStatsService.OpenedChest(player: Player, tier: string)
	local s = get(player)
	s.chests[tier] = (s.chests[tier] or 0) + 1
	if not s.bestTier or (table.find(TIER_ORDER, tier) or 0) > (table.find(TIER_ORDER, s.bestTier) or 0) then
		s.bestTier = tier
	end
end

function MatchStatsService.KilledZombie(player: Player)
	get(player).zombies += 1
end

function MatchStatsService.Built(player: Player)
	get(player).builds += 1
end

function MatchStatsService.Revived(player: Player)
	get(player).revives += 1
end

-- Everything the results screen shows, plus the tokens earned.
-- Tokens come only from deepest floor (and win ×2). Stats rows with 0 token rates are omitted.
local function summary(s: Stats, won: boolean): { [string]: any }
	local chestCount = 0
	for _, count in s.chests do
		chestCount += count
	end
	local rows = {
		{ key = "results.floor", value = s.floor, tokens = s.floor * T.PerFloor },
	}
	-- Keep non-paying rows only when the player actually did something (display / pride, 0 tokens).
	if
		chestCount > 0
		and (T.Chest.Common or 0) + (T.Chest.Rare or 0) + (T.Chest.Gold or 0) + (T.Chest.Diamond or 0) > 0
	then
		local chestTokens = 0
		for tier, count in s.chests do
			chestTokens += count * (T.Chest[tier] or 0)
		end
		table.insert(rows, { key = "results.chests", value = chestCount, tokens = chestTokens })
	end
	if s.zombies > 0 and T.Zombie > 0 then
		table.insert(rows, { key = "results.zombies", value = s.zombies, tokens = s.zombies * T.Zombie })
	end
	if s.builds > 0 and T.Build > 0 then
		table.insert(rows, { key = "results.builds", value = s.builds, tokens = s.builds * T.Build })
	end
	if s.revives > 0 and T.Revive > 0 then
		table.insert(rows, { key = "results.revives", value = s.revives, tokens = s.revives * T.Revive })
	end
	local total = 0
	for _, row in rows do
		total += row.tokens
	end
	local multiplier = if won then T.WinMultiplier else 1
	return {
		won = won,
		rows = rows,
		multiplier = multiplier,
		tokens = total * multiplier,
		bestTier = s.bestTier,
		chestCount = chestCount,
	}
end

-- Pays the player for this match (once) and shows the results screen. Yields while saving.
function MatchStatsService.Finish(player: Player, won: boolean, show: boolean)
	local s = get(player)
	if s.paid then
		return
	end
	s.paid = true
	local result = summary(s, won)
	if show then
		-- Show the counting right away; the saved total follows when the store answers.
		Net.Get(RemoteNames.ShowResults):FireClient(player, result)
	end
	local meta = MetaProgress.AddMatch(player.UserId, result.tokens, won, s.zombies, result.chestCount, s.floor)
	if show and meta and player.Parent == Players then
		Net.Get(RemoteNames.ShowResults):FireClient(player, { totalTokens = meta.tokens })
	end
end

-- A new match on this server (restart in place).
function MatchStatsService.Reset(player: Player)
	stats[player] = nil
end

function MatchStatsService.Start()
	Players.PlayerRemoving:Connect(function(player)
		-- Leaving early still pays what was earned.
		local s = stats[player]
		if s and not s.paid and (s.floor > 0 or s.zombies > 0 or s.builds > 0) then
			task.spawn(MatchStatsService.Finish, player, false, false)
		end
		task.delay(30, function()
			if player.Parent ~= Players then
				stats[player] = nil
			end
		end)
	end)
end

return MatchStatsService
