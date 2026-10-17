--!strict
-- Zombies roam the four floors below the roof (the roof itself is always safe).
-- Server-owned NPCs: they chase the nearest standing player on their floor, hit in melee through
-- DamageService. A killed zombie does not come back this match.

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local SfxService = require(script.Parent.SfxService)
local CharacterUtil = require(script.Parent.CharacterUtil)
local DamageService = require(script.Parent.DamageService)

local ZombieService = {}

local Z = GameConfig.Zombie
local World = GameConfig.World
local WALK_ANIM = "rbxassetid://507777826"
local IDLE_ANIM = "rbxassetid://507766666"
local TICK = 0.3

type Zombie = {
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	level: number, -- 0 = roof (horde only); 1..4 = floors
	home: Vector3,
	lastAttack: number,
	lastPath: number,
	waypoints: { PathWaypoint },
	waypointIndex: number,
	wanderAt: number,
	walkTrack: AnimationTrack?,
	idleTrack: AnimationTrack?,
	alertPos: Vector3?, -- a noise to investigate until alertUntil
	alertUntil: number,
	-- Studs of Y drift allowed before snap-back. Floor zombies stay ~14; horde may climb the last flight.
	maxDrift: number,
}

local zombies: { Zombie } = {}
local folder: Folder? = nil
local spawnPoints: { [number]: { Vector3 } } = {}

-- Open spots on each floor, away from the stairwell and the rubble rooms (x, z).
local SPAWNS: { [number]: { Vector2 } } = {
	[1] = { Vector2.new(0, 28), Vector2.new(-28, 15), Vector2.new(26, -5), Vector2.new(-6, -28) },
	[2] = { Vector2.new(8, 24), Vector2.new(-26, -8), Vector2.new(30, -4), Vector2.new(-6, -32) },
	[3] = { Vector2.new(-26, -6), Vector2.new(-16, 24), Vector2.new(22, -12), Vector2.new(24, 18) },
	[4] = { Vector2.new(-28, 17), Vector2.new(14, -26), Vector2.new(26, 8), Vector2.new(-10, 26), Vector2.new(4, -28) },
}

local function floorY(level: number): number
	return World.RoofY - level * World.FloorSpacing
end

local function zombieDescription(): HumanoidDescription
	local desc = Instance.new("HumanoidDescription")
	local skin = Color3.fromRGB(118, 138, 96):Lerp(Color3.fromRGB(150, 150, 120), math.random())
	desc.HeadColor = skin
	desc.LeftArmColor = skin
	desc.RightArmColor = skin
	desc.LeftLegColor = Color3.fromRGB(70, 60, 50)
	desc.RightLegColor = Color3.fromRGB(70, 60, 50)
	desc.TorsoColor = Color3.fromRGB(90, 80, 70):Lerp(Color3.fromRGB(60, 70, 80), math.random())
	return desc
end

local function playAnimations(z: Zombie)
	local animator = z.humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = z.humanoid
	end
	local function load(id: string): AnimationTrack?
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local ok, track = pcall(function()
			return (animator :: Animator):LoadAnimation(animation)
		end)
		return if ok then track else nil
	end
	z.walkTrack = load(WALK_ANIM)
	z.idleTrack = load(IDLE_ANIM)
	if z.idleTrack then
		z.idleTrack.Looped = true
		z.idleTrack:Play()
	end
	if z.walkTrack then
		z.walkTrack.Looped = true
	end
	z.humanoid.Running:Connect(function(speed)
		if not z.walkTrack then
			return
		end
		if speed > 1 and not z.walkTrack.IsPlaying then
			z.walkTrack:Play(0.2, 1, 0.8) -- a slow, dragging walk
		elseif speed <= 1 and z.walkTrack.IsPlaying then
			z.walkTrack:Stop(0.2)
		end
	end)
end

