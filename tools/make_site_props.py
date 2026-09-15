"""Build Build Crew's hand tools (DESIGN 2).

Run (from the project folder):
  blender.exe --background --python tools/make_site_props.py -- \
      --out-dir assets/models/props [--preview DIR] [--only Jackhammer,Broom]

Uses the fleet's frozen `equip_lib` (copied into tools/ with the project), so
these tools stand beside the machines and the garage's props as one family:
authored in GODOT metres, Y up, faces +Z, flat-shaded, one material per part
off the shared palette.

Every tool here is held by the GAME rather than by a hand, so they all share
one frame, the same one Car Garage's hand tools use:

    the ORIGIN is the working face - the point that meets the concrete - and
    +Z points INTO the work, +Y is the tool's own up.

`HandTool.hover(point, into, up)` then puts any of them anywhere without a
per-tool offset, and a marker called `Tip` sits at the origin so a probe can
assert that is really where it is.

  Jackhammer   Body (the breaker and its handles), Bit (the moil point, slides
               along +Z as it hammers: its own node, re-centred at its home so
               the game can drive it), markers Tip, Grip
  Sledge       Body (the shaft), Head (the steel head), marker Tip
  ScreedBoard  Body: a 4.2 m 2x4 laid ACROSS the drive (its length along X, so
               it spans the forms), marker Tip at the middle of its bottom face
  Jointer      Body (the handle), Blade (the bit that cuts the groove: a
               rounded steel runner), marker Tip
  Broom        Body (the handle), Head (the brush block and its bristles),
               marker Tip at the middle of the bristle face
  ComeAlong    Body (the handle), Head (the flat steel blade a concrete rake
               pulls wet concrete with), marker Tip at the middle of the
               blade's bottom edge. Phase 6b: the concrete is PULLED up the
               form from where the chute lands it (DESIGN 2a).
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
import equip_lib as L  # noqa: E402
from equip_lib import (Machine, V, X, Y, Z, add_box, add_cone, add_tube, log)  # noqa: E402
from mathutils import Vector  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def arg(name, default=None):
    return argv[argv.index(name) + 1] if name in argv else default


OUT_DIR = arg("--out-dir", "assets/models/props")
PREVIEW = arg("--preview")
ONLY = [s for s in (arg("--only", "") or "").split(",") if s]

RAD = math.radians
# How far a thing standing on another sinks into it, so no two faces are ever
# exactly coplanar (the fleet's z-fight rule).
SINK = 0.003

# The palette additions this project needs. equip_lib is frozen, so they are
# added here exactly as the garage's own prop pass does it.
L.MATERIALS["Black"] = (0.08, 0.08, 0.09)
L.MATERIALS["Bristle"] = (0.18, 0.30, 0.62)
L.MATERIALS["Timber"] = (0.67, 0.48, 0.28)
L.MATERIALS["Wear"] = (0.72, 0.74, 0.78)     # the fleet's polished cutting edge
# A tool orange near DARK STEEL's value (the improvement plan's 4.4): the
# breaker's own safety orange ("Body") renders level with the slab - a hue step
# with no value step - so the groover's sled takes Brand.RUST darkened a step.
# Measured in session 4's JOINT frame: the sled renders 0.41 against the slab's
# 0.58, 29% under it (the grey sled was 0.38; round 13's failed pale steel, 9%).
L.MATERIALS["ToolOrange"] = (0.62, 0.27, 0.03)

# The contract each tool promises, asserted against the exported GLB below.
CONTRACT = {
    "Jackhammer": ["Body", "Bit", "Tip", "Grip"],
    "Sledge": ["Body", "Head", "Tip"],
    "ScreedBoard": ["Body", "Tip"],
    "Jointer": ["Body", "Blade", "Grip", "Tip"],
    "Broom": ["Body", "Head", "Tip"],
    "ComeAlong": ["Body", "Head", "Tip"],
}
# A three-quarter view for the previews, plus one straight down the working axis.
VIEWS = {"hero": (1.05, 0.52, 1.25), "work": (-0.9, 0.45, 0.85)}


# ==========================================================================
#  1. JACKHAMMER - phase 1. Origin at the moil point's tip, +Z into the slab.
# ==========================================================================
def build_jackhammer():
    """A pneumatic breaker: a steel moil point at the origin, a chuck, the
    cylinder above it, two handles out either side and a hose stub. `Bit` is
    its own node so the game can stroke it along +Z while it hammers."""
    m = Machine("Jackhammer")
    # The point. Its own node, re-centred at the chuck end so the stroke the
    # game drives is a SLIDE down its own axis rather than a scale about a
    # point halfway up it.
    bm, fin = m.part("Bit", "Point", "Metal")
    add_cone(bm, V(0.0, 0.0, -0.055), Z, 0.014, 0.004, 0.110, 8)
    fin()
    m.mesh_node("Bit", center=V(0.0, 0.0, -0.110))
    B = "Body"
    bm, fin = m.part(B, "Chuck", "Hub", bevel=0.003)
    add_cone(bm, V(0.0, 0.0, -0.110 - SINK - 0.038), Z, 0.034, 0.030, 0.076, 10)
    fin()
    bm, fin = m.part(B, "Cylinder", "Body", bevel=0.006)
    add_cone(bm, V(0.0, 0.0, -0.186 - SINK - 0.150), Z, 0.052, 0.048, 0.300, 12)
    fin()
    bm, fin = m.part(B, "Cap", "Engine", bevel=0.004)
    add_cone(bm, V(0.0, 0.0, -0.486 - SINK - 0.030), Z, 0.050, 0.044, 0.060, 12)
    fin()
    # The two handles: out along X, angled back so they read as something held.
    bm, fin = m.part(B, "Handles", "Engine", bevel=0.004)
    for sx in (-1.0, 1.0):
        add_tube(bm, V(sx * 0.040, 0.0, -0.440), V(sx * 0.175, 0.0, -0.470), 0.017, 8)
        add_box(bm, V(sx * 0.150, 0.0, -0.464), (0.090, 0.034, 0.034))
    fin()
    bm, fin = m.part(B, "Hose", "Black")
    add_tube(bm, V(0.0, -0.046, -0.300), V(0.0, -0.070, -0.480), 0.012, 6)
    fin()
    m.mesh_node(B)
    m.empty("Tip", V(0.0, 0.0, 0.0), zdir=(0, 0, 1), xhint=(1, 0, 0))
    m.empty("Grip", V(0.0, 0.0, -0.464), zdir=(0, 0, 1), xhint=(1, 0, 0))
    m.note("breaker 0.55 long, bit 0.11 strokes along +Z; origin at the point")
    return m


# ==========================================================================
#  2. SLEDGE - phase 4, driving the form stakes.
# ==========================================================================
def build_sledge():
    """A short sledge: a steel head at the origin with a hickory shaft going
    back and up. Origin at the striking face, +Z into the stake's head."""
    m = Machine("Sledge")
    # A dark steel head, wider than the stake it drives, with a bright chamfer
    # on the striking face; the handle enters the head's SIDE, the way a sledge
    # is made (round 5: it was a mallet on a stick, one grey column with the
    # peg).
    # A rectangular BLOCK, its long axis the strike axis, chamfered faces at
    # both ends: a cylinder face-on read as a tin can (round 6).
    bm, fin = m.part("Head", "Steel", "Engine", bevel=0.006)
    add_box(bm, V(0.0, 0.0, -0.088), (0.080, 0.080, 0.150))
    fin()
    bm, fin = m.part("Head", "Faces", "Wear", bevel=0.004)
    add_box(bm, V(0.0, 0.0, -0.009), (0.084, 0.084, 0.018))
    add_box(bm, V(0.0, 0.0, -0.167), (0.084, 0.084, 0.018))
    fin()
    m.mesh_node("Head")
    B = "Body"
    bm, fin = m.part(B, "Shaft", "Timber", bevel=0.003)
    add_tube(bm, V(0.0, 0.040, -0.080), V(0.0, 0.62, -0.260), 0.019, 8)
    fin()
    bm, fin = m.part(B, "Wedge", "Metal")
    add_box(bm, V(0.0, 0.052, -0.080), (0.036, 0.012, 0.036))
    fin()
    m.mesh_node(B)
    m.empty("Tip", V(0.0, 0.0, 0.0), zdir=(0, 0, 1), xhint=(1, 0, 0))
    m.note("head r 0.05 x 0.16, handle through its side, 0.6 long; origin at the striking face")
    return m


