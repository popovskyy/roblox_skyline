# Inventory icons for Skyline Zero: each item is modelled small and rendered on a transparent
# 256x256 PNG in a 3/4 view, so the hotbar shows real pictures instead of emoji.
#
#   blender --background --factory-startup --python blender/build_icons.py
#
# Output: assets/icons/<ItemId>.png

import math
import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402
from sz_blender import PAINTS, ROOT, box, cylinder, new_prop, rad, reset_scene  # noqa: E402

OUT = os.path.join(ROOT, "assets", "icons")
os.makedirs(OUT, exist_ok=True)
ALONG_Y = (rad(90), 0, 0)


def scrap(p):
    box(p, "Plate", "Rust", (1.6, 1.2, 0.12), (0, 0, 0.1), rot=(0, 0, rad(20)))
    box(p, "Plate2", "Metal", (1.2, 0.8, 0.1), (0.3, 0.2, 0.25), rot=(rad(8), rad(-6), rad(-25)))
    cylinder(p, "Bolt", "Metal", 0.12, 0.8, (-0.4, -0.2, 0.45), rot=(rad(70), 0, rad(30)), vertices=6)
    cylinder(p, "Nut", "Dark", 0.2, 0.12, (0.5, -0.4, 0.35), vertices=6)
    box(p, "Bar", "Rust", (0.15, 1.4, 0.15), (-0.2, 0.4, 0.4), rot=(0, rad(10), rad(60)))


def electronics(p):
    box(p, "Board", "Teal", (1.6, 1.1, 0.08), (0, 0, 0.1))
    box(p, "Chip", "Dark", (0.5, 0.4, 0.12), (-0.3, 0.1, 0.2))
    box(p, "Chip2", "Dark", (0.3, 0.3, 0.1), (0.4, -0.2, 0.18))
    cylinder(p, "Cap", "Yellow", 0.1, 0.35, (0.45, 0.3, 0.3), vertices=8)
    cylinder(p, "Cap2", "Glass", 0.08, 0.25, (0.2, 0.35, 0.25), vertices=8)
    box(p, "Led", "Glow", (0.1, 0.1, 0.1), (-0.6, -0.35, 0.2))


def food(p):
    cylinder(p, "Can", "Red", 0.5, 1.1, (0, 0, 0.55), vertices=16)
    cylinder(p, "Label", "White", 0.51, 0.5, (0, 0, 0.55), vertices=16)
    cylinder(p, "Lid", "Metal", 0.48, 0.05, (0, 0, 1.12), vertices=16)


def medkit(p):
    box(p, "Case", "White", (1.4, 1.0, 0.7), (0, 0, 0.35), bevel=0.08)
    box(p, "CrossA", "Red", (0.6, 0.18, 0.02), (0, -0.51, 0.38))
    box(p, "CrossB", "Red", (0.18, 0.02, 0.5), (0, -0.51, 0.38))
    box(p, "Handle", "Dark", (0.6, 0.15, 0.12), (0, 0, 0.76))


def bandage(p):
    cylinder(p, "Roll", "Cloth", 0.45, 0.5, (0, 0, 0.45), rot=ALONG_Y, vertices=16)
    cylinder(p, "Core", "White", 0.18, 0.52, (0, 0, 0.45), rot=ALONG_Y, vertices=12)
    box(p, "Tail", "Cloth", (0.45, 0.02, 0.9), (0, -0.46, 0.0), rot=(rad(-20), 0, 0))


def cable(p):
    for i in range(4):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.55, minor_radius=0.08, location=(0, 0, 0.12 + i * 0.12))
        from sz_blender import finish

        finish(bpy.context.active_object, p, f"Loop{i}", "Dark")
    cylinder(p, "Plug", "Yellow", 0.1, 0.4, (0.6, -0.1, 0.55), rot=(0, rad(80), 0), vertices=8)


def motor(p):
    cylinder(p, "Body", "Metal", 0.5, 1.0, (0, 0, 0.55), rot=ALONG_Y, vertices=14)
    for y in (-0.3, -0.1, 0.1, 0.3):
        cylinder(p, f"Fin{y}", "Dark", 0.55, 0.06, (0, y, 0.55), rot=ALONG_Y, vertices=14)
    cylinder(p, "Shaft", "Yellow", 0.08, 0.5, (0, -0.7, 0.55), rot=ALONG_Y, vertices=8)
    box(p, "Base", "Dark", (0.9, 1.0, 0.12), (0, 0, 0.06))


def crowbar(p):
    box(p, "Bar", "Red", (0.12, 2.2, 0.12), (0, 0, 0.3), rot=(0, 0, rad(35)))
    box(p, "Hook", "Red", (0.12, 0.5, 0.12), (0.75, 0.95, 0.42), rot=(rad(50), 0, rad(35)))
    box(p, "Claw", "Metal", (0.14, 0.3, 0.1), (-0.65, -0.95, 0.3), rot=(rad(-20), 0, rad(35)))


