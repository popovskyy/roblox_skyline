# SkylineZero — Economy & Robux (Classy Survival Monetization)

> **Status (17.10, build b24):** Token earn rates actually in the game are in `GameConfig.Tokens` (deepest floor 2/level, chests 1/2/4/8, zombie 1, building 3, lifting a teammate 2, win x2). Tokens have **no sink yet** and there is **no Robux shop**; this doc is the plan for both. Keep the hard rules: never tokens→Robux, no shop in the first-session path, Robux never skips the game.
>
> Imported from the Cursor team's notes. Where this doc and the code disagree, the code and `GameConfig` win.


Owner brief: spend Robux on things that **matter for survival** — cool, useful, fair. Not junk cosmetics-only fluff. Pay helps the run; it never skips the game.

**Aligned with:** [game-design-loops.md](./game-design-loops.md) (§2 token rebalance, craft, team chest), [first-session-ux.md](./first-session-ux.md) (one objective, no shop spam in first 180s), [bug-backlog.md](./bug-backlog.md) (token nerf + med craft at step 6).

**Ship gate:** Monetization UI and spend products land with backlog **step 6** (onboarding clarity / med craft / token nerf). Do not put a shop in the first-session tower path. Lobby catalog is fine after first return.

---

## 1. Soft currency (Tokens) vs Robux

### Roles

| Currency | Earn | Spend | Feel |
|----------|------|-------|------|
| **Tokens** (soft) | Play: kills, floor clear, roof | Lobby meta: permanent small upgrades, cosmetic tints, token-shop consumables (weak) | Chase every run; scarce after nerf |
| **Robux** (hard) | Real money | Survival-useful packs + convenience that never replaces skill | “I bought a better chance to survive this expedition” |

Tokens are the **loop fuel**. Robux is the **accelerant** — never a bypass.

### Token economy (locked to loops doc)

Target after nerf (per player-equivalent, 4-stack; solo ≈ ×1.25 drop, not ×4):

| Source | Payout |
|--------|--------|
| Zombie kill | **1–2** (elites **5**) |
| Floor clear | **10 + 2×floorIndex** (cap **+25**) |
| Roof / session end (once) | **+25** |
| Idle / AFK | **0** |
| Per floor total | **8–15** |
| Per 15-min run | **40–70** |

**Token sinks (soft shop — no Robux):**

| Sink | Cost (tokens) | Effect | Cap / guard |
|------|---------------|--------|-------------|
| Bandage restock (3×) | 35 | Same as craft output (Heal 25 each) | Max **1 pack / run** from token shop |
| Scrap bundle (8) | 40 | Craft bulk | Max **1 / run** |
| Flashlight cell (common) | 25 | +20% beam time this run | Stacks once |
| Lobby tint / armband color | 80–150 | Cosmetic only | Unlimited |
| Personal stash +2 slots (permanent) | 400 | Meta QoL | Max **+4** via tokens (then Robux path) |
| Team beacon (1 charge, weak) | 120 | Ping last team position 60s | Max **1 / run** |

**Design intent:** after nerf, a full 15-min run (~50 tokens) buys **one** meaningful soft restock — not a full kit. Robux packs fill the gap when the player wants reliability, not when tokens shower.

### Conversion rule (hard)

| Rule | Spec |
|------|------|
| Tokens → Robux | **Never** |
| Robux → Tokens | **Allowed only** as a small bundle component (see packs), never as pure token dump that re-creates shower |
| Robux → Tokens rate (if in pack) | Cap **200 tokens** per purchase; soft sink still applies same run caps |
| Daily login tokens | **0** at launch (avoid inflation); revisit later |

---

## 2. What Robux SHOULD buy (survival-useful)

Principle: **paid gear is the same items the loop already teaches** — more reliable stock, better tools, team help — with hard caps so skill + loot still win deep floors.

### Catalog (MVP)

