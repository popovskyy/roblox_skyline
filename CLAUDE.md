# SkylineZero — Claude Code handoff

Co-op post-apoc Roblox tower (Ukrainian-primary, RU/EN locale). Places: Lobby + Tower in one universe. Canonical GitHub: [popovskyy/roblox_skyline](https://github.com/popovskyy/roblox_skyline).

**North star:** addictive first minutes without rage — teach by doing, one objective, soft currency that matters, Robux that helps survival without skipping the game.

---

## What this package is

Context for Claude Code on the owner’s PC to evaluate:

1. **Economy design** (tokens + Robux) — see `docs/design/economy-robux.md` + loops/UX siblings.
2. **Agent team we ran in Cursor** — roles under `.claude/agents/`; coordinator-driven multi-agent workflow.

This branch adds handoff docs/agents only. It does **not** claim to be the live Roblox build.

---

## Project layout (repo)

| Path | Role |
|------|------|
| `src/` | Tower Luau (Rojo-style) |
| `src_lobby/` | Lobby Luau |
| `places/*.rbxlx` | Place backups (scripts + procedural world builders) |
| `tools/` | `inject_scripts.py`, `extract_rbxlx.py`, rollback helpers |
| `docs/design/` | Design + review docs copied for this handoff |
| `.claude/agents/` | Claude Code subagents mirroring the Cursor team |

Place IDs (universe `10771270901`):

- Lobby: `128619231370772`
- Tower: `104145307601846`
- Play URL: https://www.roblox.com/games/128619231370772/Skyline-Zero (universe often **PRIVATE**)

---

## What Cursor did (summary)

Multi-agent team under a coordinator:

| Role | Work product |
|------|----------------|
| Coder | Rojo extract, backlog fixes, inject → rbxmk → Open Cloud publish, GitHub via SSH |
| Game designer | Loops, density, chest cliff, craft/tokens gates; hard review `gd-review-pass.md` |
| UX designer | First-session UX, HUD n/m, elevator modal product notes |
| Tester | Gap report, nuance pass, ship gates, live smells (lift sticky modal, etc.) |
| Economist | Tokens nerf table + Robux survival packs (`economy-robux.md`) |
| Marketer | Store copy / visual brief drafts |
| Art / 3D | Atmosphere, anim (ToolSlash), pipeline notes |
| Brainstormer | Retention hooks ranked by impact×effort |

Shipped-then-rolled agent themes (in git history, **not** all live):

- Floor plate **240**, live loot `n/m`, team chest, drop, rubble server-clear, zombie no-reseed
- Atmosphere / WeatherService / TokenService / craft Bandage·Medkit
- Lobby lift modal experiments (1–6, sticky remotes, dimmers) → **broke boarding**
- Must-fix batch (b19) then lift rollback (b20) then overlay (b21)
- Owner reported **spawn in sky / endless fall** on agent builds → emergency restore of **original uploaded places**

---

## What’s live on Roblox NOW

**Original owner upload only** (artifact `b15 · drop-chest-hud-zombies`), converted with rbxmk **with no script injection and no agent edits**:

| Place | Published version |
|-------|-------------------|
| Tower | **v33** |
| Lobby | **v34** |

Source files used: store `artifacts/places/SkylineZero.rbxlx` + `SkylineZero_Lobby.rbxlx`.

Agent builds (b16–b21 overlays/must-fixes) are **not** the live places.

---

## What broke

### 1. Lift / elevator regression

Agent modal work (OpenLiftSizePick remote, high DisplayOrder ScreenGui, Active dimmers, sticky open races, MinPartySize churn) broke **boarding** that worked on the original. Later rollback restored original lift scripts from artifacts; overlay 1–6 was attempted as “UI only” then **stopped** after the fall report. See `docs/design/lift-modal-overlay-proposal.md` and `docs/design/nuance-test-pass.md`.

### 2. Spawn-in-sky / endless fall (agent builds)

RCA: `docs/design/spawn-fall-rca.md` (from Cursor `internal/spawn-fall-rca.md`).

Short version:

- Spawns are **runtime-only** (`WorldBuilder` / `LobbyWorld`); places have no baked `SpawnLocation`.
- World folder is parented to Workspace **only after** full build succeeds.
- Agent `ServerMain` **hard-requires** `TokenService` + `WeatherService` *before* `WorldBuilder.Build()`. Artifact ServerMain does not. A failed require or a WorldBuilder error before `root.Parent` → no spawn platform → void fall / respawn loop.
- FloorSize 240 / RoofSpawn math match the artifact — **not** a simple “spawn off the 240 plate” bug.

Live join and Open Cloud Luau Execution were **not** verified by the agent (PRIVATE universe; Luau Execution API key missing write scope).

---

## GitHub `main` vs live

| | Live Roblox | GitHub `main` (as of handoff) |
|--|-------------|-------------------------------|
| Content | Original **b15** artifacts | Agent tip including **b19+** work (tokens/weather/F2/lift overlays/rollbacks) + helpers |
| Safe to play? | Intended known-good baseline (owner to confirm) | **Not** what is published; carries spawn-bug risk factors from RCA |
| Tip note | Tower v33 / Lobby v34 | Tip may include later commits (`b20`/`b21`/rollback scripts); treat tree as **dev with known hazards**, not live |

**Do not assume `main` == live.** Prefer artifact places or a clean reapply plan before publishing again.

---

## Design docs to read first

Priority order for economy + roles evaluation:

1. `docs/design/economy-robux.md`
2. `docs/design/game-design-loops.md`
3. `docs/design/first-session-ux.md`
4. `docs/design/gd-review-pass.md` + `docs/design/nuance-test-pass.md`
5. `docs/design/gap-report.md` + `docs/design/bug-backlog.md`
6. `docs/design/spawn-fall-rca.md`
7. Rest: brainstorm, marketing, art, test-plan, overlay proposal

---

## Explicit ask

**Evaluate the economy and the agent roles; say what to keep, change, or drop.**

Be concrete: token sinks/earns, Robux packs vs soft shop, first-session fairness, whether this multi-agent split (coder / tester / UX / GD / economist / marketer / art / brainstorm) helped or created thrash, and what a safer publish pipeline looks like after the lift + void regressions.
