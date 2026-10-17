# Proposal only — lift size modal as pure UI overlay (DO NOT PUBLISH YET)

**Status:** SHIPPED as **b21** (Lobby v33 / Tower v32) — see `internal/lift-overlay-b21.md`  
**Depends on:** live rollback **b20 / v31** (owner: «ок пуш аби робило»)

## Goal

Modal **1–6 including solo**, without touching the original enter / countdown / teleport path.

## Rules

1. **Do not modify** `LiftService` join, leave, countdown, MemoryStore, or `TeleportAsync`.
2. **Do not add** `OpenLiftSizePick` (or any remote that opens UI).
3. **Do not change** `LobbyWorld` cabin / `Zone` size or collision flags.
4. Open/close **only** via existing attributes: `LiftPickOpen` + `LiftPickId` (original client path).
5. Size buttons still fire existing `ChooseLiftSize` only.
6. For solo (`MinPartySize = 1`): change **only** `PlacesConfig.MinPartySize` + button range; optional one-line in `ChooseSize` to snap deadline to `fullCountdown` when size==1 — still no new remotes/UI open path.
7. UI: panel upper-mid; **no** fullscreen Active dimmer; size buttons Active; everything else `Active=false`.

## Out of scope for first overlay publish

Sticky-remote races, leader-picking toasts, countdown reposition experiments — leave original countdown HUD placement until boarding is green for a full session.
