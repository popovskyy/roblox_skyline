--!strict
-- Per-player, per-action cooldowns that protect remotes and prompts from spam.

local Players = game:GetService("Players")

local RateLimiter = {}

local lastUse: { [Player]: { [string]: number } } = {}

-- Returns true and records the call when the action is allowed now.
function RateLimiter.Allow(player: Player, action: string, cooldown: number): boolean
	local now = os.clock()
	local perPlayer = lastUse[player]
	if not perPlayer then
		perPlayer = {}
		lastUse[player] = perPlayer
	end
	local last = perPlayer[action]
	if last and now - last < cooldown then
		return false
	end
	perPlayer[action] = now
	return true
end

Players.PlayerRemoving:Connect(function(player)
	lastUse[player] = nil
end)

return RateLimiter