local function createZombie(level: number, spawnAt: Vector3, home: Vector3, maxDrift: number)
	if not folder then
		return
	end
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(zombieDescription(), Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		warn("[Zombie] could not create a zombie:", model)
		return
	end
	model.Name = "Zombie"
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	humanoid.MaxHealth = Z.MaxHealth
	humanoid.Health = Z.MaxHealth
	humanoid.WalkSpeed = Z.WalkSpeed
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.HealthDisplayDistance = 30
	humanoid.NameDisplayDistance = 0
	model:SetAttribute("Zombie", true)
	if level == 0 then
		model:SetAttribute("Horde", true)
	end
	model:PivotTo(CFrame.new(spawnAt))
	model.Parent = folder
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d:SetNetworkOwner(nil)
		end
	end

	local z: Zombie = {
		model = model,
		humanoid = humanoid,
		root = root,
		level = level,
		home = home,
		lastAttack = 0,
		lastPath = 0,
		waypoints = {},
		waypointIndex = 0,
		wanderAt = 0,
		alertUntil = 0,
		maxDrift = maxDrift,
	}
	table.insert(zombies, z)
	playAnimations(z)

	humanoid.Died:Once(function()
		local index = table.find(zombies, z)
		if index then
			table.remove(zombies, index)
		end
		task.delay(3, function()
			model:Destroy()
		end)
		-- No respawn: a cleared floor stays cleared for the rest of the match.
	end)
end

local spawnZombie: (level: number) -> ()

spawnZombie = function(level: number)
	local points = spawnPoints[level]
	if not points or not folder then
		return
	end
	-- The spot farthest from every player and every other zombie, so nobody pops up in someone's face.
	local home = points[1]
	local bestScore = -math.huge
	for _, point in points do
		local nearest = math.huge
		for _, player in Players:GetPlayers() do
			local root = CharacterUtil.GetRoot(player)
			if root then
				nearest = math.min(nearest, (root.Position - point).Magnitude)
			end
		end
		for _, other in zombies do
			nearest = math.min(nearest, (other.root.Position - point).Magnitude * 1.5)
		end
		local score = nearest + math.random() * 4
		if score > bestScore then
			home, bestScore = point, score
		end
	end
	createZombie(level, home, home, 14)
end

-- Roof horde: spawn on / just below the stair exit, chase anyone on the roof. Never respawns floor packs.
function ZombieService.SpawnHordeZombie(spawnAt: Vector3, home: Vector3)
	createZombie(0, spawnAt, home, 28)
end

-- Nearest standing player on the same floor within aggro range.
local function findTarget(z: Zombie): (Player?, BasePart?)
	local best: Player? = nil
	local bestRoot: BasePart? = nil
	local bestDistance = Z.AggroRange
	local y = floorY(z.level)
	for _, player in Players:GetPlayers() do
		local root = CharacterUtil.GetRoot(player)
		if root and not DamageService.IsDowned(player) and math.abs(root.Position.Y - (y + 3)) < 9 then
			local distance = (root.Position - z.root.Position).Magnitude
			if distance < bestDistance then
				best, bestRoot, bestDistance = player, root, distance
			end
		end
	end
	return best, bestRoot
end

local function isBarricadeBlock(part: Instance?): boolean
	return part ~= nil and part:IsA("BasePart") and part:GetAttribute("BarricadeBlock") == true and part.CanCollide
end

-- Ray from A to B hits a built barricade segment (server collision on).
local function rayHitsBarricade(from: Vector3, to: Vector3, ignore: { Instance }): BasePart?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local result = workspace:Raycast(from, to - from, params)
	if result and isBarricadeBlock(result.Instance) then
		return result.Instance
	end
	return nil
end

local function hasLineOfSight(z: Zombie, target: BasePart): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { z.model, target.Parent :: Instance }
	local from = z.root.Position
	local result = workspace:Raycast(from, target.Position - from, params)
	if result == nil then
		return true
	end
	-- Built boards count as a hard block even if a thin gap would otherwise look clear.
	return not isBarricadeBlock(result.Instance)
end

local function stopInPlace(z: Zombie)
	z.humanoid:MoveTo(z.root.Position)
	z.waypoints = {}
	z.waypointIndex = 0
end

local function moveAlongPath(z: Zombie, goal: Vector3, now: number)
	-- Never soft-clip through boards: if the goal is on the other side, stop (or attack in place).
	if rayHitsBarricade(z.root.Position, goal, { z.model }) then
		stopInPlace(z)
		return
	end
	if now - z.lastPath > 1.5 or z.waypointIndex > #z.waypoints then
		z.lastPath = now
		local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = false })
		local ok = pcall(function()
			path:ComputeAsync(z.root.Position, goal)
		end)
		if ok and path.Status == Enum.PathStatus.Success then
			z.waypoints = path:GetWaypoints()
			z.waypointIndex = 2
		else
			z.waypoints = {}
			z.waypointIndex = 0
		end
	end
	local waypoint = z.waypoints[z.waypointIndex]
	if waypoint then
		if rayHitsBarricade(z.root.Position, waypoint.Position, { z.model }) then
			stopInPlace(z)
			return
		end
		z.humanoid:MoveTo(waypoint.Position)
		if (waypoint.Position - z.root.Position).Magnitude < 4 then
			z.waypointIndex += 1
		end
	else
		-- Path failed: do not fall back to naked MoveTo(goal) through a barricade.
		if rayHitsBarricade(z.root.Position, goal, { z.model }) then
			stopInPlace(z)
		else
			z.humanoid:MoveTo(goal)
		end
	end
