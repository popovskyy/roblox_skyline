# Skyline Zero — banner art brief (human / Blender redo)

> **Status (17.10, final-pass):** Concept direction for Art. Do **not** upload to Creator Hub until
> owner + Art approve. Do **not** invent asset ids.

## Concept files (repo)

| Role | Path | Size / ratio | Gate |
|------|------|----------------|------|
| Primary widescreen banner / thumb | `assets/store/thumbnail-1920x1080.png` | **1920×1080** | Art approve |
| Experience icon | `assets/store/icon-512.png` | **512×512** | Art approve |
| Optional owner-PC concept | `C:\Users\Roman\.cursor\projects\c-Roblox\assets\banner-1920-concept.jpg` | 16:9 | Re-export if preferred over repo PNG |

See [store-visual-brief.md](./store-visual-brief.md) for palette / composition / rejection list.

## One-sentence pitch

Cinematic still on a ruined skyscraper **roof**: overcast Ukrainian autumn light, one warm doorway as the only hope, dead overgrown city below — film key art, not store collage.

## Composition (build this)

1. **Camera:** low / eye-level on the roof terrace, looking out across the parapet to the dead skyline. Shallow DOF: foreground ledge soft, mid-roof sharp, distant city soft haze.
2. **Focal point (one only):** small concrete shelter / maintenance shack doorway with **cold amber** interior spill; **2 tiny** survivor silhouettes in/near the door — human scale, not hero poses.
3. **Roof props (supporting, not competing):** rusted HVAC left, tilted satellite dish right, cracked wet concrete, moss in seams, puddles — sparse, grounded.
4. **Background:** ruined high-rises with dying green vines, teal-grey atmospheric haze — readable silhouette mass, not busy collage.
5. **Safe zone:** keep doorway + figures inside center ~70% (Roblox UI crops edges).
6. **Text:** **none in the render.** Owner overlays `Skyline Zero` later as a restrained film title card (Oswald / condensed industrial, bone cream, lower-left or lower-third, small).

## Palette (hex)

From store brief + Theme tokens (marketing, not HUD chrome):

| Role | Hex | Source |
|------|-----|--------|
| Ash concrete | `#6B6E72` | store-visual-brief |
| Deep slate / shadows | `#1C2228` | store-visual-brief |
| Cold amber (doorway only) | `#C48A3A` | store-visual-brief (Theme Amber `#E3A436` is hotter — prefer cold amber on banner) |
| Teal haze / distant air | `#4A6B6E` | store-visual-brief |
| Dying green / toxic hint | `#2F6F64` | Theme `Toxic` |
| Soft toxic fog (distant only) | `#6FB3A6` | Theme `ToxicFog` — use sparingly, desaturated |
| Bone / title overlay | `#E8E2D6` or Theme Cream `#EEE6D0` | title card only |
| Panel / night mass | `#0F0E0C`, `#1E1C18` | Theme Panel — deep fill, not UI boxes |

## Light & grade

- Flat **overcast** Ukrainian autumn daylight — cool grey sky, soft contrast.
- Single warm accent: doorway amber.
- Natural film grain, soft roll-off — **not** HDR crunch, not bloom spam, not god-ray fireworks.
- Anamorphic / trailer still feel; grounded photo-real or Blender Cycles path-trace look.

## Negative prompts / rejection list

Do **not** include:

- Purple / neon / cyberpunk gradients
- Glossy 3D logo floating in void
- Midjourney-looking swirl skies, rainbow grading
- Oversharpen HDR, plastic characters, stock “apocalypse montage”
- Emoji, fake HUD chrome, promo stickers (“NEW”, “#1”)
- Zombie face close-ups, blood collage, cluttered text spam
- Botanical sunny park roof, cartoon mascot undead
- Inset cards, multi-layer collage, busy sky

## Blender / capture notes

- Prefer in-game camera or Blender set dressed to match `WorldBuilder` roof + ruins mood.
- Export 1920×1080, sRGB, no watermark.
- Optional title overlay in Affinity/PS: `SKYLINE ZERO` only, cream `#E8E2D6`, condensed sans, opacity ~90%, lower-left third — or leave blank for owner.

## Roblox upload targets (sizes)

| Asset | Exact px | Where (Creator Hub) |
|-------|----------|---------------------|
| Experience icon | **512×512** | Experience → configure media / icon (universe-level store face) |
| Thumbnail + widescreen banner | **1920×1080** | Experience thumbnails / media carousel (same canvas OK for both) |

Universe (experience) media is what Discovery / experience page shows. Place-level icons exist for Lobby vs Tower places but are secondary; primary store face = **experience (universe)**.
