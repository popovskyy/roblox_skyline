--!strict
-- Lobby lifts. Standing inside a lift's zone joins it; walking out leaves it. The first player in is the leader
-- and must pick a party size (1–6, solo allowed) before the countdown starts. When the countdown ends the
-- server reserves a private tower server, stores the party in MemoryStore and teleports everyone together.

local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local PlacesConfig = require(ReplicatedStorage.Shared.PlacesConfig)

local LiftService = {}

type LiftDef = { id: string, countdown: number, fullCountdown: number }

type Lift = {
	def: LiftDef,
	zone: BasePart,
	statusLabel: TextLabel,
	members: { Player }, -- join order; members[1] is the leader
	capacity: number?, -- set by the leader via ChooseLiftSize
	deadline: number?,
	launching: boolean,
	blocked: { [Player]: boolean }, -- after a failed start: must step out before rejoining
	leaderPickToast: { [Player]: boolean }, -- once-per-stay “leader is picking” toast
	pendingLeader: Player?, -- inside the empty lift, waiting to pick a size
}

type Notify = (player: Player, message: any, kind: string?) -> ()

local lifts: { Lift } = {}
local notify: Notify = function(_player, _message, _kind) end
local TICK = 0.25
local chooseRemote: RemoteEvent? = nil
local openPickRemote: RemoteEvent? = nil

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

local function clearPickPrompt(player: Player)
	player:SetAttribute("LiftPickOpen", nil)
	player:SetAttribute("LiftPickId", nil)
end

local function clearRider(player: Player)
	player:SetAttribute("LiftSeconds", nil)
	player:SetAttribute("LiftCount", nil)
	player:SetAttribute("LiftCapacity", nil)
	clearPickPrompt(player)
end

local function updateStatus(lift: Lift)
	local count = #lift.members
	local capacity = lift.capacity
	if capacity then
		lift.statusLabel.Text = ("%d / %d"):format(count, capacity)
	else
		lift.statusLabel.Text = "—"
	end
	local seconds = if lift.deadline then math.max(0, math.ceil(lift.deadline - os.clock())) else nil
	for _, player in lift.members do
		player:SetAttribute("LiftSeconds", if lift.launching then 0 else seconds)
		player:SetAttribute("LiftCount", count)
		player:SetAttribute("LiftCapacity", capacity)
	end
	if lift.pendingLeader and lift.pendingLeader.Parent == Players then
		lift.pendingLeader:SetAttribute("LiftPickOpen", true)
		lift.pendingLeader:SetAttribute("LiftPickId", lift.def.id)
	end
end

local function clearPending(lift: Lift)
	local pending = lift.pendingLeader
	lift.pendingLeader = nil
	if pending and pending.Parent == Players and not liftOf(pending) then
		clearPickPrompt(pending)
	end
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
		lift.capacity = nil
	end
	updateStatus(lift)
end

local function addMember(lift: Lift, player: Player)
	table.insert(lift.members, player)
	clearPickPrompt(player)
	local capacity = lift.capacity
	local now = os.clock()
	if #lift.members == 1 and capacity then
		lift.deadline = now + lift.def.countdown
	end
	if capacity and #lift.members >= capacity and lift.deadline then
		lift.deadline = math.min(lift.deadline, now + lift.def.fullCountdown)
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
		lift.capacity = nil
		clearPending(lift)
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
		lift.capacity = nil
		clearPending(lift)
		updateStatus(lift)
	end)
end

local function beginPick(lift: Lift, player: Player)
	if lift.pendingLeader and lift.pendingLeader ~= player then
		return
	end
	lift.pendingLeader = player
	-- Attribute for clients that poll it; remote so the modal opens even if AttributeChanged is missed.
	player:SetAttribute("LiftPickOpen", true)
	player:SetAttribute("LiftPickId", lift.def.id)
	if openPickRemote then
		openPickRemote:FireClient(player, lift.def.id)
	end
	notify(player, "lobby.pickSizeHint", "info")
	updateStatus(lift)
end

