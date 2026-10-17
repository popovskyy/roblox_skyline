# Melee weapons for Skyline Zero: nail club, aluminium bat, crowbar, taped pipe, machete.
#
#   blender --background --factory-startup --python blender/build_weapons.py
#
# Each weapon lies along +Y with its grip at the origin; a small "<Weapon>_Grip_Dark" box marks where
# the hand holds it, so the game can line the mesh up with the tool handle.
# After export: bash scripts/upload_model.sh assets/models/Weapons.fbx SkylineZero_Weapons
# → paste the printed id into PropLibrary.ASSETS.Weapons (never invent ids).

import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
from sz_blender import ROOT, apply_modifiers, box, cylinder, export_fbx, new_prop, rad, render_preview, reset_scene  # noqa: E402

ALONG_Y = (rad(90), 0, 0)  # cylinders are built along Z; rotate them to lie along Y


def club(p):
    cylinder(p, "Handle", "Cloth", 0.13, 1.1, (0, 0.55, 0), rot=ALONG_Y, vertices=8)
    cylinder(p, "Knob", "Dark", 0.18, 0.12, (0, -0.05, 0), rot=ALONG_Y, vertices=8)
    cylinder(p, "Neck", "Wood", 0.16, 0.8, (0, 1.5, 0), rot=ALONG_Y, vertices=8)
    cylinder(p, "Barrel", "Wood", 0.26, 1.4, (0, 2.6, 0), rot=ALONG_Y, vertices=10, bevel=0.03)
    for i, (x, z, y) in enumerate(((0.3, 0, 2.4), (-0.3, 0, 2.8), (0, 0.3, 3.0), (0, -0.3, 2.2), (0.21, 0.21, 3.1))):
        cylinder(p, f"Nail{i}", "Metal", 0.03, 0.35, (x, y, z), rot=(0, rad(90), 0) if z == 0 else (0, 0, 0), vertices=4)
    box(p, "Grip", "Dark", (0.05, 0.05, 0.05), (0, 0.4, 0))


def bat(p):
    # Own mesh (Phase D): longer aluminium barrel — not a Club tint.
    cylinder(p, "Handle", "Dark", 0.12, 1.0, (0, 0.5, 0), rot=ALONG_Y, vertices=8)
    cylinder(p, "Wrap", "Cloth", 0.14, 0.7, (0, 0.55, 0), rot=ALONG_Y, vertices=8)
    cylinder(p, "Neck", "Metal", 0.14, 0.9, (0, 1.45, 0), rot=ALONG_Y, vertices=10)
    cylinder(p, "Barrel", "Metal", 0.24, 1.7, (0, 2.75, 0), rot=ALONG_Y, vertices=12, bevel=0.02)
    cylinder(p, "End", "Metal", 0.26, 0.18, (0, 3.65, 0), rot=ALONG_Y, vertices=12)
    box(p, "Grip", "Dark", (0.05, 0.05, 0.05), (0, 0.35, 0))


def crowbar(p):
    # Held tool mesh (Phase D): was a plain Part block in CombatService.LOOKS.
    cylinder(p, "Shaft", "Rust", 0.09, 2.6, (0, 1.4, 0), rot=ALONG_Y, vertices=8)
    box(p, "Chisel", "Metal", (0.12, 0.55, 0.28), (0, 2.85, 0.08), rot=(rad(-18), 0, 0), bevel=0.02)
    box(p, "Hook", "Metal", (0.12, 0.35, 0.45), (0, -0.05, 0.12), rot=(rad(55), 0, 0), bevel=0.02)
    box(p, "Grip", "Dark", (0.05, 0.05, 0.05), (0, 0.5, 0))


def pipe(p):
    cylinder(p, "Tube", "Rust", 0.15, 3.4, (0, 1.7, 0), rot=ALONG_Y, vertices=10)
    cylinder(p, "Tape", "Cloth", 0.17, 0.9, (0, 0.45, 0), rot=ALONG_Y, vertices=10)
    box(p, "Elbow", "Metal", (0.42, 0.45, 0.42), (0, 3.45, 0), bevel=0.05)
    cylinder(p, "Stub", "Metal", 0.17, 0.4, (0, 3.45, 0.32), vertices=10)
    box(p, "Grip", "Dark", (0.05, 0.05, 0.05), (0, 0.4, 0))


def machete(p):
    box(p, "Handle", "Dark", (0.22, 1.0, 0.34), (0, 0.5, 0), bevel=0.05)
    box(p, "Guard", "Metal", (0.3, 0.12, 0.55), (0, 1.05, 0))
    box(p, "Blade", "Metal", (0.05, 2.4, 0.55), (0, 2.3, 0.05))
    box(p, "Tip", "Metal", (0.05, 0.5, 0.35), (0, 3.6, 0.15), rot=(rad(-25), 0, 0))
    box(p, "Edge", "White", (0.06, 2.4, 0.08), (0, 2.3, -0.24))
    box(p, "Rust", "Rust", (0.06, 0.7, 0.3), (0, 1.8, 0.1))
    box(p, "Grip", "Dark", (0.05, 0.05, 0.05), (0, 0.45, 0))


WEAPONS = [
    ("WeaponClub", club),
    ("WeaponBat", bat),
    ("WeaponCrowbar", crowbar),
    ("WeaponPipe", pipe),
    ("WeaponMachete", machete),
]


def main():
    reset_scene()
    for i, (name, build) in enumerate(WEAPONS):
        build(new_prop(name, i * 2.5))
    apply_modifiers()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "blender", "Weapons.blend"))
    render_preview(os.path.join(ROOT, "assets", "previews", "Weapons.png"), (5.0, 1.8, 0), 11, 10)
    export_fbx(os.path.join(ROOT, "assets", "models", "Weapons.fbx"))
    print("[Weapons] exported", len(WEAPONS))


main()