| Product | Gameplay effect | Anti-P2W guard | Suggested Robux |
|---------|-----------------|----------------|-----------------|
| **Medkit Pack (3)** | 3× Medkit (Heal 60 / revive charge 1 each) into **personal backpack** (can deposit to team chest) | Max **1 pack purchase / run**; medkits identical to craft — no god heal | **49** |
| **Bandage Pack (6)** | 6× Bandage (Heal 25) | Max **1 / run**; cannot exceed backpack+chest free slots (overflow → chest if space, else refuse) | **25** |
| **Tactical Flashlight** | Permanent unlock: brighter cone, **+40%** battery vs common; same toggle UX | No wallhack / no zombie highlight; battery still drains | **99** |
| **Stash Upgrade +4** | Permanent **+4** team-chest slots for parties you lead (or personal meta stash if party chest not owned) | Cap total chest **32** slots (base 24 + max +8 from all sources); does not add damage | **149** |
| **Revive Token (1)** | Instant self-revive **or** ally revive at marker, **full 60 HP**, **1× per death event** | Max **2 held**; **1 use / floor**; 8s channel (interruptible); no invuln after; cannot use if party wiped | **75** |
| **Team Beacon (3 charges)** | Place ping: party sees world marker **90s**; reveals nearest **uncleared** elevator path soft glow | No loot radar, no zombie count, no floor skip; charges shared to buyer only | **49** |
| **Rare Mat Crate** | **Electronics ×4** + **Scrap ×10** into backpack/chest | Max **1 crate / run**; mats = craft inputs only (no weapons); does not auto-craft | **99** |
| **Crowbar Grip (permanent)** | Rubble break **−20%** hold time (solo); still 2-player shared bar | Floor gates remain; cannot one-shot rubble (<2.4s floor) | **125** |
| **Ammo Belt (run)** | +1 ammo stack capacity this run (exact ammo type = current weapon table) | No infinite ammo; drop/chest rules unchanged | **39** |

### Fairness rules (pay ≠ instant win)

1. **Same stats as earned gear** — Robux medkits = craft medkits. No “Robux Medkit+”.
2. **Per-run purchase caps** on consumables (table above).
3. **No combat power multipliers** from Robux (damage, HP, armor, zombie spawn rate).
4. **No floor / elevator skip** products.
5. **Co-op first:** consumables can go into **team chest**; buying helps the squad, not a solo god.
6. **Channel / interrupt** on revive token — paid revive is not free “press R to win”.
7. **Deep floors stay scarce** — packs refill inventory; world loot density and craft costs unchanged.
8. **First session:** shop locked until tutorial return (roof deposit / step that unlocks craft). Zero Robux prompts in first 180s.

---

## 3. What Robux must NEVER buy

| Forbidden | Why |
|-----------|-----|
| Skip whole floors / auto-clear / “teleport to roof” | Deletes core loop |
| God mode / damage immunity / one-shot zombies | Pay-to-win combat |
| Pay-to-clear zombies (kill aura, auto-aim packs, spawn delete) | Unfair to F2P squadmates |
| Infinite ammo / infinite heals without caps | Breaks scarcity tension |
| Loot ESP / full map reveal of scrap & electronics | Skips explore dopamine |
| Exclusive weapons with higher damage than F2P path | Permanent P2W ladder |
| Token showers (5000+ tokens) that erase sinks | Re-inflates soft economy |
| Party kick immunity / host abuse tools | Toxicity |
| Skip rubble without crowbar interaction | Gates exist for reason |
| Paid zombie respawn disable for others / grief tools | Anti-social |

Cosmetics are **allowed later** as secondary (armband, radio skin, flashlight housing color) — never as the *only* catalog. MVP priority = survival utility above.

---

## 4. Starter packs & Battle-Pass-lite

### First-session clarity (hard UX rules)

