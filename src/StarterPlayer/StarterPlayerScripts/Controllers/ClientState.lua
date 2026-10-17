--!strict
-- Latest state snapshot from the server plus a Changed signal. The client never edits it.

local ClientState = {}

local changed = Instance.new("BindableEvent")
local snapshot: { [string]: any }? = nil

ClientState.Changed = changed.Event

function ClientState.Set(newSnapshot: { [string]: any })
	snapshot = newSnapshot
	changed:Fire(newSnapshot)
end

function ClientState.Get(): { [string]: any }?
	return snapshot
end

return ClientState
