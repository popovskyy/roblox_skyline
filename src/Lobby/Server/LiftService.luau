--!strict
-- Lobby lifts. Standing inside a lift's zone joins it; walking out leaves it. The first player in is the leader.
-- A countdown starts with the first player and shortens once the lift is full. When it ends the server
-- reserves a private tower server, stores the party in MemoryStore and teleports everyone together.

local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local PlacesConfig = require(ReplicatedStorage.Shared.PlacesConfig)

local LiftService = {}

type LiftDef = { id: string, capacity: number, countdown: number, choose: boolean? }

type Lift = {
	def: LiftDef,
	capacity: number, -- current size: the default, or what the leader picked
	zone: BasePart,
	statusLabel: TextLabel,
	members: { Player }, -- join order; members[1] is the leader
	deadline: number?,
	launching: boolean,
	blocked: { [Player]: boolean }, -- after a failed start: must step out before rejoining
}

type Notify = (player: Player, message: any, kind: string?) -> ()

local lifts: { Lift } = {}
local notify: Notify = function(_player, _message, _kind) end
local TICK = 0.25

local function isInside(part: BasePart, position: Vector3): boolean
	local p = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function liftOf(player: Player): Lift?
	for _, lift in lifts do
		if table.find(lift.members, player) then
			return lift
		end
	end
	return nil
end

-- Riders get the countdown as player attributes (LiftSeconds, LiftCount, LiftCapacity) for their own screen.
local function updateStatus(lift: Lift)
	local count = #lift.members
	-- Over the cabin: "SOLO" or "GROUP · 2/4" (localized on each client from the attributes).
	lift.statusLabel:SetAttribute("LiftCount", count)
	lift.statusLabel:SetAttribute("LiftCapacity", lift.capacity)
	lift.statusLabel:SetAttribute("LiftSolo", lift.def.capacity == 1)
	local seconds = if lift.deadline then math.max(0, math.ceil(lift.deadline - os.clock())) else nil
	for _, player in lift.members do
		player:SetAttribute("LiftSeconds", if lift.launching then 0 else seconds)
		player:SetAttribute("LiftCount", count)
		player:SetAttribute("LiftCapacity", lift.capacity)
		-- Only the leader of a group lift picks the party size.
		player:SetAttribute("LiftCanChoose", lift.def.choose == true and lift.members[1] == player)
		player:SetAttribute("LiftTotal", lift.def.countdown)
	end
end

local function clearRider(player: Player)
	player:SetAttribute("LiftSeconds", nil)
	player:SetAttribute("LiftCount", nil)
	player:SetAttribute("LiftCapacity", nil)
	player:SetAttribute("LiftTotal", nil)
	player:SetAttribute("LiftCanChoose", nil)
end

local function removeMember(lift: Lift, player: Player)
	local index = table.find(lift.members, player)
	if not index then
		return
	end
	table.remove(lift.members, index)
	clearRider(player)
	if #lift.members == 0 then
		lift.deadline = nil
		lift.capacity = lift.def.capacity
	end
	updateStatus(lift)
end

local function addMember(lift: Lift, player: Player)
	table.insert(lift.members, player)
	local now = os.clock()
	if #lift.members == 1 then
		lift.deadline = now + lift.def.countdown
	end
	if #lift.members >= lift.capacity and lift.deadline then
		-- Full lift: no reason to keep everyone waiting, run the remaining time three times faster.
		lift.deadline = now + math.max(0, lift.deadline - now) / PlacesConfig.FullLiftSpeedup
	end
	updateStatus(lift)
end

local function withRetries(fn: () -> any): (boolean, any)
	local lastError = nil
	for attempt = 1, PlacesConfig.TeleportRetries do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastError = result
		warn(("[Lift] attempt %d failed: %s"):format(attempt, tostring(result)))
		task.wait(attempt)
	end
	return false, lastError
end