# ==========================================================================
#  3. SCREED BOARD - phase 8. Origin at the middle of its bottom face.
# ==========================================================================
def build_screed_board():
    """A 4.2 m 2x4 with a handle at each end, laid ACROSS the drive so it
    spans both forms. Its length runs along X; the origin is the middle of
    the edge that rides on the concrete, +Z the way it is pulled."""
    m = Machine("ScreedBoard")
    B = "Body"
    bm, fin = m.part(B, "Board", "Timber", bevel=0.004)
    # 3.70 m and a 2x6, not 4.20 m and a 2x4: the driven stakes stand a stub
    # proud OUTSIDE the boards at 1.93 m either side of the centre, and a longer
    # board would sweep through them; and a 90 mm board was a stray form board
    # in every screed frame (round 3).
    add_box(bm, V(0.0, 0.070, 0.0), (3.70, 0.140, 0.050))
    fin()
    # A lighter top edge, so a 4 m plank is not one flat brown bar.
    bm, fin = m.part(B, "Edge", "Wood")
    add_box(bm, V(0.0, 0.140 - SINK, 0.0), (3.70, 0.012, 0.050))
    fin()
    bm, fin = m.part(B, "Handles", "Engine", bevel=0.004)
    for sx in (-1.0, 1.0):
        add_tube(bm, V(sx * 1.62, 0.140, 0.0), V(sx * 1.62, 0.300, -0.080), 0.018, 8)
        add_tube(bm, V(sx * 1.50, 0.300, -0.080), V(sx * 1.74, 0.300, -0.080), 0.018, 8)
    fin()
    m.mesh_node(B)
    m.empty("Tip", V(0.0, 0.0, 0.0), zdir=(0, 0, 1), xhint=(1, 0, 0))
    m.note("3.70 m 2x6 across the drive, two handles; origin on its bottom edge")
    return m


