# Shared helpers for Skyline Zero Blender scripts.
# Every prop is an empty named after the prop holding meshes named "<Prop>_<Part>_<Paint>".
# In Roblox the colour/material comes from <Paint> (PROP_PAINTS in WorldBuilder.luau).
# 1 Blender unit = 1 stud. Props stand on Z = 0, centred on X/Y, facing -Y.

import math
import os

import bpy
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Preview colours only.
PAINTS = {
    "Wood": (0.42, 0.27, 0.15),
    "Metal": (0.45, 0.47, 0.50),
    "Dark": (0.12, 0.13, 0.15),
    "Rust": (0.45, 0.22, 0.10),
    "Yellow": (0.85, 0.62, 0.10),
    "Glow": (1.0, 0.55, 0.15),
    "Teal": (0.20, 0.50, 0.55),
    "Red": (0.75, 0.12, 0.10),
    "Fabric": (0.30, 0.32, 0.22),
    "Cloth": (0.55, 0.50, 0.42),
    "White": (0.78, 0.76, 0.70),
    "Cardboard": (0.55, 0.42, 0.26),
    "Concrete": (0.48, 0.46, 0.42),
    "Moss": (0.28, 0.38, 0.16),
    "Glass": (0.45, 0.55, 0.55),
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


def new_prop(name, x_offset=0.0, y_offset=0.0):
    prop = bpy.data.objects.new(name, None)
    prop.empty_display_type = "PLAIN_AXES"
    prop.location = (x_offset, y_offset, 0)
    bpy.context.scene.collection.objects.link(prop)
    return prop


def apply_modifiers():
    for obj in bpy.data.objects:
        if obj.type == "MESH":
            bpy.context.view_layer.objects.active = obj
            for mod in list(obj.modifiers):
                bpy.ops.object.modifier_apply(modifier=mod.name)


def render_preview(path, center, ortho_scale, distance=40):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_shadows = True
    scene.render.resolution_x = 1800
    scene.render.resolution_y = 900
    world = bpy.data.worlds.new("World")
    world.color = (0.30, 0.28, 0.22)
    scene.world = world
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = ortho_scale
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    target = Vector(center)
    cam.location = target + Vector((distance * 0.55, -distance, distance * 0.6))
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam)


def export_fbx(path):
    # Props sit at their own offsets in the .blend; export them centred so the game can place them.
    for prop in [o for o in bpy.data.objects if o.type == "EMPTY"]:
        prop.location = (0, 0, 0)
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=False,
        object_types={"EMPTY", "MESH"},
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        mesh_smooth_type="FACE",
        bake_anim=False,
    )


def rad(deg):
    return math.radians(deg)