| Rule | Spec |
|------|------|
| Tower first 180s | **No** shop modal, **no** GamePass prompt, **no** “limited offer” toast |
| Unlock shop | After first roof return **or** lobby re-entry post-tutorial |
| Soft CTA | Lobby: one quiet button `СНАРЯЖЕННЯ` / `GEAR` — amber, not pulsing rainbow |
| Pack open | Grant → short list “+3 Medkit” → dismiss; no second upsell in same session |

### Starter Pack — “First Descent Kit”

| Contents | Notes |
|----------|-------|
| Medkit ×2 | Same as craft |
| Bandage ×4 | Same as craft |
| Flashlight cell (common, 1 run) | Or 50% progress toward Tactical Flashlight if already tracking unlock |
| Tokens **100** | Under soft conversion cap; ~2 soft restocks |
| Team Beacon ×1 | Teach squad ping once |

| Field | Value |
|-------|-------|
| Price | **149** Robux |
| Account limit | **1× ever** |
| When shown | Lobby after first tutorial complete; optional second surface on first death end-screen as **one** line CTA (not modal wall) |

### Mid Pack — “Expedition Resupply”

| Contents | Price |
|----------|-------|
| Medkit Pack (3) + Rare Mat Crate (elec 4 + scrap 10) + Ammo Belt (run) | **175** Robux (bundle save vs 49+99+39 = 187) |
| Limit | **1 / day** account |

### Premium Pack — “Squad Anchor”

| Contents | Price |
|----------|-------|
| Tactical Flashlight (perm) + Stash Upgrade +4 + Revive Token ×2 + Team Beacon (3) | **399** Robux |
| Limit | Flashlight/stash once; consumables refill rules still apply |

### Battle-Pass-lite — “Roof Ledger” (season 4–6 weeks)

Free track must stay **meaningful** so F2P feels respected.

| Track | Examples (concrete) |
|-------|---------------------|
| **Free** | Tokens 40 / 60 / 80 at milestones; Bandage ×3; Scrap ×12; armband tint; 1× Team Beacon |
| **Premium (Robux)** | Medkit ×2 at mid; Rare mats; Revive Token ×1; Crowbar Grip **or** Flashlight if not owned; exclusive radio skin |
| Premium price | **499** Roblox (or **399** launch promo) |
| XP source | Floor clear, roof touch, scrap deposited to team chest — **not** Robux XP skip for whole pass |
| XP skip | Optional **tiny** +1 level for **49** Robux, max **3** per season (never skip to end) |
| First session | Pass UI **hidden** until tutorial done; no “buy premium” in tower |

Premium track rewards = same item definitions as shop (no exclusive DPS gear).

---

## 5. Price bands (Robux)

| Band | Range | Products | Player moment |
|------|-------|----------|---------------|
| **Cheap impulse** | **25–49** | Bandage Pack, Team Beacon, Ammo Belt, Medkit Pack, XP+1 | Died once / inventory empty / “one more floor” |
| **Mid** | **75–149** | Revive Token, Rare Mat Crate, Tactical Flashlight, Stash +4, Starter Pack, Crowbar Grip | “I play this weekly” |
| **Premium** | **175–499** | Expedition Resupply, Squad Anchor, Roof Ledger premium | Commitment / gift-to-squad vibe |

**Psychological anchors (Roblox-typical):** prefer endings **25 / 49 / 75 / 99 / 125 / 149 / 175 / 399 / 499**. Avoid 1000+ at launch.

---

## 6. Master table (item → effect → guard → Robux)

