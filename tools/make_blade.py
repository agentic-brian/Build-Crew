"""Build the skid steer's PUSH BLADE (DESIGN 2c).

Run (from the project folder):
  blender.exe --background --python tools/make_blade.py -- \
      --out-dir assets/models/props [--preview DIR]

The user, 2026-09-14: "skid steer bucket should be more like a bulldozer push
blade". A loader bucket SCOOPS - it is the wrong tool for shoving nine metres
of broken slab down a drive - and a skid steer with a dozer-blade attachment
is a real thing a real crew bolts on for exactly this. So this is that
attachment: a concave mouldboard, wider than the machine, a bolt-on cutting
edge, ribs down its back and the push frame that hangs it off the quick-attach
plate.

It is authored in the BUCKET'S OWN FRAME: the origin is the fleet SkidSteer's
bucket pin (`Bucket`, 0.74 m up and 1.24 m forward of the machine's origin),
+Z forward, so the game parents this GLB under that pivot, hides the bucket's
own meshes, and every lift and tilt the machine already knows about carries
the blade instead. The cutting edge is put exactly where the bucket's was
(0.04 below and 0.52 ahead of the pin), so `arm_down_deg` still lands it on
the dirt with no retuning; `BladeEdge` marks it, and `Machine.bucket_edge_world`
reads that marker when a blade is fitted.

Nodes: Blade (one mesh), markers BladeEdge (the middle of the cutting edge,
+Z forward) and Mount (the pin).
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
import equip_lib as L  # noqa: E402
import fleet_lib as F  # noqa: E402
from equip_lib import (Machine, V, X, Y, Z, add_box, add_box_between, add_tube, log)  # noqa: E402
from fleet_lib import add_shell, part  # noqa: E402
from mathutils import Vector  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def arg(name, default=None):
    return argv[argv.index(name) + 1] if name in argv else default


OUT_DIR = arg("--out-dir", "assets/models/props")
PREVIEW = arg("--preview")
RAD = math.radians
COS = math.cos
SIN = math.sin
SINK = 0.003

# Where the bucket's cutting edge sits in the pin's frame (machine_probe:
# BucketTip local (0, -0.04, 0.52)). The blade's edge goes exactly there.
EDGE = V(0.0, -0.04, 0.52)
# The mouldboard: one arc concave FORWARD (its centre of curvature is ahead of
# the blade), from the cutting edge at the bottom up to the top lip.
WIDE = 2.04
ARC_C = V(0.0, 0.28, 1.20)
ARC_R = 0.75
A_LIP = 245.0
A_TOP = 302.0
THICK = 0.075

CONTRACT = ["Blade", "BladeEdge", "Mount"]
VIEWS = {"hero": (1.30, 0.55, 1.35), "work": (-1.1, 0.35, 1.1)}


def on_arc(deg, r=ARC_R):
    return ARC_C + V(0.0, COS(RAD(deg)), SIN(RAD(deg))) * r


def build_blade():
    F.reset_stats()
    # The edge hangs 4 cm under the pin, on purpose.
    F.allow_below(0.20)
    m = Machine("PushBlade")
    B = "Blade"
    # The mouldboard.
    bm, fin = part(m, B, "Board", "Machine")
    add_shell(bm, ARC_C, X, Y, Z, ARC_R - THICK, ARC_R, RAD(A_LIP), RAD(A_TOP), 8, WIDE)
    fin()
    # A top lip folded back, so the blade has a top edge you can read.
    top = on_arc(A_TOP, ARC_R - THICK * 0.5)
    bm, fin = part(m, B, "TopLip", "Machine", bevel=0.006)
    add_box(bm, top + V(0.0, 0.02, -0.05), (WIDE + 0.02, 0.05, 0.16))
    fin()
    # The cutting edge: a straight bolt-on strip along the lip, polished.
    lip = on_arc(A_LIP, ARC_R - THICK * 0.5)
    u = V(0.0, COS(RAD(A_LIP)), SIN(RAD(A_LIP)))
    t = V(0.0, -SIN(RAD(A_LIP)), COS(RAD(A_LIP)))
    bm, fin = part(m, B, "Edge", "Wear")
    add_box(bm, lip + u * 0.028, (WIDE + 0.03, 0.10, THICK + 0.05), axes=(X, u, t))
    fin()
    # Ribs down the back of the board, and the two end plates.
    bm, fin = part(m, B, "Ribs", "Engine")
    for sx in (-0.36, -0.12, 0.12, 0.36):
        for deg in range(int(A_LIP) + 8, int(A_TOP) - 6, 9):
            p = on_arc(deg, ARC_R + 0.028)
            add_box(bm, p + X * (sx * WIDE), (0.09, 0.12, 0.09))
    fin()
    bm, fin = part(m, B, "EndPlates", "Engine")
    for sx in (-1.0, 1.0):
        F.add_sector(bm, ARC_C + X * (sx * (WIDE * 0.5 + 0.02)), X, Y, Z,
                     ARC_R + 0.01, RAD(A_LIP), RAD(A_TOP), 8, 0.04,
                     r_in=ARC_R - THICK - 0.01)
    fin()
    # The push frame: a quick-attach plate on the pin and two arms out to the
    # back of the board.
    bm, fin = part(m, B, "Plate", "Engine", bevel=0.006)
    add_box(bm, V(0.0, 0.16, 0.06), (1.26, 0.46, 0.07))
    fin()
    back = on_arc(275.0, ARC_R + 0.06)
    bm, fin = part(m, B, "Arms", "Engine", bevel=0.006)
    for sx in (-0.42, 0.42):
        add_box_between(bm, V(sx, 0.18, 0.10), V(sx, back.y, back.z - 0.02), 0.14, 0.16)
    add_tube(bm, V(-0.50, 0.18, 0.10), V(0.50, 0.18, 0.10), 0.05, 8)
    fin()
    bm, fin = part(m, B, "Pins", "Hub")
    for sx in (-1.0, 1.0):
        add_tube(bm, V(sx * 0.52, 0.0, 0.0), V(sx * 0.66, 0.0, 0.0), 0.05, 8)
    fin()
    m.mesh_node(B)
    m.empty("BladeEdge", lip + u * 0.05, zdir=(0, 0, 1), xhint=(1, 0, 0))
    m.empty("Mount", V(0.0, 0.0, 0.0), zdir=(0, 0, 1), xhint=(1, 0, 0))
    m.note("mouldboard %.2f wide, %.2f tall; edge at (%.2f, %.2f) in the pin's frame"
           % (WIDE, on_arc(A_TOP).y - on_arc(A_LIP).y, lip.y, lip.z))
    return m


def check(name, path):
    js = L.glb_json(path)
    have = [n.get("name", "?") for n in js.get("nodes", [])]
    missing = [w for w in CONTRACT if w not in have]
    log("%s: exported nodes %s" % (name, have))
    if missing:
        log("%s: MISSING CONTRACT NODES %s" % (name, missing))
        return False
    for n in js.get("nodes", []):
        if n.get("name") == "BladeEdge":
            t = n.get("translation", [0.0, 0.0, 0.0])
            log("%s: BladeEdge at (%.3f, %.3f, %.3f)" % (name, t[0], t[1], t[2]))
            ok = abs(t[1] - EDGE.y) < 0.06 and abs(t[2] - EDGE.z) < 0.06
            if not ok:
                log("%s: edge is NOT where the bucket's was (%s)" % (name, EDGE))
                return False
    return True


L.fresh_scene()
machine = build_blade()
out = os.path.join(OUT_DIR, "PushBlade.glb")
ok = machine.export(out, PREVIEW, views=VIEWS)
ok = check("PushBlade", out) and ok
below = F.ST["below"]
if below:
    log("PushBlade: parts below the floor %s" % below)
    ok = False
w, h, l = F.dims()
log("PushBlade: %.2f x %.2f x %.2f, %d tris, %s" % (w, h, l, machine.tris, "; ".join(machine.notes)))
print("PUSH_BLADE_OK" if ok else "PUSH_BLADE_FAIL")