# ==========================================================================
#  4. JOINTER - phase 9, the control joints.
# ==========================================================================
def build_jointer():
    """A walking groover: a steel runner with a rounded bead that cuts the
    joint, a bracket, and a long handle going back. Origin at the bottom of
    the bead, +Z down into the slab."""
    m = Machine("Jointer")
    # Not pale metal: at 0.92 the sled was the brightest object on the lot
    # (round 12), the same trap the joint's lip fell into in round 6. Not plain
    # Steel either: at 0.42 it rendered 9% from the slab it sat on (round 13).
    # Dark steel ("Disc", 0.30) kept the value step - and was a dark-grey sled on
    # a grey slab, the least visible tool in the game (the improvement plan's
    # 4.4). So the value stays and the HUE changes: the sled is tool orange at
    # the same value, and the dark steel is only its bottom edge.
    #
    # The steel: the bead that makes the groove, a round bar along Y (the
    # travel), and a SOLE under the plate 6 mm proud of its long sides - the
    # dark rim a real groover's wear plate is.
    bm, fin = m.part("Blade", "Runner", "Disc", bevel=0.002)
    add_cone(bm, V(0.0, 0.0, -0.004), Y, 0.012, 0.012, 0.220, 10)
    # z -0.009..-0.004: 1 mm up into the plate's bottom (-0.008), so no two faces
    # are coplanar, and 2 mm short of its ends.
    add_box(bm, V(0.0, 0.0, -0.0065), (0.162, 0.236, 0.005))
    fin()
    # The SLED - a plate a hand and a half long with both ends stepped up like
    # a runner's - so the head is a tool in the picture and not a 35 px speck
    # (round 11).
    bm, fin = m.part("Blade", "Sled", "ToolOrange", bevel=0.002)
    add_box(bm, V(0.0, 0.0, -0.012), (0.150, 0.240, 0.008))
    for sy in (-1.0, 1.0):
        add_box(bm, V(0.0, sy * 0.128, -0.021), (0.150, 0.024, 0.010))
        add_box(bm, V(0.0, sy * 0.142, -0.032), (0.150, 0.016, 0.012))
    fin()
    # And a BIT the eye can see: a dark fin at the trailing end standing up
    # out of the groove behind the plate, the width of the cut.
    bm, fin = m.part("Blade", "Bit", "Engine", bevel=0.002)
    add_box(bm, V(0.0, -0.132, -0.022), (0.022, 0.030, 0.060))
    fin()
    m.mesh_node("Blade")
    B = "Body"
    bm, fin = m.part(B, "Bracket", "Hub", bevel=0.003)
    add_box(bm, V(0.0, 0.0, -0.050), (0.036, 0.030, 0.036))
    fin()
    # A LONG handle - a walking groover is pushed from standing - and the grip
    # is its OWN node, so the game can stretch the handle into the child's
    # hands (`HandTool.aim_handle_at`) and slide the grip to its end
    # unstretched (round 10: a knob scaled with the handle was a sausage).
    bm, fin = m.part(B, "Handle", "Timber", bevel=0.003)
    add_tube(bm, V(0.0, 0.0, -0.066), V(0.0, 1.10, -0.600), 0.016, 8)
    fin()
    m.mesh_node(B)
    bm, fin = m.part("Grip", "Knob", "Accent", bevel=0.003)
    add_cone(bm, V(0.0, 1.10, -0.600), V(0.0, 1.25, -0.672), 0.024, 0.020, 0.070, 10)
    fin()
    m.mesh_node("Grip")
    m.empty("Tip", V(0.0, 0.0, 0.0), zdir=(0, 0, 1), xhint=(1, 0, 0))
    m.note("bead r 0.012 and a steel sole under a 0.15 x 0.24 tool-orange sled, 1.25 handle with its grip a node; origin at the bead")
    return m