| Item / Product | Gameplay effect | Anti-P2W guard | Robux |
|----------------|-----------------|----------------|-------|
| Bandage Pack (6) | Heal 25 ×6 | 1/run; slot check | 25 |
| Medkit Pack (3) | Heal 60 / revive charge ×3 | 1/run; = craft stats | 49 |
| Team Beacon (3) | Party ping 90s; soft elevator glow | No loot/zombie ESP; buyer charges | 49 |
| Ammo Belt (run) | +1 ammo stack capacity | Finite ammo; run-bound | 39 |
| Revive Token (1) | Channel revive 60 HP | 2 held; 1/floor; interruptible; no wipe revive | 75 |
| Rare Mat Crate | Elec 4 + Scrap 10 | 1/run; craft inputs only | 99 |
| Tactical Flashlight | Perm better light +40% battery | No wallhack | 99 |
| Crowbar Grip | −20% rubble time | Min break still ≥2.4s | 125 |
| Stash Upgrade +4 | +4 chest slots | Cap 32 total | 149 |
| First Descent Kit | Med2 + Band4 + tokens100 + beacon1 + cell | 1× account; post-tutorial | 149 |
| Expedition Resupply | Med3 + mat crate + ammo belt | 1/day | 175 |
| Squad Anchor | Flashlight + stash+4 + revive×2 + beacon3 | Perm pieces once | 399 |
| Roof Ledger Premium | Season track (utility + cosmetic) | Free track solid; XP skip ≤3 | 499 |
| Pass XP +1 | +1 ledger level | Max 3/season | 49 |

---

## 7. Hooks: team chest + drop + loot loop

Monetization must **reinforce** the co-op loop from [game-design-loops.md](./game-design-loops.md) §2 / §5 — not replace it.

```
explore → loot → (fight) → deposit chest / drop for ally → clear → elevator → next floor
         ↑                                      ↑
    Rare Mat Crate / packs              Medkit deposit / Revive Token
```

| Hook | How Robux products plug in |
|------|----------------------------|
| **Shared team chest** (24 base slots) | Purchased meds/mats prefer **deposit prompt** “У скриню команди?” after grant; Stash Upgrade increases shared capacity — whole party feels the buy |
| **Drop (TTL 120s, party-only)** | Buyer can drop paid medkit under fire for downed ally — paid stock becomes **squad dependency** fuel, same as crafted |
| **Loot quota / counter** | Mat crate fills craft inputs; does **not** auto-complete tutorial scrap 0/3 (tutorial ignores purchased scrap for quest Total until after tutorial.3) |
| **Craft scarcity** | Packs reduce drought; recipes stay Scrap 4 / Scrap 6+Elec 2 — paid mats are shortcuts to craft, not skip-craft god items |
| **Roof +25 tokens** | Soft earn remains visible; Robux token crumbs in packs stay ≤200 so roof bonus still feels like session climax |
| **Near-miss end screen** | CTA may offer First Descent / Resupply **once** as text button — never auto-prompt ProcessReceipt mid-death cam |
| **Revive / death marker** | Revive Token uses same downed marker UX; paid revive still needs LOS/channel near body |

**Fairness for F2P teammates:** if one player buys Medkit Pack and deposits to chest, allies use the same items — no “buyer-only heal aura”.

---

## 8. Implementation notes (coder)

No real upload. Placeholders only. Respect backlog order: economy products with **step 6**; chest/drop must exist from **step 2**.

### DataStores (suggested)

| Store name (placeholder) | Key | Value |
|--------------------------|-----|-------|
| `SZ_PlayerEconomy_v1` | `userId` | `{ tokens, permUnlocks{}, stashBonus, pass{seasonId, xp, premium}, starterClaimed, dailyBundleDay }` |
| `SZ_PurchaseLog_v1` | `userId:purchaseId` | `{ productId, at, runId? }` — idempotency / support |
| Session (memory) | party | `{ runCaps{ medPack, bandagePack, matCrate }, beaconCharges }` |

**Rules:**
- All grants **server-side** after `MarketplaceService.ProcessReceipt` — never trust client.
- Idempotent receipt: same `PurchaseId` → return `PurchaseGranted` without double grant.
- Tokens integer; clamp ≥0; apply sinks before grant if overflow cosmetics.
- Perm unlocks: `flashlight_tactical`, `crowbar_grip`, `stash_bonus` (0–8).
- Run caps reset on new tower run / party recreate — not on death alone.

### Product ID placeholders

Replace with real Developer Product / GamePass IDs when uploading in Creator Dashboard.