local function launch(lift: Lift)
	local party = table.clone(lift.members)
	lift.launching = true
	lift.deadline = nil

	local function fail(message: string)
		for _, player in party do
			if player.Parent then
				notify(player, message, "warning")
			end
		end
		lift.launching = false
		for _, player in lift.members do
			lift.blocked[player] = true
			clearRider(player)
		end
		table.clear(lift.members)
		updateStatus(lift)
	end

	if PlacesConfig.TowerPlaceId == 0 then
		fail("lobby.notPublished")
		return
	end
	if RunService:IsStudio() then
		fail("lobby.studio")
		return
	end
	for _, player in party do
		notify(player, "lobby.starting", "success")
	end

	local reserved, result = withRetries(function()
		local code, serverId = TeleportService:ReserveServer(PlacesConfig.TowerPlaceId)
		return { code = code, serverId = serverId }
	end)
	if not reserved then
		fail("lobby.failed")
		return
	end
	local accessCode: string = result.code
	local privateServerId: string = result.serverId

	local userIds = {}
	for _, player in party do
		table.insert(userIds, player.UserId)
	end
	local partyMap = MemoryStoreService:GetHashMap(PlacesConfig.PartyMapName)
	local stored = withRetries(function()
		partyMap:SetAsync(privateServerId, {
			leaderUserId = userIds[1],
			partyUserIds = userIds,
		}, PlacesConfig.PartyTtlSeconds)
	end)
	if not stored then
		fail("lobby.failed")
		return
	end

	-- Only players still in the lobby can travel.
	local travellers = {}
	for _, player in party do
		if player.Parent == Players then
			table.insert(travellers, player)
		end
	end
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = accessCode
	-- Carry each rider's language choice over to the tower (cosmetic only, so client-forgeable data is fine).
	local languages = {}
	for _, player in travellers do
		local code = player:GetAttribute("Language")
		if code == "uk" or code == "ru" or code == "en" then
			languages[tostring(player.UserId)] = code
		end
	end
	options:SetTeleportData({ languages = languages })
	local teleported = withRetries(function()
		TeleportService:TeleportAsync(PlacesConfig.TowerPlaceId, travellers, options)
	end)
	if not teleported then
		fail("lobby.failed")
		return
	end
	-- Teleporting players stay in the lift until they disappear, so nobody else can take their slot.
	task.delay(15, function()
		lift.launching = false
		for _, player in lift.members do
			if player.Parent then
				clearRider(player)
			end
		end
		table.clear(lift.members)
		updateStatus(lift)
	end)
end

local function tick()
	local now = os.clock()
	for _, lift in lifts do
		if not lift.launching then
			-- Leave: anyone no longer inside the zone.
			for i = #lift.members, 1, -1 do
				local player = lift.members[i]
				local root = rootOf(player)
				if player.Parent ~= Players or not root or not isInside(lift.zone, root.Position) then
					removeMember(lift, player)
					if player.Parent == Players then
						notify(player, "lobby.left", "info")
					end
				end
			end
			-- Join: anyone inside the zone who is not in a lift yet.
			for _, player in Players:GetPlayers() do
				local root = rootOf(player)
				local inside = root ~= nil and isInside(lift.zone, root.Position)
				if not inside then
					lift.blocked[player] = nil
				elseif not lift.blocked[player] and not liftOf(player) and #lift.members < lift.capacity then
					addMember(lift, player)
				end
			end
			if lift.deadline and now >= lift.deadline and #lift.members > 0 then
				task.spawn(launch, lift)
			else
				updateStatus(lift)
			end
		end
	end
end

-- The leader of a group lift picks how many players it takes (2..6, never fewer than already inside).
function LiftService.SetSize(player: Player, size: any)
	local lift = liftOf(player)
	if not lift or lift.launching or not lift.def.choose or lift.members[1] ~= player then
		return
	end
	if type(size) ~= "number" or not table.find(PlacesConfig.PartySizes, size) or size < #lift.members then
		return
	end
	lift.capacity = size
	if #lift.members >= lift.capacity and lift.deadline then
		local now = os.clock()
		lift.deadline = now + math.max(0, lift.deadline - now) / PlacesConfig.FullLiftSpeedup
	end
	updateStatus(lift)
end

-- "Leave lift" button: out of the party, and not taken back in until the player steps out of the zone.
function LiftService.Leave(player: Player)
	local lift = liftOf(player)
	if lift and not lift.launching then
		removeMember(lift, player)
		lift.blocked[player] = true
		notify(player, "lobby.left", "info")
	end
end

-- zones[id] = { zone = part, statusLabel = label } from LobbyWorld.
function LiftService.Start(zones: { [string]: { zone: BasePart, statusLabel: TextLabel } }, notifyFn: Notify)
	notify = notifyFn
	for _, def in PlacesConfig.Lifts do
		local refs = zones[def.id]
		if refs then
			local lift: Lift = {
				def = def,
				capacity = def.capacity,
				zone = refs.zone,
				statusLabel = refs.statusLabel,
				members = {},
				deadline = nil,
				launching = false,
				blocked = {},
			}
			table.insert(lifts, lift)
			updateStatus(lift)
		end
	end
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator >= TICK then
			accumulator = 0
			tick()
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local lift = liftOf(player)
		if lift then
			removeMember(lift, player)
		end
		for _, l in lifts do
			l.blocked[player] = nil
		end
	end)
end

return LiftService