# ==========================================================================
#  5. BROOM - phase 10, the finish.
# ==========================================================================
def build_broom():
    """A concrete broom: a wide block of blue bristles on a head, a long
    handle back and up. Origin at the middle of the bristle face, +Z into
    the slab, so the game lays it flat on the surface and draws it across."""
    m = Machine("Broom")
    # TUFTS, not a blue brick (round 6): eighteen rows of bristle with a gap
    # between each, so the head is serrated from the side.
    bm, fin = m.part("Head", "Bristles", "Bristle")
    for i in range(18):
        add_box(bm, V(-0.425 + i * 0.050, 0.0, -0.042), (0.036, 0.020, 0.084))
    fin()
    bm, fin = m.part("Head", "Block", "Timber", bevel=0.004)
    add_box(bm, V(0.0, 0.0, -0.084 - SINK - 0.025), (0.920, 0.060, 0.050))
    fin()
    m.mesh_node("Head")
    B = "Body"
    # 1.7 m of handle: a concrete broom's, and long enough to run from the
    # slab up to the hands of a person standing at the kerb.
    bm, fin = m.part(B, "Handle", "Wood", bevel=0.003)
    add_tube(bm, V(0.0, 0.0, -0.115), V(0.0, 1.55, -0.760), 0.017, 8)
    fin()
    bm, fin = m.part(B, "Ferrule", "Hub")
    add_cone(bm, V(0.0, 0.03, -0.132), V(0.0, 1.55, -0.76), 0.023, 0.020, 0.060, 10)
    fin()
    m.mesh_node(B)
    m.empty("Tip", V(0.0, 0.0, 0.0), zdir=(0, 0, 1), xhint=(1, 0, 0))
    m.note("0.90 m of tufted bristle, 1.7 handle; origin at the bristle face")
    return m