function LiftService.ChooseSize(player: Player, size: any)
	if type(size) ~= "number" or size ~= size or size % 1 ~= 0 then
		return
	end
	local minSize = PlacesConfig.MinPartySize
	local maxSize = PlacesConfig.MaxPartySize
	if size < minSize or size > maxSize then
		notify(player, "lobby.badSize", "warning")
		return
	end
	local liftId = player:GetAttribute("LiftPickId")
	if type(liftId) ~= "string" then
		return
	end
	local lift: Lift? = nil
	for _, candidate in lifts do
		if candidate.def.id == liftId then
			lift = candidate
			break
		end
	end
	if not lift or lift.launching or lift.capacity ~= nil then
		return
	end
	if lift.pendingLeader ~= player then
		return
	end
	local root = rootOf(player)
	if not root or not isInside(lift.zone, root.Position) then
		clearPending(lift)
		clearPickPrompt(player)
		return
	end
	lift.capacity = size
	lift.pendingLeader = nil
	clearPickPrompt(player)
	addMember(lift, player)
	notify(player, { "lobby.sizeChosen", size }, "success")
	-- Solo (1): leave almost immediately after pick so a lone player is not stuck waiting 20s.
	if size == 1 and lift.deadline then
		lift.deadline = math.min(lift.deadline, os.clock() + lift.def.fullCountdown)
		updateStatus(lift)
	end
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
			-- Pending leader left before picking a size.
			if lift.pendingLeader then
				local pending = lift.pendingLeader
				local root = rootOf(pending)
				if pending.Parent ~= Players or not root or not isInside(lift.zone, root.Position) then
					clearPending(lift)
					if pending.Parent == Players then
						clearPickPrompt(pending)
						notify(pending, "lobby.left", "info")
					end
				end
			end
			-- Join / start size pick.
			for _, player in Players:GetPlayers() do
				local root = rootOf(player)
				local inside = root ~= nil and isInside(lift.zone, root.Position)
				if not inside then
					lift.blocked[player] = nil
					lift.leaderPickToast[player] = nil
				elseif not liftOf(player) then
					if lift.capacity == nil then
						if lift.pendingLeader == nil then
							beginPick(lift, player)
						elseif lift.pendingLeader ~= player and not lift.leaderPickToast[player] then
							-- Second rider while leader still picking: soft feedback, no second modal.
							-- Do NOT set blocked — that would prevent join after capacity is chosen.
							notify(player, "lobby.leaderPicking", "info")
							lift.leaderPickToast[player] = true
						end
					elseif not lift.blocked[player] then
						if #lift.members < (lift.capacity :: number) then
							addMember(lift, player)
						else
							notify(player, "lobby.full", "warning")
							lift.blocked[player] = true
						end
					end
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

-- zones[id] = { zone = part, statusLabel = label } from LobbyWorld.
function LiftService.Start(zones: { [string]: { zone: BasePart, statusLabel: TextLabel } }, notifyFn: Notify)
	notify = notifyFn
	for _, def in PlacesConfig.Lifts do
		local refs = zones[def.id]
		if refs then
			local lift: Lift = {
				def = def,
				zone = refs.zone,
				statusLabel = refs.statusLabel,
				members = {},
				capacity = nil,
				deadline = nil,
				launching = false,
				blocked = {},
				leaderPickToast = {},
				pendingLeader = nil,
			}
			table.insert(lifts, lift)
			updateStatus(lift)
		end
	end

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local existing = remotes:FindFirstChild("ChooseLiftSize")
		if existing and existing:IsA("RemoteEvent") then
			chooseRemote = existing
		else
			local remote = Instance.new("RemoteEvent")
			remote.Name = "ChooseLiftSize"
			remote.Parent = remotes
			chooseRemote = remote
		end
		local openExisting = remotes:FindFirstChild("OpenLiftSizePick")
		if openExisting and openExisting:IsA("RemoteEvent") then
			openPickRemote = openExisting
		else
			local openRemote = Instance.new("RemoteEvent")
			openRemote.Name = "OpenLiftSizePick"
			openRemote.Parent = remotes
			openPickRemote = openRemote
		end
		(chooseRemote :: RemoteEvent).OnServerEvent:Connect(function(player, size)
			LiftService.ChooseSize(player, size)
		end)
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
			if l.pendingLeader == player then
				clearPending(l)
			end
		end
		clearRider(player)
	end)
end

return LiftService
