--!strict
-- Soft-currency tokens (not Robux). Earn: kill 1–2, floor clear 10+2×floor (cap +25), roof +25 once.
-- Session-scoped while PersistProgress is false; mirrored onto PlayerData.tokens for snapshot/HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateSyncService = require(script.Parent.StateSyncService)

local TokenService = {}

local roofBonusClaimed: { [Player]: boolean } = {}
local floorClearClaimed: { [number]: boolean } = {}

local function cfg()
	return GameConfig.Tokens
end

function TokenService.Get(player: Player): number
	local data = PlayerDataService.Get(player)
	return data and (data.tokens or 0) or 0
end

function TokenService.Add(player: Player, amount: number, reason: string?)
	if amount <= 0 then
		return
	end
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end
	data.tokens = (data.tokens or 0) + amount
	PlayerDataService.MarkDirty(player)
	StateSyncService.Request(player)
	if reason then
		Net.Notify(player, { "tokens.earned", amount, { ref = reason } }, "success")
	end
end

function TokenService.OnZombieKill(killer: Player?)
	if not killer then
		return
	end
	local amount = math.random(cfg().KillMin, cfg().KillMax)
	TokenService.Add(killer, amount, "tokens.reason.kill")
end

function TokenService.OnFloorCleared(level: number)
	if floorClearClaimed[level] then
		return
	end
	floorClearClaimed[level] = true
	local amount = math.min(cfg().FloorClearCap, cfg().FloorClearBase + cfg().FloorClearPerLevel * level)
	for _, player in Players:GetPlayers() do
		TokenService.Add(player, amount, "tokens.reason.clear")
	end
end

function TokenService.OnRoofTouch(player: Player)
	if roofBonusClaimed[player] then
		return
	end
	roofBonusClaimed[player] = true
	TokenService.Add(player, cfg().RoofBonus, "tokens.reason.roof")
end

function TokenService.Init()
	StateSyncService.RegisterProvider(function(player, snapshot)
		snapshot.tokens = TokenService.Get(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		roofBonusClaimed[player] = nil
	end)
end

return TokenService
