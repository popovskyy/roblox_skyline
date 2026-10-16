# Builds the low-poly roof structures for Skyline Zero and exports them for Roblox.
#
# Run (no Blender UI needed):
#   blender --background --factory-startup --python blender/build_roof_props.py
#
# Output:
#   assets/models/RoofProps.fbx   import into Studio (File > Import 3D)
#   blender/RoofProps.blend       editable source
#
# Each prop is an empty named after its upgrade id (StorageCrate, Generator, AirFilter, Bridge)
# holding mesh parts named "<Prop>_<Paint>". The game colours every part from the <Paint>
# suffix (see PROP_PAINTS in WorldBuilder.luau), so no textures are needed.
# 1 Blender unit = 1 stud. Props stand on Z = 0, centred on X/Y.

import math
import os

import bpy
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "models")
os.makedirs(OUT_DIR, exist_ok=True)

# Preview colours only; in Roblox the colour comes from the paint name.
PAINTS = {
    "Wood": (0.42, 0.27, 0.15),
    "Metal": (0.45, 0.47, 0.50),
    "Dark": (0.12, 0.13, 0.15),
    "Rust": (0.45, 0.22, 0.10),
    "Yellow": (0.85, 0.62, 0.10),
    "Glow": (1.0, 0.55, 0.15),
    "Teal": (0.20, 0.50, 0.55),
    "Red": (0.75, 0.12, 0.10),
}


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material(paint):
    name = "M_" + paint
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        r, g, b = PAINTS[paint]
        mat.diffuse_color = (r, g, b, 1.0)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = (r, g, b, 1.0)
            bsdf.inputs["Roughness"].default_value = 0.8
            if paint == "Glow":
                bsdf.inputs["Emission Color"].default_value = (r, g, b, 1.0)
                bsdf.inputs["Emission Strength"].default_value = 3.0
    return mat


def finish(obj, prop, part, paint, bevel=0.0):
    obj.name = f"{prop.name}_{part}_{paint}"
    obj.data.name = obj.name
    obj.data.materials.append(material(paint))
    if bevel > 0:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        mod.limit_method = "ANGLE"
    obj.parent = prop
    return obj


def box(prop, part, paint, size, loc, rot=(0, 0, 0), bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    obj = bpy.context.active_object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, prop, part, paint, bevel)


def cylinder(prop, part, paint, radius, depth, loc, rot=(0, 0, 0), vertices=12, bevel=0.0):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rot)
    return finish(bpy.context.active_object, prop, part, paint, bevel)


def new_prop(name, x_offset):
    prop = bpy.data.objects.new(name, None)
    prop.empty_display_type = "PLAIN_AXES"
    prop.location = (x_offset, 0, 0)
    bpy.context.scene.collection.objects.link(prop)
    return prop


# Coordinates below are local to the prop (the empty sits at the prop's base centre).
def storage_crate(prop):
    # 6 x 4 x 4 footprint: plank body, steel bands, lid, padlock.
    box(prop, "Body", "Wood", (6, 4, 3.4), (0, 0, 1.7), bevel=0.08)
    box(prop, "Lid", "Wood", (6.2, 4.2, 0.5), (0, 0, 3.65), bevel=0.08)
    for x in (-2.4, 0, 2.4):
        box(prop, f"Band{x}", "Metal", (0.35, 4.15, 3.5), (x, 0, 1.75))
    for z in (0.5, 2.9):
        box(prop, f"Rim{z}", "Metal", (6.1, 4.1, 0.25), (0, 0, z))
    box(prop, "Lock", "Yellow", (0.7, 0.3, 0.8), (0, -2.15, 2.9), bevel=0.05)
    # Plank grooves on the long sides.
    for z in (1.1, 2.3):
        for y in (-2.02, 2.02):
            box(prop, f"Groove{z}{y}", "Dark", (5.6, 0.05, 0.08), (0, y, z))


def generator(prop):
    # 6 x 4 x 5: skid frame, engine block, fuel tank, exhaust, control panel.
    box(prop, "Skid", "Dark", (6, 4, 0.5), (0, 0, 0.25), bevel=0.05)
    for y in (-1.6, 1.6):
        box(prop, f"Rail{y}", "Metal", (6.2, 0.35, 0.35), (0, y, 0.6))
    box(prop, "Engine", "Yellow", (3.6, 3, 2.4), (-0.6, 0, 1.7), bevel=0.15)
    for i in range(6):
        box(prop, f"Fin{i}", "Dark", (0.12, 3.05, 1.8), (-2.0 + i * 0.5, 0, 1.7))
    cylinder(prop, "Tank", "Red", 0.9, 3.4, (-0.6, 0, 3.6), rot=(math.pi / 2, 0, 0), vertices=14, bevel=0.05)
    box(prop, "Panel", "Metal", (1.6, 2.6, 2.6), (2.0, 0, 1.8), bevel=0.08)
    box(prop, "Screen", "Glow", (0.05, 1.2, 0.6), (2.82, 0, 2.4))
    for i, y in enumerate((-0.6, 0, 0.6)):
        cylinder(prop, f"Knob{i}", "Dark", 0.14, 0.15, (2.85, y, 1.6), rot=(0, math.pi / 2, 0), vertices=8)
    cylinder(prop, "Exhaust", "Rust", 0.22, 2.0, (-2.2, -1.1, 3.6), vertices=10)
    cylinder(prop, "ExhaustCap", "Dark", 0.3, 0.2, (-2.2, -1.1, 4.65), vertices=10)