# ==========================================================================
#  6. COME-ALONG - phase 6b, pulling the concrete up the form. Same frame as
#     the broom: origin at the middle of the blade's bottom edge, +Z into the
#     slab, +Y the way the handle goes (toward the person pulling it).
# ==========================================================================
def build_come_along():
    """A concrete rake: a flat steel blade, slightly curved back, a bracket and
    a long handle. It is PULLED, so the handle rises along +Y from the blade's
    top and the blade stands up from the slab (along -Z)."""
    m = Machine("ComeAlong")
    bm, fin = m.part("Head", "Blade", "Steel", bevel=0.003)
    # The plate stands UP off the slab (its height runs along -Z) and is thin
    # along Y, the pull direction. Dark steel, and taller: a pale thin plate
    # read as a white line with two tabs from two metres (round 8).
    add_box(bm, V(0.0, 0.0, -0.095), (0.560, 0.024, 0.190))
    fin()
    # A dark wear edge along the bottom and two ribs up the back, so the head is
    # a blade and not a brick (round 4).
    bm, fin = m.part("Head", "Lip", "Engine")
    add_box(bm, V(0.0, 0.0, -0.008), (0.540, 0.032, 0.016))
    fin()
    bm, fin = m.part("Head", "Ribs", "Engine")
    for sx in (-0.16, 0.16):
        add_box(bm, V(sx, 0.014 + SINK, -0.070), (0.020, 0.008, 0.130))
    fin()
    m.mesh_node("Head")
    B = "Body"
    bm, fin = m.part(B, "Bracket", "Hub", bevel=0.003)
    add_box(bm, V(0.0, 0.018 + SINK, -0.100), (0.060, 0.036, 0.070))
    add_box(bm, V(0.0, 0.050, -0.130), (0.040, 0.050, 0.040))
    fin()
    bm, fin = m.part(B, "Handle", "Timber", bevel=0.003)
    add_tube(bm, V(0.0, 0.070, -0.140), V(0.0, 1.50, -0.900), 0.017, 8)
    fin()
    bm, fin = m.part(B, "Grip", "Accent", bevel=0.003)
    add_cone(bm, V(0.0, 1.49, -0.895), V(0.0, 1.62, -0.96), 0.021, 0.019, 0.150, 10)
    fin()
    m.mesh_node(B)
    m.empty("Tip", V(0.0, 0.0, 0.0), zdir=(0, 0, 1), xhint=(1, 0, 0))
    m.note("0.52 m blade, 1.7 m handle back along +Y; origin at the blade's bottom edge")
    return m


BUILDERS = [
    ("Jackhammer", build_jackhammer),
    ("Sledge", build_sledge),
    ("ScreedBoard", build_screed_board),
    ("Jointer", build_jointer),
    ("Broom", build_broom),
    ("ComeAlong", build_come_along),
]


def check_nodes(name, path):
    js = L.glb_json(path)
    have = [n.get("name", "?") for n in js.get("nodes", [])]
    missing = [w for w in CONTRACT[name] if w not in have]
    log("%s: exported nodes %s" % (name, have))
    if missing:
        log("%s: MISSING CONTRACT NODES %s" % (name, missing))
        return False
    return True


def check_origin(name, path):
    """The working face really is at the origin. A tool whose origin has
    drifted is a tool the game hangs in the air a hand away from the work,
    and no screenshot ever says why."""
    js = L.glb_json(path)
    tip = None
    for n in js.get("nodes", []):
        if n.get("name") == "Tip":
            t = n.get("translation", [0.0, 0.0, 0.0])
            tip = Vector((t[0], t[1], t[2]))
    if tip is None:
        log("%s: no Tip marker" % name)
        return False
    ok = tip.length < 0.002
    log("%s: Tip at (%.4f, %.4f, %.4f) %s" % (name, tip.x, tip.y, tip.z, "OK" if ok else "OFF ORIGIN"))
    return ok


results = []
for tool_name, builder in BUILDERS:
    if ONLY and tool_name not in ONLY:
        continue
    L.fresh_scene()
    machine = builder()
    out = os.path.join(OUT_DIR, tool_name + ".glb")
    ok = machine.export(out, PREVIEW, views=VIEWS)
    ok = check_nodes(tool_name, out) and check_origin(tool_name, out) and ok
    results.append((tool_name, ok, machine.tris, machine.notes))

log("---- summary ----")
all_ok = True
for tool_name, ok, tris, notes in results:
    all_ok = all_ok and ok
    log("%-12s %s  %5d tris  %s" % (tool_name, "OK  " if ok else "FAIL", tris, "; ".join(notes)))
print("SITE_PROPS_OK %d" % len(results) if all_ok else "SITE_PROPS_FAIL")
