# Interior props for the four floors of Skyline Zero (post-apocalyptic, overgrown, low-poly).
#
#   blender --background --factory-startup --python blender/build_interior_props.py
#
# Output: assets/models/InteriorProps.fbx, blender/InteriorProps.blend, assets/previews/InteriorProps.png
# See sz_blender.py for the naming rules the game relies on.

import os
import random
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
from sz_blender import (  # noqa: E402
    ROOT,
    apply_modifiers,
    box,
    cylinder,
    export_fbx,
    new_prop,
    rad,
    render_preview,
    reset_scene,
)

rng = random.Random(7)


def sofa(p):
    box(p, "Base", "Fabric", (7, 3, 1.4), (0, 0, 0.9), bevel=0.15)
    box(p, "Back", "Fabric", (7, 0.9, 2.2), (0, 1.05, 2.0), bevel=0.15)
    for x in (-3.2, 3.2):
        box(p, f"Arm{x}", "Fabric", (0.7, 3, 1.8), (x, 0, 1.4), bevel=0.12)
    box(p, "Cushion", "Cloth", (2.8, 2.2, 0.5), (-1.6, -0.2, 1.8), rot=(0, 0, rad(8)), bevel=0.1)
    box(p, "Tear", "Dark", (1.2, 0.05, 0.6), (1.5, -1.52, 1.0))
    for x in (-3, 3):
        for y in (-1.2, 1.2):
            box(p, f"Leg{x}{y}", "Dark", (0.3, 0.3, 0.3), (x, y, 0.15))


def bed(p):
    box(p, "Frame", "Wood", (4.4, 7.4, 0.8), (0, 0, 0.6), bevel=0.06)
    box(p, "Mattress", "Cloth", (4, 7, 0.8), (0, 0, 1.4), bevel=0.15)
    box(p, "Headboard", "Wood", (4.4, 0.4, 2.6), (0, 3.6, 1.6), bevel=0.06)
    box(p, "Blanket", "Fabric", (4.1, 3.6, 0.25), (0, -1.6, 1.85), rot=(rad(3), 0, rad(-4)), bevel=0.08)
    box(p, "Pillow", "White", (2.2, 1, 0.5), (0, 2.6, 2.0), bevel=0.15)


def mattress(p):
    box(p, "Pad", "Cloth", (4, 7, 0.7), (0, 0, 0.35), rot=(0, 0, rad(12)), bevel=0.2)
    box(p, "Stain", "Dark", (1.6, 2, 0.05), (0.6, -1, 0.72), rot=(0, 0, rad(12)))
    box(p, "Blanket", "Fabric", (3, 3, 0.2), (-0.4, 1.6, 0.8), rot=(rad(4), rad(3), rad(30)), bevel=0.06)


def fridge(p):
    box(p, "Body", "White", (3, 2.6, 6.5), (0, 0, 3.25), bevel=0.2)
    box(p, "DoorGap", "Dark", (3.02, 0.05, 0.08), (0, -1.31, 4.4))
    box(p, "Handle", "Metal", (0.2, 0.3, 1.6), (1.1, -1.42, 5.3))
    box(p, "Handle2", "Metal", (0.2, 0.3, 1.2), (1.1, -1.42, 3.4))
    box(p, "Rust", "Rust", (1.2, 0.05, 0.9), (-0.6, -1.31, 0.8))


def counter(p):
    box(p, "Cabinet", "Wood", (8, 2.4, 3), (0, 0, 1.5), bevel=0.05)
    box(p, "Top", "Concrete", (8.2, 2.6, 0.3), (0, 0, 3.15))
    box(p, "Sink", "Metal", (2, 1.6, 0.4), (-2, 0, 3.15))
    cylinder(p, "Tap", "Metal", 0.12, 1.2, (-2, 0.9, 3.8), vertices=8)
    for x in (-3, -1, 1, 3):
        box(p, f"Door{x}", "Wood", (1.8, 0.06, 2.4), (x, -1.22, 1.5))
    box(p, "Pot", "Dark", (1.2, 1.2, 0.8), (2.4, 0, 3.7), bevel=0.15)


def table(p):
    box(p, "Top", "Wood", (5, 3, 0.3), (0, 0, 2.6), bevel=0.05)
    for x in (-2.2, 2.2):
        for y in (-1.2, 1.2):
            box(p, f"Leg{x}{y}", "Wood", (0.3, 0.3, 2.5), (x, y, 1.25))
    box(p, "Can", "Red", (0.5, 0.5, 0.7), (1.2, 0.4, 3.1))
    box(p, "Plate", "White", (0.9, 0.9, 0.08), (-1, -0.3, 2.8))


