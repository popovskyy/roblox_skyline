# SkylineZero — Roblox store visual brief

> **Status (17.10, after b34):** Checklist for owner + Art. Do **not** upload to Creator Hub until they
> approve. Concepts already in repo under `assets/store/` (see table). Full owner gate list:
> [owner-gates.md](./owner-gates.md).
>
> Where this doc and the code disagree, the code and `GameConfig` win.

Art / marketing execution guide.

---

## Asset checklist (exact specs)

| Asset | Size (px) | Ratio | Repo file | Owner gate |
|-------|-----------|-------|-----------|------------|
| **Experience icon** | **512 × 512** | 1:1 | `assets/store/icon-512.png` | Art approve → Creator Hub |
| **Thumbnail / widescreen banner** | **1920 × 1080** | 16:9 | `assets/store/thumbnail-1920x1080.png` | Same canvas OK for thumb + banner; Art approve |
| **Banner brief / redo notes** | — | — | [banner-art-brief.md](./banner-art-brief.md) | Human/Blender redo if concept rejected |
| **Optional square thumb** | 512 × 512 | 1:1 | (reuse icon mood) | Social / Discord |

**Export:** sRGB, no watermark, no “AI sample” text. Max file size per Roblox limits at upload time (keep &lt; ~5–10 MB).  
**Do not invent asset ids.** Hub upload is owner-only after merge.

---

## Mood (north star)

**Last-of-Us tower post-apoc** — ruined high-rise as character, ash dusk, sparse amber windows, dead distant skyline, squad as small silhouettes.

**Not:** generic green zombie face, blood collage, neon purple glow, cartoon undead mascot, “SURVIVE!!!” scream type, botanical/garden roof, floating disconnected skyboxes.

**Palette**

| Token | Hex (approx) | Use |
|-------|----------------|-----|
| Ash concrete | `#6B6E72` | Tower mass |
| Deep slate | `#1C2228` | Shadows / night |
| Cold amber | `#C48A3A` | Lit windows / elevator glow |
| Teal haze | `#4A6B6E` | Distant air / fog |
| Bone text | `#E8E2D6` | Title only |

Typography: condensed industrial sans (not Inter/Roboto default look if custom). One word + logo max on thumb.

---

## Composition — icon 512

1. **Dominant:** vertical tower silhouette filling ~60–70% height, slight ¾ angle or straight-on slab.  
2. **Accent:** 3–8 warm window lights (asymmetric, not grid of Christmas lights).  
3. **Scale cue:** 2 tiny silhouettes on a mid ledge **or** elevator shaft glow at base — optional, keep tiny.  
4. **Background:** muted overcast / teal-grey haze, soft vignette.  
5. **Text:** none on icon preferred; if needed, tiny `SZ` monogram bottom corner, high contrast.  
6. **Readable test:** shrink to 64px — tower shape + amber still recognizable.

**Avoid on icon:** faces, guns in foreground, dense particle gore, busy city collage.

---

## Composition — thumbnail / banner 1920×1080

1. **Full-bleed hero:** edge-to-edge ruined tower exterior OR mid-floor ledge looking out at dead skyline (full-bleed; no inset card).  
2. **Brand:** `SKYLINEZERO` large, left or lower-left third — hero-level, not a nav pill.  
3. **One line support (optional):** `Dead tower. Your crew.` / UK: `Мертва вежа. Твоя команда.`  
4. **CTA not required** on Roblox banner (page has Play).  
5. **Figures:** 2–3 silhouettes mid-ground; no floating badges/stickers.  
6. **Safe zone:** keep logo + faces of action inside center 70% (UI chrome crops edges).  
7. **Motion for trailer later:** slow push-in up the tower; rain optional once weather ships — don’t fake weather in still if store copy can’t claim it.

---

## Mockups (concepts) — not in repo yet

Target filenames once art is ready (folder `media/marketing/` does not exist today):

| File | Size | Role |
|------|------|------|
| `media/marketing/icon-512-concept.png` | 512×512 | Experience icon concept |
| `media/marketing/banner-1920-concept.png` | 1920×1080 | Widescreen banner + primary thumb |
| `media/marketing/thumbnail-alt-concept.png` | 1920×1080 | Alt: ledge POV + squad silhouettes |

Art final: Blender/paint over or in-game lighting match. Concepts are direction only, not live store art.

---

## Rejection list (quick)

- Green zombie close-up  
- Purple/neon cyber glow  
- Multi-layer glossy cards / pill clusters  
- Overlaid promo stickers (“NEW”, “#1”)  
- Botanical roof / sunny park skyline  
- Busy HUD mockup as the main image