def air_filter(prop):
    # 4 x 4 x 7: concrete base, filter column with intake rings, fan housing on top.
    box(prop, "Base", "Dark", (4, 4, 0.6), (0, 0, 0.3), bevel=0.08)
    cylinder(prop, "Column", "Teal", 1.4, 4.2, (0, 0, 2.7), vertices=16, bevel=0.04)
    for i in range(4):
        cylinder(prop, f"Ring{i}", "Metal", 1.55, 0.18, (0, 0, 1.2 + i * 1.05), vertices=16)
    cylinder(prop, "FanHousing", "Metal", 1.9, 1.0, (0, 0, 5.3), vertices=16, bevel=0.06)
    cylinder(prop, "FanGrille", "Dark", 1.6, 0.1, (0, 0, 5.85), vertices=16)
    for i in range(4):
        angle = i * math.pi / 4
        box(prop, f"Blade{i}", "Metal", (2.9, 0.35, 0.06), (0, 0, 5.92), rot=(0, 0, angle))
    cylinder(prop, "Hub", "Yellow", 0.3, 0.2, (0, 0, 6.0), vertices=10)
    box(prop, "Gauge", "Glow", (0.05, 0.5, 0.5), (1.42, 0, 2.6))
    cylinder(prop, "Pipe", "Rust", 0.25, 2.5, (1.6, 1.6, 1.3), vertices=8)


def bridge_console(prop):
    # 3 x 3 x 3: winch pedestal with an angled panel and a big lever.
    box(prop, "Pedestal", "Metal", (2.2, 2.2, 2.0), (0, 0, 1.0), bevel=0.1)
    box(prop, "Panel", "Dark", (2.6, 1.6, 0.25), (0, -0.2, 2.25), rot=(math.radians(-25), 0, 0), bevel=0.05)
    box(prop, "PanelScreen", "Glow", (1.4, 0.8, 0.05), (0, -0.25, 2.4), rot=(math.radians(-25), 0, 0))
    cylinder(prop, "Drum", "Rust", 0.55, 2.4, (0, 0.9, 1.4), rot=(0, math.pi / 2, 0), vertices=12)
    box(prop, "Lever", "Metal", (0.15, 0.15, 1.3), (0.9, -0.5, 2.9), rot=(math.radians(20), 0, 0))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.22, location=(0.9, -0.72, 3.5))
    finish(bpy.context.active_object, prop, "Knob", "Red")


def render_preview(path):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_shadows = True
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 700
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("World")
    world.color = (0.35, 0.2, 0.12)
    scene.world = world
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 46
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = Vector((15, -30, 16))
    direction = Vector((15, 0, 2.5)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam)


def main():
    reset_scene()
    builders = [
        ("StorageCrate", storage_crate),
        ("Generator", generator),
        ("AirFilter", air_filter),
        ("Bridge", bridge_console),
    ]
    for i, (name, build) in enumerate(builders):
        build(new_prop(name, i * 10))

    # Apply bevels so the exported meshes match the preview.
    for obj in bpy.data.objects:
        if obj.type == "MESH":
            bpy.context.view_layer.objects.active = obj
            for mod in list(obj.modifiers):
                bpy.ops.object.modifier_apply(modifier=mod.name)

    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "blender", "RoofProps.blend"))
    render_preview(os.path.join(ROOT, "assets", "previews", "RoofProps.png"))

    # Each prop sits at its own X offset in the .blend; export them centred so the game can place them.
    for prop in [o for o in bpy.data.objects if o.type == "EMPTY"]:
        prop.location = (0, 0, 0)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(OUT_DIR, "RoofProps.fbx"),
        use_selection=False,
        object_types={"EMPTY", "MESH"},
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        bake_anim=False,
    )
    tris = sum(len(o.data.polygons) for o in bpy.data.objects if o.type == "MESH")
    print(f"[RoofProps] exported {len(builders)} props, {tris} faces total")


main()