def chair(p):
    box(p, "Seat", "Wood", (1.8, 1.8, 0.25), (0, 0, 1.7))
    box(p, "Back", "Wood", (1.8, 0.25, 1.8), (0, 0.8, 2.7))
    for x in (-0.75, 0.75):
        for y in (-0.75, 0.75):
            box(p, f"Leg{x}{y}", "Wood", (0.2, 0.2, 1.6), (x, y, 0.8))


def desk(p):
    box(p, "Top", "Wood", (5.4, 2.6, 0.25), (0, 0, 2.5), bevel=0.04)
    box(p, "Drawers", "Metal", (1.6, 2.4, 2.4), (1.8, 0, 1.2))
    for x in (-2.5,):
        for y in (-1.1, 1.1):
            box(p, f"Leg{y}", "Metal", (0.2, 0.2, 2.4), (x, y, 1.2))
    box(p, "Monitor", "Dark", (2, 0.2, 1.3), (-0.6, 0.6, 3.4), rot=(rad(-8), 0, rad(15)))
    box(p, "Stand", "Dark", (0.3, 0.3, 0.6), (-0.6, 0.7, 2.9))
    box(p, "Papers", "White", (1.2, 0.9, 0.06), (0.8, -0.4, 2.66), rot=(0, 0, rad(20)))


def shelf(p):
    for x in (-2.4, 2.4):
        for y in (-0.8, 0.8):
            box(p, f"Post{x}{y}", "Metal", (0.2, 0.2, 7), (x, y, 3.5))
    for i, z in enumerate((0.6, 2.4, 4.2, 6.0)):
        box(p, f"Board{i}", "Metal", (5, 1.8, 0.15), (0, 0, z))
    for i in range(7):
        z = (0.6, 2.4, 4.2, 6.0)[rng.randint(0, 3)] + 0.6
        x = rng.uniform(-1.8, 1.8)
        paint = rng.choice(["Cardboard", "Cardboard", "Red", "White"])
        box(p, f"Box{i}", paint, (rng.uniform(0.8, 1.4), 1.2, rng.uniform(0.7, 1.1)), (x, 0, z), rot=(0, 0, rad(rng.uniform(-10, 10))))


def boiler(p):
    cylinder(p, "Tank", "Rust", 2, 6, (0, 0, 3.6), vertices=16, bevel=0.05)
    cylinder(p, "Cap", "Metal", 2.15, 0.4, (0, 0, 6.8), vertices=16)
    cylinder(p, "Base", "Dark", 2.3, 0.6, (0, 0, 0.3), vertices=16)
    cylinder(p, "PipeUp", "Metal", 0.35, 4, (1.2, 0, 8.6), vertices=10)
    cylinder(p, "PipeSide", "Metal", 0.35, 3, (2.6, 0, 2), rot=(0, rad(90), 0), vertices=10)
    cylinder(p, "Valve", "Red", 0.5, 0.15, (2.2, -0.6, 2), rot=(rad(90), 0, 0), vertices=10)
    box(p, "Gauge", "White", (0.8, 0.1, 0.8), (0, -2.05, 4.5))


def cabinet(p):
    box(p, "Body", "Metal", (3, 1.4, 6), (0, 0, 3), bevel=0.08)
    box(p, "Door", "Dark", (2.6, 0.06, 5.4), (0, -0.72, 3))
    box(p, "Warning", "Yellow", (0.9, 0.05, 0.9), (0, -0.76, 4.6), rot=(0, rad(45), 0))
    for i in range(4):
        cylinder(p, f"Cable{i}", "Dark", 0.12, 4, (-1 + i * 0.6, 0.2, 7.9), vertices=6)


def pipe_wall(p):
    for i, z in enumerate((3, 4.2, 5.4)):
        cylinder(p, f"Pipe{i}", "Metal" if i != 1 else "Rust", 0.4, 12, (0, 0, z), rot=(0, rad(90), 0), vertices=10)
    for x in (-5, 0, 5):
        box(p, f"Clamp{x}", "Dark", (0.3, 0.9, 3.3), (x, 0.2, 4.2))
    cylinder(p, "Drop", "Rust", 0.35, 3, (4, 0, 1.5), vertices=10)
    cylinder(p, "Wheel", "Red", 0.6, 0.15, (-3, -0.5, 4.2), rot=(rad(90), 0, 0), vertices=12)


def vent_duct(p):
    box(p, "Duct", "Metal", (10, 3, 3), (0, 0, 3.4), bevel=0.05)
    for x in (-4.9, -1.6, 1.6, 4.9):
        box(p, f"Seam{x}", "Dark", (0.2, 3.1, 3.1), (x, 0, 3.4))
    for x in (-3.5, 3.5):
        box(p, f"Leg{x}", "Dark", (0.3, 2, 1.9), (x, 0, 0.95))
    box(p, "Grille", "Dark", (0.1, 2.4, 2.4), (5.05, 0, 3.4))
    box(p, "Moss", "Moss", (4, 3.05, 0.2), (-2, 0, 4.95), rot=(0, rad(-3), 0))


