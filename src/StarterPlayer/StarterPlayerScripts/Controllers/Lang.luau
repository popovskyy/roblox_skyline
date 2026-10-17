--!strict
-- Client-side translation helpers. Static labels register with Lang.Bind and refresh on a language change;
-- everything else re-renders from the state snapshot (Lang.Changed re-fires it).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)

local Lang = {}

local player = Players.LocalPlayer
local changed = Instance.new("BindableEvent")
Lang.Changed = changed.Event

type Binding = { key: string, args: { any } }
local bindings: { [Instance]: Binding } = {}

function Lang.Get(): Locale.Lang
	return Locale.ForPlayer(player)
end

function Lang.T(key: string, ...: any): string
	return Locale.T(Lang.Get(), key, ...)
end

function Lang.ItemWithRarity(itemId: string): string
	return Locale.ItemWithRarity(Lang.Get(), itemId)
end

function Lang.Format(message: any): string
	return Locale.Format(Lang.Get(), message)
end

-- Keeps a TextLabel / TextButton translated: Text = T(key, ...), now and after every language change.
function Lang.Bind(instance: Instance, key: string, ...: any)
	local target: any = instance
	target.Text = Lang.T(key, ...)
	bindings[instance] = { key = key, args = { ... } }
	instance.Destroying:Once(function()
		bindings[instance] = nil
	end)
end

local last = Lang.Get()
-- Changing the language in the Roblox menu updates LocaleId; redraw everything when it does.
player:GetPropertyChangedSignal("LocaleId"):Connect(function()
	local now = Lang.Get()
	if now == last then
		return
	end
	last = now
	for instance, binding in bindings do
		local target: any = instance
		target.Text = Lang.T(binding.key, table.unpack(binding.args))
	end
	changed:Fire(now)
end)

return Lang
