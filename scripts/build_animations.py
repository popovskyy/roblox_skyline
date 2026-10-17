# Writes the R15 weapon animations as Rojo KeyframeSequence models, builds them to .rbxm and
# (with --upload) uploads them to Roblox as Animation assets through Open Cloud.
#
#   python scripts/build_animations.py            # build assets/animations/*.rbxm
#   python scripts/build_animations.py --upload   # build and upload, prints the asset ids
#
# Angles are degrees in joint space, applied like CFrame.Angles(x, y, z). The character faces -Z:
# +X on a shoulder raises the arm forward, -Y on the waist turns the chest to the right.

import json
import math
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "animations")
SCRATCH = os.environ.get("TEMP", "/tmp")

# Joint tree of the poses we touch (parent -> children). Untouched branches (legs, head) are left
# out so walking keeps animating the legs.
TREE = {
    "HumanoidRootPart": ["LowerTorso"],
    "LowerTorso": ["UpperTorso"],
    "UpperTorso": ["RightUpperArm", "LeftUpperArm"],
    "RightUpperArm": ["RightLowerArm"],
    "RightLowerArm": ["RightHand"],
    "LeftUpperArm": ["LeftLowerArm"],
    "LeftLowerArm": ["LeftHand"],
    "RightHand": [],
    "LeftHand": [],
}

# Ready stance: bat resting up over the right shoulder, left hand near the chest.
HOLD = {
    "UpperTorso": (0, -8, 0),
    "RightUpperArm": (35, 0, 12),
    "RightLowerArm": (75, 0, 0),
    "RightHand": (-10, 0, 0),
    "LeftUpperArm": (30, 0, -20),
    "LeftLowerArm": (55, 0, 0),
    "LeftHand": (0, 0, 0),
}

# Overhand diagonal smash: wind up behind the right shoulder, chop forward-down to the left, recover.
WINDUP = {
    "UpperTorso": (5, -35, 0),
    "RightUpperArm": (120, 20, 35),
    "RightLowerArm": (60, 0, 0),
    "RightHand": (20, 0, 0),
    "LeftUpperArm": (60, 0, -10),
    "LeftLowerArm": (40, 0, 0),
    "LeftHand": (0, 0, 0),
}
STRIKE = {
    "UpperTorso": (-12, 35, 0),
    "RightUpperArm": (70, 45, -10),
    "RightLowerArm": (5, 0, 0),
    "RightHand": (-75, 0, 0),
    "LeftUpperArm": (20, 0, -25),
    "LeftLowerArm": (20, 0, 0),
    "LeftHand": (0, 0, 0),
}
FOLLOW = {
    "UpperTorso": (-8, 25, 0),
    "RightUpperArm": (45, 40, -5),
    "RightLowerArm": (20, 0, 0),
    "RightHand": (-60, 0, 0),
    "LeftUpperArm": (25, 0, -25),
    "LeftLowerArm": (35, 0, 0),
    "LeftHand": (0, 0, 0),
}

# Holding a small item (food, medkit...): forearm up in front of the chest.
CARRY = {
    "RightUpperArm": (20, 0, 5),
    "RightLowerArm": (70, 0, 0),
    "RightHand": (0, 0, 0),
}
# Using it: hand lifts to the face and back.
USE_UP = {
    "UpperTorso": (8, 0, 0),
    "RightUpperArm": (45, 25, 0),
    "RightLowerArm": (110, 0, 0),
    "RightHand": (0, 0, 0),
}

ANIMATIONS = {
    "WeaponHold": {"loop": True, "priority": "Action", "keys": [(0, HOLD), (1, HOLD)]},
    "WeaponSwing": {
        "loop": False,
        "priority": "Action2",
        "keys": [(0, HOLD), (0.14, WINDUP), (0.26, STRIKE), (0.36, FOLLOW), (0.6, HOLD)],
    },
    "ItemHold": {"loop": True, "priority": "Action", "keys": [(0, CARRY), (1, CARRY)]},
    "ItemUse": {"loop": False, "priority": "Action2", "keys": [(0, CARRY), (0.25, USE_UP), (0.7, USE_UP), (0.95, CARRY)]},
}


def rotation(x, y, z):
    # Row-major matrix of CFrame.Angles(x, y, z) = Rx * Ry * Rz.
    x, y, z = math.radians(x), math.radians(y), math.radians(z)
    cx, sx, cy, sy, cz, sz = math.cos(x), math.sin(x), math.cos(y), math.sin(y), math.cos(z), math.sin(z)
    rx = [[1, 0, 0], [0, cx, -sx], [0, sx, cx]]
    ry = [[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]
    rz = [[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]]

    def mul(a, b):
        return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]

    return [[round(v, 6) for v in row] for row in mul(mul(rx, ry), rz)]


def pose(name, angles):
    props = {"Weight": 1 if name in angles else 0}
    if name in angles:
        props["CFrame"] = {"CFrame": {"position": [0, 0, 0], "orientation": rotation(*angles[name])}}
    children = [pose(child, angles) for child in TREE[name] if subtree_used(child, angles)]
    return {"name": name, "className": "Pose", "properties": props, "children": children}


def subtree_used(name, angles):
    return name in angles or any(subtree_used(child, angles) for child in TREE[name])


def sequence(spec):
    return {
        "className": "KeyframeSequence",
        "properties": {"Loop": spec["loop"], "Priority": spec["priority"]},
        "children": [
            {
                "name": f"K{i}",
                "className": "Keyframe",
                "properties": {"Time": t},
                "children": [pose("HumanoidRootPart", angles)],
            }
            for i, (t, angles) in enumerate(spec["keys"])
        ],
    }


def build(name, spec):
    model = os.path.join(OUT, name + ".model.json")
    with open(model, "w") as f:
        json.dump(sequence(spec), f, indent=1)
    project = os.path.join(SCRATCH, f"sz_anim_{name}.project.json")
    with open(project, "w") as f:
        json.dump({"name": name, "tree": {"$path": model.replace("\\", "/")}}, f)
    rbxm = os.path.join(OUT, name + ".rbxm")
    subprocess.run(["rojo", "build", project, "-o", rbxm], check=True, capture_output=True)
    return rbxm


def upload(name, rbxm):
    key = open(os.path.join(ROOT, ".roblox_api_key")).read().strip()
    request = json.dumps(
        {
            "assetType": "Animation",
            "displayName": "SZ_" + name,
            "description": "Skyline Zero",
            "creationContext": {"creator": {"userId": "8053736277"}},
        }
    )
    out = subprocess.run(
        ["curl", "-sS", "-m", "120", "-X", "POST", "https://apis.roblox.com/assets/v1/assets",
         "-H", "x-api-key: " + key, "-F", "request=" + request, "-F", f"fileContent=@{rbxm};type=model/x-rbxm"],
        check=True, capture_output=True, text=True,
    ).stdout
    operation = json.loads(out)["operationId"]
    for _ in range(30):
        time.sleep(3)
        out = subprocess.run(
            ["curl", "-sS", "-m", "30", "https://apis.roblox.com/assets/v1/operations/" + operation,
             "-H", "x-api-key: " + key],
            check=True, capture_output=True, text=True,
        ).stdout
        result = json.loads(out)
        if result.get("done"):
            return result["response"]["assetId"]
    raise RuntimeError("upload did not finish: " + operation)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, spec in ANIMATIONS.items():
        rbxm = build(name, spec)
        if "--upload" in sys.argv:
            print(name, upload(name, rbxm))
        else:
            print("built", rbxm)


main()