def barrel(p):
    cylinder(p, "Drum", "Rust", 1.2, 3, (0, 0, 1.5), vertices=14)
    for z in (0.6, 2.4):
        cylinder(p, f"Ring{z}", "Dark", 1.25, 0.15, (0, 0, z), vertices=14)
    cylinder(p, "Lid", "Dark", 1.15, 0.1, (0, 0, 3.02), vertices=14)


def boxes(p):
    box(p, "A", "Cardboard", (2.4, 2, 1.8), (0, 0, 0.9), rot=(0, 0, rad(6)))
    box(p, "B", "Cardboard", (2, 1.8, 1.6), (0.3, 0.1, 2.6), rot=(0, 0, rad(-12)))
    box(p, "C", "Cardboard", (1.6, 1.4, 1.2), (-2, 0.4, 0.6), rot=(0, 0, rad(25)))
    box(p, "Tape", "Cloth", (2.42, 0.3, 0.05), (0, 0, 1.81), rot=(0, 0, rad(6)))


def locker(p):
    box(p, "Body", "Teal", (2, 1.8, 6.5), (0, 0, 3.25), bevel=0.06)
    box(p, "Gap", "Dark", (0.06, 1.82, 6.2), (0, 0, 3.25))
    for x in (-0.5, 0.5):
        for z in (5.6, 5.9):
            box(p, f"Vent{x}{z}", "Dark", (0.7, 0.05, 0.08), (x, -0.92, z))
    box(p, "Dent", "Rust", (0.8, 0.05, 1), (0.5, -0.91, 2.2))


def rebar_slab(p):
    box(p, "Slab", "Concrete", (10, 7, 1.2), (0, 0, 2.2), rot=(rad(-14), rad(8), 0), bevel=0.1)
    box(p, "Chunk", "Concrete", (3, 2.5, 1.6), (3.6, -3.4, 0.8), rot=(rad(20), rad(-15), rad(30)), bevel=0.1)
    box(p, "Chunk2", "Concrete", (2, 2, 1.2), (-4, 3.2, 0.6), rot=(rad(-10), rad(25), rad(10)), bevel=0.1)
    for i in range(7):
        cylinder(
            p,
            f"Rebar{i}",
            "Rust",
            0.08,
            rng.uniform(2.5, 4.5),
            (rng.uniform(-4, 4), rng.uniform(-3, 3), rng.uniform(2.5, 3.6)),
            rot=(rad(rng.uniform(-60, 60)), rad(rng.uniform(-60, 60)), 0),
            vertices=5,
        )
    box(p, "Moss", "Moss", (5, 3, 0.15), (-1.5, 1, 3.0), rot=(rad(-14), rad(8), 0))


def ceiling_panel(p):
    # A ceiling tile hanging down on one corner, with loose cables.
    box(p, "Tile", "White", (6, 4, 0.2), (0, 0, 0), rot=(rad(35), rad(10), 0))
    for i in range(3):
        cylinder(p, f"Wire{i}", "Dark", 0.05, 3, (-2 + i * 1.6, 1.4, 0.8), rot=(rad(rng.uniform(-20, 20)), 0, 0), vertices=4)


PROPS = [
    ("Sofa", sofa),
    ("Bed", bed),
    ("Mattress", mattress),
    ("Fridge", fridge),
    ("Counter", counter),
    ("Table", table),
    ("Chair", chair),
    ("Desk", desk),
    ("Shelf", shelf),
    ("Boiler", boiler),
    ("Cabinet", cabinet),
    ("PipeWall", pipe_wall),
    ("VentDuct", vent_duct),
    ("Barrel", barrel),
    ("Boxes", boxes),
    ("Locker", locker),
    ("RebarSlab", rebar_slab),
    ("CeilingPanel", ceiling_panel),
]


def main():
    reset_scene()
    columns = 6
    for i, (name, build) in enumerate(PROPS):
        build(new_prop(name, (i % columns) * 14, -(i // columns) * 14))
    apply_modifiers()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "blender", "InteriorProps.blend"))
    render_preview(os.path.join(ROOT, "assets", "previews", "InteriorProps.png"), (35, -14, 2), 96, 110)
    export_fbx(os.path.join(ROOT, "assets", "models", "InteriorProps.fbx"))
    faces = sum(len(o.data.polygons) for o in bpy.data.objects if o.type == "MESH")
    print(f"[InteriorProps] exported {len(PROPS)} props, {faces} faces")


main()
