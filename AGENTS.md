# Skyline Zero — guide for coding agents (Cursor, Claude Code, others)

Read this whole file before changing anything. It is short on purpose; every rule here was learned by
breaking the live game once.

## The game in one paragraph

Roblox co-op survival on a skyscraper roof in a ruined, overgrown city (The Last of Us / Days Gone look).
Players start on the safe roof, go down 4 floors for resources, food and loot crates, avoid zombies and
toxic air, bring things back and build Chest → Generator → Air filter / Bridge, then cross the bridge to win.
Every match starts from zero; only tokens, lifetime stats and the lobby leaderboard are saved.
Players speak Ukrainian first (also Russian and English); all player text is translated.

## Places

| Place | Id | Rojo project | Source |
|---|---|---|---|
| Lobby (start place) | 128619231370772 | `lobby.project.json` | `src/Lobby`, plus shared files listed in the project |
| Tower (the match) | 104145307601846 | `default.project.json` | `src/ReplicatedStorage`, `src/ServerScriptService`, `src/StarterPlayer` |

Universe 10771270901. **This repository is the only source of truth.** Never extract code from a `.rbxlx`
or a published place and build on that: an old export once became a second codebase and overwrote weeks
of work when it was published.

## Code map

- `src/ReplicatedStorage/Shared/` — config and data shared by server and client:
  `GameConfig` (all tuning numbers), `ItemDefinitions`, `UpgradeDefinitions`, `Locale` (every player-facing
  string, uk/ru/en), `PlacesConfig` (place ids, `Build` tag), `Theme` (fonts and HUD colour tokens),
  `SoundConfig`, `MusicConfig`, `MetaProgress` (DataStore for tokens), `RemoteNames`.
- `src/ServerScriptService/` — `ServerMain` (init/start order), `WorldBuilder` (the whole tower is built
  from code at server start), `Ruins`, `Scenery`, `Atmosphere`, `PropLibrary` (Blender models loaded with
  InsertService), and `Services/*`, one service per system (Inventory, Resource, Combat, Zombie, Damage,
  Hazard, Match, MatchStats, Tutorial, Interaction, Storage, BaseUpgrade, Party, Craft, Sfx, ...).
- `src/StarterPlayer/StarterPlayerScripts/` — `ClientMain` starts the client controllers in
  `Controllers/*` (HUD, Vitals, Inventory, Combat, Interaction, LootFx, Results, Menu, GamepadHints, ...).
  Clients only draw and send requests; **the server decides everything** (damage, loot, inventory).
- `src/Lobby/` — lobby server (lifts, leaderboard, world) and client.
- `blender/*.py` — headless Blender scripts for props and weapons. `scripts/` — publishing, model upload,
  animation build/upload, icon render.

Patterns to follow:
- New player text → add a key to `Locale.luau` in uk, ru and en. The server sends keys (or
  `{key, args}`), the client renders with `Lang.T`. Never hard-code a visible string.
- New remote → add its name to `RemoteNames.luau`; `Net` creates it. Validate everything server-side and
  rate-limit with `RateLimiter`.
- Live per-player values for the HUD go out as player attributes (`Hunger`, `Downed`, `Equipped`, ...);
  bigger state goes through `StateSyncService` snapshots (`ClientState` on the client).
- Tuning numbers go in `GameConfig`, not inline.

## Build, check, publish

```bash
stylua src && selene src          # must end with 0 errors, 0 warnings
grep -rn "end)(" src              # must print nothing (see pitfall 1)
bash scripts/publish.sh           # builds both places with Rojo and publishes them via Open Cloud
bash scripts/publish.sh tower     # only one place
```

- Bump `PlacesConfig.Build` (e.g. `"b24 · 17.10 12:00"`) before every publish; the lobby shows it so the
  owner can tell which build is live.
- The Open Cloud API key lives in `.roblox_api_key` (git-ignored). **Never print it, commit it, paste it
  in chat or copy it elsewhere.** `rojo upload` does not work with this key; `scripts/publish.sh` posts the
  built place with curl.
- **Only one agent publishes at a time**, and only from this repository's current `main`. Publishing
  replaces the live game for every player.
- Nobody can run the game headless here (no Luau-execution scope). The owner tests on PC, phone, tablet
  and PS5 and reports with screenshots. Read code paths carefully before publishing.
- Teleports and DataStores do not work in Studio; test lifts and tokens in the published game.

## Git

- Work on a branch, keep commits small, write messages in English describing the visible change.
- Run the checks above before every commit. Do not commit built places (`*.rbxl`, `*.rbxlx`, `*.rbxm`
  outputs) or anything secret.

## Pitfalls we already hit (do not repeat)

1. **A statement that starts with `(`** — e.g. `(remotes:FindFirstChild(X) :: RemoteEvent):FireServer()`
   after a line ending in `)` or a value. StyLua silently joins it onto the previous line as a function
   call; selene does not complain. In b15–b18 this crashed `ClientMain`, so pickups, the hotbar and
   attacks all stopped. Always assign to a local first. The `grep "end)("` check above catches it.
2. **Relying on Roblox input events on phones.** `Tool.Activated` and `TouchTapInWorld` did not fire
   reliably next to the touch controls. All attack input (tap, click, R2) goes through
   `CombatController.attackInput`; the held Tool is `ManualActivationOnly`. Keep it that way.
3. **Screens drawn on top of each other.** The downed screen once covered the results screen. Full-screen
   layers have explicit `DisplayOrder`s (`UIKit.Screen` 0, `FullScreen` 1, `TopScreen` 2, results 50);
   the results screen sets the `MatchOver` attribute and the other layers hide.
4. **Glyphs missing from the game fonts** (☰, ✕, ▼, −, emoji) show as empty boxes. Draw shapes with
   Frames or use the uploaded icons.
5. **Hard requires before the world is built.** `WorldBuilder.Build()` creates the spawn platform; if any
   module required before it errors, players spawn in the void and fall forever. Keep `ServerMain`'s order.
6. **Python heredocs with Cyrillic or multi-line Lua strings** broke strings twice. Edit Lua files with a
   real editor.
7. Matching `return Locale` with a naive search once truncated `Locale.luau`. Edit by unique context.
8. Phones: no UI downscaling (`UIKit.IsTouch()` layout instead), text never below 13 px, keep the
   thumbstick (bottom-left) and jump button (bottom-right) areas clear.

## Design references

- `ui/HUD_SPEC.md` style rules live in `Theme.Colors`; HUD layout follows that spec.
- Design reviews and economy notes: the `docs/design/` folder on the Cursor branches of the GitHub repo.
- `HANDOFF.md` has the asset ids (models, icons, animations) and the current to-do list.
