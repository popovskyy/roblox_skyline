--!strict
-- Creates every RemoteEvent on the server and gives services a small API around them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)

local Net = {}

local folder: Folder? = nil
local remotes: { [string]: RemoteEvent } = {}

function Net.Init()
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		existing:Destroy()
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = "Remotes"
	for _, name in RemoteNames do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = newFolder
		remotes[name] = remote
	end
	newFolder.Parent = ReplicatedStorage
	folder = newFolder
end

function Net.Get(name: string): RemoteEvent
	local remote = remotes[name]
	assert(remote, "Unknown remote " .. name)
	return remote
end

export type NotifyKind = "info" | "success" | "warning" | "error"

-- message is a Locale key or { key, args... }; the client renders it in the player's language.
function Net.Notify(player: Player, message: any, kind: NotifyKind?)
	Net.Get(RemoteNames.Notify):FireClient(player, message, kind or "info")
end

function Net.IsReady(): boolean
	return folder ~= nil
end

return Net
