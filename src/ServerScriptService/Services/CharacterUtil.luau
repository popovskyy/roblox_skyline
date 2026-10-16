--!strict
-- Small helpers for validating a player's character on the server.

local CharacterUtil = {}

function CharacterUtil.GetRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

function CharacterUtil.GetHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

-- Distance from the character to the closest point of the part's bounding box.
function CharacterUtil.DistanceTo(player: Player, part: BasePart): number
	local root = CharacterUtil.GetRoot(player)
	if not root then
		return math.huge
	end
	local localPos = part.CFrame:PointToObjectSpace(root.Position)
	local half = part.Size / 2
	local clamped = Vector3.new(
		math.clamp(localPos.X, -half.X, half.X),
		math.clamp(localPos.Y, -half.Y, half.Y),
		math.clamp(localPos.Z, -half.Z, half.Z)
	)
	return (localPos - clamped).Magnitude
end

function CharacterUtil.IsNear(player: Player, part: BasePart, maxDistance: number): boolean
	return CharacterUtil.DistanceTo(player, part) <= maxDistance
end

return CharacterUtil