def flashlight(p):
    cylinder(p, "Body", "Yellow", 0.2, 1.3, (0, 0, 0.3), rot=ALONG_Y, vertices=12)
    cylinder(p, "Head", "Dark", 0.32, 0.4, (0, -0.75, 0.3), rot=ALONG_Y, vertices=12)
    cylinder(p, "Lens", "Glow", 0.28, 0.05, (0, -0.96, 0.3), rot=ALONG_Y, vertices=12)
    box(p, "Button", "Dark", (0.12, 0.2, 0.08), (0, 0.1, 0.52))


def club(p):
    cylinder(p, "Handle", "Cloth", 0.09, 0.8, (0, 0.4, 0), rot=ALONG_Y, vertices=8)
    cylinder(p, "Barrel", "Wood", 0.18, 1.4, (0, 1.5, 0), rot=ALONG_Y, vertices=10)
    for i, (x, z, y) in enumerate(((0.22, 0, 1.4), (-0.22, 0, 1.7), (0, 0.22, 1.9))):
        cylinder(p, f"Nail{i}", "Metal", 0.025, 0.25, (x, y, z), rot=(0, rad(90), 0) if z == 0 else (0, 0, 0), vertices=4)


def pipe(p):
    cylinder(p, "Tube", "Rust", 0.11, 2.2, (0, 1.1, 0), rot=ALONG_Y, vertices=10)
    cylinder(p, "Tape", "Cloth", 0.13, 0.6, (0, 0.3, 0), rot=ALONG_Y, vertices=10)
    box(p, "Elbow", "Metal", (0.3, 0.32, 0.3), (0, 2.25, 0))


def machete(p):
    box(p, "Handle", "Dark", (0.16, 0.7, 0.24), (0, 0.35, 0))
    box(p, "Guard", "Metal", (0.22, 0.08, 0.4), (0, 0.72, 0))
    box(p, "Blade", "Metal", (0.04, 1.7, 0.4), (0, 1.6, 0.04))
    box(p, "Edge", "White", (0.05, 1.7, 0.06), (0, 1.6, -0.17))


ITEMS = {
    "Scrap": scrap,
    "Electronics": electronics,
    "Food": food,
    "Medkit": medkit,
    "Bandage": bandage,
    "Cable": cable,
    "Motor": motor,
    "Crowbar": crowbar,
    "Flashlight": flashlight,
    "Club": club,
    "Pipe": pipe,
    "Machete": machete,
}


def setup_scene():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items.keys() else "BLENDER_EEVEE"
    scene.render.resolution_x = 256
    scene.render.resolution_y = 256
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    world = bpy.data.worlds.new("World")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.6, 0.6, 0.6, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.6
    scene.world = world
    for mat in bpy.data.materials:
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        paint = mat.name[2:]
        if bsdf and paint in PAINTS:
            r, g, b = PAINTS[paint]
            bsdf.inputs["Base Color"].default_value = (r, g, b, 1)
            bsdf.inputs["Roughness"].default_value = 0.55
            if paint == "Metal":
                bsdf.inputs["Metallic"].default_value = 0.6
            if paint == "Glow":
                bsdf.inputs["Emission Color"].default_value = (1, 0.8, 0.4, 1)
                bsdf.inputs["Emission Strength"].default_value = 4
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 4
    sun_obj = bpy.data.objects.new("Sun", sun)
    sun_obj.rotation_euler = (rad(50), rad(10), rad(30))
    scene.collection.objects.link(sun_obj)
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def frame(cam, prop):
    # Fit the orthographic camera around the prop's bounding box, seen from the front-right and above.
    points = []
    for obj in prop.children:
        for corner in obj.bound_box:
            points.append(obj.matrix_world @ Vector(corner))
    lo = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    hi = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    center = (lo + hi) / 2
    size = (hi - lo).length
    cam.data.ortho_scale = size * 1.05
    direction = Vector((1, -1.2, 1)).normalized()
    cam.location = center + direction * size * 3
    cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()


def main():
    reset_scene()
    props = {}
    for name, build in ITEMS.items():
        prop = new_prop("Icon_" + name)
        build(prop)
        props[name] = prop
    bpy.context.view_layer.update()
    cam = setup_scene()
    for name, prop in props.items():
        for other in props.values():
            hidden = other is not prop
            other.hide_render = hidden
            for child in other.children:
                child.hide_render = hidden
        frame(cam, prop)
        bpy.context.scene.render.filepath = os.path.join(OUT, name + ".png")
        bpy.ops.render.render(write_still=True)
    print("[Icons] rendered", len(props))


main()