| `productKey` | Type | Placeholder ID | Robux |
|--------------|------|----------------|-------|
| `dev_bandage_pack_6` | Developer Product | `PROD_BANDAGE_6` | 25 |
| `dev_medkit_pack_3` | Developer Product | `PROD_MEDKIT_3` | 49 |
| `dev_team_beacon_3` | Developer Product | `PROD_BEACON_3` | 49 |
| `dev_ammo_belt_run` | Developer Product | `PROD_AMMO_BELT` | 39 |
| `dev_revive_token_1` | Developer Product | `PROD_REVIVE_1` | 75 |
| `dev_rare_mat_crate` | Developer Product | `PROD_MAT_CRATE` | 99 |
| `dev_pass_xp_1` | Developer Product | `PROD_PASS_XP` | 49 |
| `dev_starter_first_descent` | Developer Product | `PROD_STARTER` | 149 |
| `dev_expedition_resupply` | Developer Product | `PROD_RESUPPLY` | 175 |
| `dev_squad_anchor` | Developer Product | `PROD_SQUAD_ANCHOR` | 399 |
| `gp_flashlight_tactical` | GamePass (perm) | `GP_FLASHLIGHT` | 99 |
| `gp_crowbar_grip` | GamePass (perm) | `GP_CROWBAR` | 125 |
| `gp_stash_plus4` | GamePass (perm) | `GP_STASH4` | 149 |
| `gp_roof_ledger_premium` | GamePass (season) **or** DevProduct season grant | `GP_LEDGER` | 499 |

**Prefer:** consumables = Developer Products (repurchase). Permanents = GamePasses (or one-time DevProducts with DataStore flag — pick one pattern and stick to it; GamePass is simpler for flashlight/stash).

### Grant pipeline (pseudo)

```
ProcessReceipt(receipt)
  → lookup productKey
  → if already granted: return PurchaseGranted
  → check account/run caps → if fail: still grant? NO — return NotProcessedYet only on DataStore outage; else grant alternative tokens≤50 + log (never leave player charged with nothing)
  → apply items to InventoryService / team chest
  → write PurchaseLog + PlayerEconomy
  → replicate soft toast once (UX)
  → return PurchaseGranted
```

### UI surfaces (with UX)

| Surface | When |
|---------|------|
| Lobby `СНАРЯЖЕННЯ` | Post-tutorial |
| End-of-run CTA | Optional 1 product |
| In-run pause / radio menu | Consumables only; no full catalog mid-fight |
| Tower objective strip | **Never** ads |

### Localization keys (suggest)

`shop.title`, `shop.medkitPack`, `shop.fairnessNote` (“Ті самі аптечки, що з крафту — ліміт 1 за рейд”), `shop.lockedTutorial`.

### Acceptance (economy)

1. F2P can finish tutorial and craft bandages with zero Robux.  
2. Token earn matches loops nerf; Robux token crumbs ≤200/purchase.  
3. Buying Medkit Pack cannot exceed 1/run; stats = craft.  
4. No product skips floors, clears zombies, or grants damage buffs.  
5. Purchased meds depositable to team chest / droppable to allies.  
6. No shop UI before tutorial return.  
7. ProcessReceipt idempotent; placeholders only until real IDs.

---

## 9. Priority vs backlog

| Backlog | Economy work |
|---------|--------------|
| 1 Elevators | None |
| 2 Rubble / drop / team chest | Implement chest slot API used later by Stash Upgrade |
| 3 Quest counter / death marker | Revive Token targets same marker |
| 4 No zombie respawn | Do not sell “clear floor” |
| 5 Atmosphere | Cosmetics secondary |
| **6 Onboarding / med craft / token nerf** | **Ship soft sinks + Robux MVP catalog + starter lock** |
| 7 Cross-plat anims | None |

---

*Economist deliverable for SkylineZero. Concrete numbers; no secrets; classy survival spend.*