end

local function think(z: Zombie, now: number)
	if z.humanoid.Health <= 0 then
		return
	end
	-- Keep floor zombies on their floor; horde (level 0) may climb the last flight onto the roof.
	if math.abs(z.root.Position.Y - (floorY(z.level) + 3)) > z.maxDrift then
		z.model:PivotTo(CFrame.new(z.home))
		return
	end
	local target, targetRoot = findTarget(z)
	-- The occasional groan, more often while chasing someone.
	if math.random() < (if target then 0.04 else 0.012) then
		SfxService.Play("ZombieGroan", z.root, 0.8)
	end
	if target and targetRoot then
		local distance = (targetRoot.Position - z.root.Position).Magnitude
		local ignore: { Instance } = { z.model }
		local character = target.Character
		if character then
			table.insert(ignore, character)
		end
		local blocked = rayHitsBarricade(z.root.Position, targetRoot.Position, ignore)
		if distance <= Z.AttackRange and not blocked then
			z.humanoid:MoveTo(z.root.Position)
			if now - z.lastAttack >= Z.AttackCooldown then
				z.lastAttack = now
				SfxService.Play("ZombieAttack", z.root, 0.9)
				DamageService.Damage(target, Z.Damage)
			end
		elseif blocked then
			-- Goal is behind boards: idle / press against the wall; never LoS-MoveTo through it.
			stopInPlace(z)
		elseif hasLineOfSight(z, targetRoot) then
			z.humanoid:MoveTo(targetRoot.Position)
		else
			moveAlongPath(z, targetRoot.Position, now)
		end
		return
	end
	-- A noise nearby (crowbar break-in): go and look.
	if z.alertPos and now < z.alertUntil then
		if (z.alertPos - z.root.Position).Magnitude > 4 then
			moveAlongPath(z, z.alertPos, now)
		end
		return
	end
	-- Nobody around: shuffle near home (still never through boards).
	if now >= z.wanderAt then
		z.wanderAt = now + math.random(4, 9)
		local offset = Vector3.new(math.random(-12, 12), 0, math.random(-12, 12))
		local wanderGoal = z.home + offset
		if rayHitsBarricade(z.root.Position, wanderGoal, { z.model }) then
			stopInPlace(z)
		else
			z.humanoid:MoveTo(wanderGoal)
		end
	end
end

function ZombieService.GetZombieAt(part: Instance): (Humanoid?, BasePart?)
	local model = part:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("Zombie") then
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
		if humanoid and root and root:IsA("BasePart") then
			return humanoid, root
		end
	end
	return nil, nil
end

-- A loud noise: zombies on the same floor within radius come to check it out.
function ZombieService.Alert(position: Vector3, radius: number, seconds: number)
	local now = os.clock()
	for _, z in zombies do
		local offset = z.root.Position - position
		if math.abs(offset.Y) < 9 and offset.Magnitude <= radius then
			z.alertPos = position
			z.alertUntil = now + seconds
		end
	end
end

-- Every living zombie: { humanoid, root }.
function ZombieService.All(): { Zombie }
	return zombies
end

function ZombieService.Start(root: Folder)
	local zombieFolder = Instance.new("Folder")
	zombieFolder.Name = "Zombies"
	zombieFolder.Parent = root
	folder = zombieFolder
	for level, points in SPAWNS do
		local list = {}
		for _, p in points do
			table.insert(list, Vector3.new(p.X, floorY(level) + 3, p.Y))
		end
		spawnPoints[level] = list
	end
	for level, count in Z.PerFloor do
		for _ = 1, count do
			task.spawn(spawnZombie, level)
		end
	end

	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < TICK then
			return
		end
		accumulator = 0
		local now = os.clock()
		for _, z in table.clone(zombies) do
			task.spawn(think, z, now)
		end
	end)
end

return ZombieService
