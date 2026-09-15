"""Shared sub-assemblies for the Big Little Jobs machine fleet.

Sits on top of `equip_lib.py` (copied verbatim from car-fixer, which copied it
from tree-chop) and adds the pieces a WORKING machine needs that a car does
not: crawler tracks, chunky off-road wheels, an operator cab, hydraulic rams
that really extend, digging and loading buckets, beacons and hazard stripes.

Conventions -- identical to Car Fixer's and Tree Crew's, so a machine from
this folder stands next to one of theirs without a seam:

  * authored in GODOT metres, Y up, the machine faces +Z
  * the origin is on the GROUND under the machine's centre
  * every part is flat-shaded low poly; curves get 8-16 segments, never more
  * one mesh node per moving thing; a ROTATING assembly is an EMPTY pivot
    with a `<Name>Mesh` child, so the empty's basis stays identity and
    children chain naturally (Boom > Stick > Bucket > BucketTip)
  * a SLIDING part is a mesh node re-centred at its home, so the game adds
    an offset along the node's own +Z
  * a marker empty's +Z is the meaningful direction (where it pours, grabs,
    tips or points)

Nothing here knows about any one game: these are props with named joints.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import equip_lib as L  # noqa: E402
from equip_lib import (V, X, Y, Z, add_arc_shell, add_box,  # noqa: E402
                       add_box_between, add_cone, add_prism, add_ring,
                       add_tube, C3, log)
import bpy  # noqa: E402,F401  (equip_lib re-exports it for the preview swap)
from mathutils import Vector  # noqa: E402

PI = math.pi
SIN = math.sin
COS = math.cos
RAD = math.radians

# --------------------------------------------------------------------------
#  Palette. equip_lib's table is FROZEN, so additions are injected here,
#  before the first fresh_scene() / build_materials() call. Car Fixer's own
#  additions are repeated verbatim (same values) so a truck built here and a
#  truck built there are literally the same colours.
# --------------------------------------------------------------------------
L.MATERIALS["White"] = (0.93, 0.93, 0.90)
L.MATERIALS["Black"] = (0.08, 0.08, 0.09)
L.MATERIALS["Green"] = (0.13, 0.50, 0.24)      # the refuse body
L.MATERIALS["Machine"] = (0.95, 0.70, 0.09)    # construction yellow: the fleet colour.
                                               # Deeper than the palette's `Yellow`
                                               # (0.98 0.78 0.12), which stays what it
                                               # has always been -- a safety stripe.
L.MATERIALS["Track"] = (0.15, 0.15, 0.17)      # track rubber: one step off `Tyre`
                                               # (0.07) so a shoe reads against a tyre
L.MATERIALS["Grouser"] = (0.32, 0.33, 0.36)    # the bar across a track shoe
L.MATERIALS["Wear"] = (0.72, 0.74, 0.78)       # a polished cutting edge / bucket lip
# ---- farm & city (the same family, one palette; see docs/FLEET.md) --------
L.MATERIALS["BarnRed"] = (0.60, 0.16, 0.13)    # the barn, and only the barn
L.MATERIALS["Roof"] = (0.31, 0.27, 0.27)       # shingle / tile, dark warm grey
L.MATERIALS["RoofTile"] = (0.55, 0.30, 0.22)   # a terracotta roof, for variety
L.MATERIALS["Brick"] = (0.64, 0.34, 0.27)
L.MATERIALS["Render"] = (0.88, 0.85, 0.78)     # painted render / stucco
L.MATERIALS["Trim"] = (0.96, 0.95, 0.92)       # window and door surrounds
L.MATERIALS["Asphalt"] = (0.305, 0.305, 0.325)   # lifted a step: at the old
                                                 # value it was the darkest thing
                                                 # in the kit and everything
                                                 # standing on it looked unmoored
L.MATERIALS["Gutter"] = (0.375, 0.375, 0.385)    # the strip inside the kerb
L.MATERIALS["Kerb"] = (0.74, 0.74, 0.72)       # a shade paler than Concrete
L.MATERIALS["Grass"] = (0.36, 0.58, 0.26)
L.MATERIALS["Soil"] = (0.38, 0.28, 0.20)
L.MATERIALS["Crop"] = (0.80, 0.70, 0.30)       # standing wheat, straw, hay
L.MATERIALS["CropTip"] = (0.91, 0.84, 0.46)    # the lit ear on top of it
L.MATERIALS["Leaf"] = (0.24, 0.52, 0.25)
L.MATERIALS["Bark"] = (0.35, 0.26, 0.19)
# ---- livestock -----------------------------------------------------------
L.MATERIALS["Wool"] = (0.90, 0.88, 0.82)      # a sheep's fleece: paler than Trim
L.MATERIALS["Pigskin"] = (0.92, 0.66, 0.63)
L.MATERIALS["Bay"] = (0.44, 0.25, 0.14)       # a horse's coat
L.MATERIALS["Mane"] = (0.17, 0.12, 0.09)      # ... and its mane and tail
L.MATERIALS["Hoof"] = (0.23, 0.20, 0.18)
L.MATERIALS["Snout"] = (0.84, 0.50, 0.48)     # a pig's nose: a DEEPER pink
                                              # than its skin, not a red disc
L.MATERIALS["Beak"] = (0.95, 0.72, 0.16)      # beaks, bills and duck feet
L.MATERIALS["Horn"] = (0.86, 0.82, 0.70)      # horns, and a goat's beard
# ---- suburb --------------------------------------------------------------
L.MATERIALS["Olive"] = (0.44, 0.45, 0.27)     # a craftsman house's body
L.MATERIALS["Stone"] = (0.58, 0.56, 0.52)     # porch piers and foundations
L.MATERIALS["Sand"] = (0.87, 0.79, 0.58)
L.MATERIALS["Clay"] = (0.74, 0.46, 0.30)      # a warmer siding, so a street
                                              # of houses is not one colour
L.MATERIALS["RoofCap"] = (0.47, 0.43, 0.42)   # a ridge cap / fascia board,
                                              # one clear step off `Roof`. A
                                              # pitched roof is the biggest
                                              # face on a house from the
                                              # diorama camera and one flat
                                              # near-black plane kills it
L.MATERIALS["SignBlueDark"] = (0.11, 0.24, 0.50)   # a panel ON a blue thing
L.MATERIALS["GlassDark"] = (0.26, 0.38, 0.46)  # office curtain wall
L.MATERIALS["SignRed"] = (0.76, 0.12, 0.12)
L.MATERIALS["SignGreen"] = (0.10, 0.42, 0.24)
L.MATERIALS["SignBlue"] = (0.16, 0.34, 0.68)
L.MATERIALS["Amber"] = (0.96, 0.62, 0.10)      # a traffic light's middle lens
L.MATERIALS["GoGreen"] = (0.20, 0.76, 0.34)    # ... and its bottom one

ON_PANEL = 0.004        # the smallest gap a plate may stand off its panel
SINK = 0.003            # how far a thing standing on another sinks into it


# ==========================================================================
#  PREVIEW FRAMING. equip_lib fits its camera to the LARGEST bounding-box
#  extent and multiplies it by a constant, which works for a long low machine
#  and silently crops a tall one -- the render is 4:3, so the vertical field
#  of view is only three quarters of the horizontal, and a 6 m tile with a
#  5 m light column on it came out as mostly lamp post and backdrop.
#
#  This measures the bounds PROJECTED onto the camera's own right and up
#  axes and solves for the distance that fits both, which is the same answer
#  for every shape. equip_lib stays byte-identical to Car Fixer's copy: the
#  swap is done here, at import, and it only ever affects PNGs -- no exported
#  geometry passes through this function.
# ==========================================================================
SENSOR = 36.0                          # Blender's default, fitted to the wider axis
FIT_MARGIN = 1.12                      # a little air round the subject


def render_previews(machine, objs, preview_dir, views=None):
    os.makedirs(preview_dir, exist_ok=True)
    scene = L.bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    sh = scene.display.shading
    sh.light, sh.color_type = "STUDIO", "MATERIAL"
    sh.show_shadows, sh.shadow_intensity = True, 0.30
    sh.show_cavity, sh.cavity_type = True, "BOTH"
    sh.background_type, sh.background_color = "VIEWPORT", (0.62, 0.76, 0.88)
    try:
        scene.view_settings.view_transform = "Standard"
        scene.view_settings.look = "None"
        scene.view_settings.exposure = 0.0
        scene.view_settings.gamma = 1.0
    except Exception as exc:
        log("view transform:", exc)
    scene.render.resolution_x, scene.render.resolution_y = 640, 480
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"
    if "PreviewCam" not in L.bpy.data.objects:
        cd = L.bpy.data.cameras.new("PreviewCam")
        cd.lens = 45
        scene.collection.objects.link(L.bpy.data.objects.new("PreviewCam", cd))
    cam = L.bpy.data.objects["PreviewCam"]
    scene.camera = cam
    lens = cam.data.lens
    aspect = scene.render.resolution_y / float(scene.render.resolution_x)
    tan_h = (SENSOR * 0.5) / lens
    tan_v = tan_h * aspect
    corners = []
    for o in objs:
        if o.type != "MESH":
            continue
        for c in o.bound_box:
            corners.append(C3 @ (o.matrix_world @ Vector(c)))
    if not corners:
        return
    lo = Vector((min(p.x for p in corners), min(p.y for p in corners),
                 min(p.z for p in corners)))
    hi = Vector((max(p.x for p in corners), max(p.y for p in corners),
                 max(p.z for p in corners)))
    centre = (lo + hi) * 0.5
    for label, direction in (views or L.DEFAULT_VIEWS).items():
        d = Vector(direction).normalized()
        right = d.cross(Y)
        right = right.normalized() if right.length > 1e-6 else Vector(X)
        up = right.cross(d).normalized()
        hw = max(abs((p - centre).dot(right)) for p in corners)
        hh = max(abs((p - centre).dot(up)) for p in corners)
        hd = max(abs((p - centre).dot(d)) for p in corners)
        dist = max(hw / tan_h, hh / tan_v) * FIT_MARGIN + hd + 0.3
        loc = L.g2b(centre + d * dist)
        cam.location = loc
        cam.rotation_euler = (L.g2b(centre) - loc).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(preview_dir,
                                             "%s_%s.png" % (machine.name, label))
        L.bpy.ops.render.render(write_still=True)
    log("%s: previews in %s (%.2f x %.2f x %.2f m)"
        % (machine.name, preview_dir, hi.x - lo.x, hi.y - lo.y, hi.z - lo.z))


L.render_previews = render_previews     # Machine.export resolves this at call time


# ==========================================================================
#  Part wrapper: every part is measured as it is authored, so a machine's
#  real bounds are known without opening it in anything.
# ==========================================================================
ST = {}
WHEELS = []      # every wheel() drawn since the last reset_stats()


def reset_stats():
    ST.clear()
    ST.update(lo=[9e9, 9e9, 9e9], hi=[-9e9, -9e9, -9e9], parts=0, below=[],
              floor=-0.004)
    del WHEELS[:]


def allow_below(depth):
    """A ground tile's slab hangs UNDER y=0 on purpose: its top face is the
    surface. Call this once in such a builder and the check moves down."""
    ST["floor"] = -abs(depth) - 0.004


def part(m, group, pname, mat, bevel=0.0, solidify=0.0, preview=False):
    """m.part() plus a measurement of what was actually authored."""
    bm, fin = m.part(group, pname, mat, bevel=bevel, solidify=solidify, preview=preview)

    def done():
        obj = fin()
        if not preview:
            grow = solidify * 0.5
            lo, hi = part_box(obj)
            for i in range(3):
                ST["lo"][i] = min(ST["lo"][i], lo[i] - grow)
                ST["hi"][i] = max(ST["hi"][i], hi[i] + grow)
            ST["parts"] += 1
            if lo.y - grow < ST["floor"]:
                ST["below"].append((pname, round(lo.y - grow, 4)))
        return obj
    return bm, done


def part_box(obj):
    """(lo, hi) of a part's vertices in Godot metres."""
    lo = [9e9, 9e9, 9e9]
    hi = [-9e9, -9e9, -9e9]
    for v in obj.data.vertices:
        g = C3 @ v.co
        for i in range(3):
            lo[i] = min(lo[i], g[i])
            hi[i] = max(hi[i], g[i])
    return (Vector(lo), Vector(hi))


def dims():
    return (ST["hi"][0] - ST["lo"][0], ST["hi"][1] - ST["lo"][1],
            ST["hi"][2] - ST["lo"][2])


# ==========================================================================
#  Small authoring helpers (the same names Car Fixer's builders use).
# ==========================================================================
def boxes(m, G, pname, mat, spec, bevel=0.0, mirror=False):
    """spec = [(center, size), ...]; mirror=True repeats each at -x."""
    bm, fin = part(m, G, pname, mat, bevel=bevel)
    for c, s in spec:
        add_box(bm, V(*c), s)
        if mirror:
            add_box(bm, V(-c[0], c[1], c[2]), s)
    fin()


def panel(m, G, pname, p0, p1, w, t, mat, bevel=0.0):
    """A sloped plate in the y-z plane, `w` across X, `t` thick."""
    bm, fin = part(m, G, pname, mat, bevel=bevel)
    add_box_between(bm, V(*p0), V(*p1), w, t)
    fin()


def add_sector(bm, centre, axis, e_a, e_b, r, a0, a1, segs, thick, r_in=0.0):
    """A solid pie wedge (or, with `r_in`, a curved rib): the sector
    r_in..r / a0..a1 in the (e_a, e_b) plane, extruded `thick` along `axis`.
    ONE closed prism, not a fan of overlapping ones -- the only way to close
    the SIDE of a curved shell, since add_arc_shell gives an open strip and
    add_prism only a triangle."""
    e_a, e_b = Vector(e_a), Vector(e_b)
    a = Vector(axis).normalized() * (thick * 0.5)
    c = Vector(centre)
    ring = []
    for i in range(segs + 1):
        th = a0 + (a1 - a0) * i / float(segs)
        ring.append(c + (e_a * COS(th) + e_b * SIN(th)) * r)
    if r_in > 1e-6:
        for i in range(segs, -1, -1):
            th = a0 + (a1 - a0) * i / float(segs)
            ring.append(c + (e_a * COS(th) + e_b * SIN(th)) * r_in)
    else:
        ring.append(c)
    back = [bm.verts.new(p - a) for p in ring]
    front = [bm.verts.new(p + a) for p in ring]
    bm.faces.new(back)
    bm.faces.new(list(reversed(front)))
    n = len(ring)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((back[i], back[j], front[j], front[i]))


def add_shell(bm, centre, axis, e_a, e_b, r_in, r_out, a0, a1, segs, width):
    """A thick curved shell (a bucket's back, a fender): the band between two
    radii, swept a0..a1, `width` wide along `axis`. Solid, so it needs no
    solidify modifier and never leaves an open edge for the light to find."""
    e_a, e_b = Vector(e_a), Vector(e_b)
    a = Vector(axis).normalized()
    c = Vector(centre)
    h = a * (width * 0.5)
    rows = []
    for i in range(segs + 1):
        th = a0 + (a1 - a0) * i / float(segs)
        u = e_a * COS(th) + e_b * SIN(th)
        rows.append((c + u * r_in, c + u * r_out))
    ring = []
    for pin, pout in rows:
        ring.append((bm.verts.new(pin - h), bm.verts.new(pout - h),
                     bm.verts.new(pout + h), bm.verts.new(pin + h)))
    for a0v, a1v in zip(ring, ring[1:]):
        bm.faces.new((a0v[1], a1v[1], a1v[2], a0v[2]))     # outer
        bm.faces.new((a0v[0], a0v[3], a1v[3], a1v[0]))     # inner
        bm.faces.new((a0v[0], a1v[0], a1v[1], a0v[1]))     # -axis side
        bm.faces.new((a0v[3], a0v[2], a1v[2], a1v[3]))     # +axis side
    bm.faces.new(list(reversed(ring[0])))
    bm.faces.new(list(ring[-1]))


def hazard(m, G, pname, c, size, cells=5, mat_a="Yellow", mat_b="Black", along=X):
    """The diagonal-ish warning band every heavy machine wears: alternating
    blocks, two nodes' worth of material in one part each."""
    along = Vector(along)
    step = (size[0] if abs(along.x) > 0.5 else size[2]) / float(cells)
    for mat, idx in ((mat_a, range(0, cells, 2)), (mat_b, range(1, cells, 2))):
        bm, fin = part(m, G, "%s_%s" % (pname, mat), mat)
        for i in idx:
            off = (i - (cells - 1) * 0.5) * step
            cell = (step, size[1], size[2]) if abs(along.x) > 0.5 else (size[0], size[1], step)
            add_box(bm, Vector(c) + along * off, cell)
        fin()


def grab_rail(bm, p0, p1, r=0.022, stand=0.07, up=Y):
    """A handrail on two stand-offs, so it reads as a thing you hold and not
    a stripe painted on the panel."""
    p0, p1 = Vector(p0), Vector(p1)
    n = (p1 - p0).normalized().cross(Vector(up)).normalized() * stand
    add_tube(bm, p0 + n, p1 + n, r, 6)
    add_tube(bm, p0, p0 + n, r * 0.8, 6)
    add_tube(bm, p1, p1 + n, r * 0.8, 6)


# ==========================================================================
#  WHEELS -- the fleet's chunky off-road tyre. Bigger and squarer than the
#  car fleet's (which is 0.34 r on a 0.22 tread); the lugs are a chevron
#  pair so a 40 cm tyre still reads as tread at tablet distance.
# ==========================================================================
def wheel(m, node, c, r=0.46, w=0.32, rim_f=0.60, lugs=13, parent=None,
          rim_mat="Hub", dual=False, segs=16):
    """One wheel as its own node, origin ON the axle, spinning about X.

    `rim_f` is the rim radius as a fraction of `r`; `dual` cuts a groove down
    the middle of the tread so a wide rear reads as twin tyres.
    """
    c = V(*c)
    WHEELS.append((c.x, c.y, c.z, r, w))
    sx = 1.0 if c.x >= 0.0 else -1.0
    rim_r = r * rim_f
    carc = r - 0.034                       # the carcass; the LUGS carry `r`
    bm, fin = part(m, node, node + "_Tyre", "Tyre")
    add_ring(bm, c, X, rim_r, carc, w, segs)
    fin()
    # Tread. A chevron pair per station: two blocks angled the opposite way,
    # which is what a real off-road lug looks like from three metres and what
    # a single straight bar never manages. The outer face stops 6 mm short of
    # `r` because the block's CORNER reaches further than its face, and the
    # difference is the machine sunk into the road.
    if not lugs:
        # A road tyre: the carcass keeps the full radius and a shoulder band
        # gives the highlight that tread blocks give an off-road one.
        bm, fin = part(m, node, node + "_Tread", "Tyre")
        add_ring(bm, c, X, carc - 0.006, r, w * 0.84, segs)
        fin()
        bm, fin = part(m, node, node + "_Wall", "Track")
        for sk in (-1.0, 1.0):
            add_ring(bm, c + X * (sk * (w * 0.5 - 0.055)), X, rim_r + 0.02,
                     carc + 0.012, 0.03, segs)
        fin()
    bm, fin = part(m, node, node + "_Lugs", "Tyre")
    for i in range(lugs):
        a = 2.0 * PI * i / lugs
        u = Y * COS(a) + Z * SIN(a)
        t = -Y * SIN(a) + Z * COS(a)
        for sk in (-1.0, 1.0):
            ax = (t + X * (sk * 0.55)).normalized()
            add_box(bm, c + u * (r - 0.020) + X * (sk * w * 0.26),
                    (0.028, 0.09, w * 0.42), axes=(u, ax, ax.cross(u).normalized()))
    fin()
    if dual:
        bm, fin = part(m, node, node + "_Groove", "Black")
        add_ring(bm, c, X, carc - 0.004, carc + 0.016, w * 0.10, segs)
        fin()
    bm, fin = part(m, node, node + "_Rim", rim_mat)
    add_cone(bm, c, X, rim_r + 0.006, rim_r + 0.006, w * 0.86, segs)
    fin()
    bm, fin = part(m, node, node + "_Cap", "Steel")
    add_cone(bm, c + X * (sx * (w * 0.43 + 0.012)), X, rim_r * 0.42, rim_r * 0.34,
             0.05, 10)
    fin()
    bm, fin = part(m, node, node + "_Nuts", "Metal")
    for i in range(6):
        a = 2.0 * PI * i / 6.0 + RAD(30.0)
        u = Y * COS(a) + Z * SIN(a)
        add_cone(bm, c + u * (rim_r * 0.62) + X * (sx * (w * 0.43 + 0.010)), X,
                 0.028, 0.028, 0.026, 6)
    fin()
    m.mesh_node(node, parent=parent, center=c)


def arch(m, G, name="Arches", mat="Machine", liner="Grouser", spec=None,
         t=0.075, over=1.22, lip=0.055, segs=11, skip=()):
    """A proud arch over every wheel, and a darker liner just inside it.

    Called with no `spec` it covers every wheel() drawn since reset_stats(),
    so the arches cannot drift from the wheels -- pass `skip` a set of node
    names' indices only when a wheel genuinely wants no arch.

    This is the single biggest thing separating a Car Fixer vehicle from a box
    with wheels under it. An arch changes the SILHOUETTE, which is what
    survives at thumbnail size, and the dark liner keeps a black tyre from
    disappearing into a dark body. `add_arc_shell` gives an open strip; the
    part's solidify turns it into a shell with real thickness.

    NOTE the arch's end caps are flat planes at |x| = x_in and x_out. Keep
    them off the body's own side planes or the z-fight scan will say so.
    """
    spec = spec if spec is not None else [w for i, w in enumerate(WHEELS)
                                          if i not in skip]
    if not spec:
        return
    bm, fin = part(m, G, name, mat, solidify=t)
    for x, y, z, r, w in spec:
        sx = 1.0 if x >= 0.0 else -1.0
        xi, xo = abs(x) - w * 0.5 - 0.012, abs(x) + w * 0.5 + lip
        R = r * over
        add_arc_shell(bm, V(sx * xi, y, z), R, V(sx * xo, y, z), R,
                      Z, Y, 0.0, PI, segs)
    fin()
    bm, fin = part(m, G, name + "Liner", liner, solidify=t * 0.5)
    for x, y, z, r, w in spec:
        sx = 1.0 if x >= 0.0 else -1.0
        xi, xo = abs(x) - w * 0.5 - 0.004, abs(x) + w * 0.5 + lip * 0.55
        R = r * (over - 0.075)
        add_arc_shell(bm, V(sx * xi, y, z), R, V(sx * xo, y, z), R,
                      Z, Y, 0.0, PI, segs)
    fin()


def truck_face(m, G, z, half, y_lo, y_hi, name="Face", panel_mat="Engine",
               bar="Hub", bars=5, lamps=(), lamp_r=0.11, bezel="Hub",
               badge=None, badge_mat="Wear"):
    """A face: a dark grille panel, vertical bars proud of it, a bezel ring
    round each headlamp, and an optional badge.

    Every truck in this fleet had one flat black rectangle and two lamp discs
    where the reference has a recess, bars, bezels and a badge. `z` is the
    nose plane; `lamps` are (x, y) centres in it.

    The bars sit in the panel's own shadow, so they add relief without
    muddying the outline -- which is the constraint that keeps this from
    becoming surface fussiness.
    """
    yc, yh = (y_lo + y_hi) * 0.5, y_hi - y_lo
    bm, fin = part(m, G, name + "Grille", panel_mat, bevel=0.01)
    add_box(bm, V(0.0, yc, z + 0.020), (half * 2.0, yh, 0.055))
    fin()
    if bars:
        bm, fin = part(m, G, name + "Bars", bar)
        for i in range(bars):
            bx = (i - (bars - 1) * 0.5) * (half * 1.72 / max(1, bars - 1))
            add_box(bm, V(bx, yc, z + 0.052), (0.052, yh - 0.085, 0.030))
        add_box(bm, V(0.0, yc, z + 0.052), (half * 2.0 - 0.05, 0.055, 0.030))
        fin()
    if lamps:
        bm, fin = part(m, G, name + "Bezels", bezel)
        for lx, ly in lamps:
            add_ring(bm, V(lx, ly, z + 0.026), Z, lamp_r * 0.98, lamp_r * 1.34,
                     0.052, 12)
        fin()
    if badge:
        bm, fin = part(m, G, name + "Badge", badge_mat, bevel=0.01)
        add_box(bm, V(0.0, badge, z + 0.040), (0.34, 0.12, 0.05))
        fin()


def louvres(m, G, name, at, across, up, w, h, n=5, mat="Engine", face=X,
            depth=0.030, rib=None):
    """A stack of cooling louvres on an engine bay's flank.

    `at` is the OUTER surface point on the face's axis; `across` and `up` are
    the two in-plane axes. Every machine in this fleet has a bare slab where
    its radiator lives; this is the cheapest thing that says "engine in here".
    """
    face = V(*face) if not hasattr(face, "x") else face
    across, up = V(*across) if not hasattr(across, "x") else across, \
        V(*up) if not hasattr(up, "x") else up
    rib = rib or h / float(n) * 0.52
    bm, fin = part(m, G, name, mat)
    base = V(*at) + face * (depth * 0.5)
    for i in range(n):
        u = (i - (n - 1) * 0.5) * (h / float(n))
        add_box(bm, base + up * u, (w, rib, depth), axes=(across, up, face))
    fin()


def handrail(m, G, name, pts, h=0.90, r=0.028, mat="Metal", posts=True):
    """A rail run: a top tube along `pts` and a stanchion under each point.
    Handrails round a platform are what make a machine look like something a
    person climbs on rather than a solid casting."""
    pts = [V(*p) for p in pts]
    bm, fin = part(m, G, name, mat)
    for a, b in zip(pts, pts[1:]):
        add_tube(bm, a + Y * h, b + Y * h, r, 6)
        add_tube(bm, a + Y * (h * 0.55), b + Y * (h * 0.55), r * 0.80, 6)
    if posts:
        for p in pts:
            add_tube(bm, p, p + Y * h, r * 1.15, 6)
    fin()


def ladder(m, G, name, p0, p1, w=0.36, rungs=5, mat="Metal", r=0.024,
           cage=False):
    """An access ladder between two points, with an optional hoop cage --
    which is what a grain bin or a silo needs before it reads as climbable."""
    p0, p1 = V(*p0), V(*p1)
    d = p1 - p0
    side = V(d.y, -d.x, 0.0)
    side = X if side.length < 1e-6 else side.normalized()
    side = X
    bm, fin = part(m, G, name, mat)
    for sx in (-1.0, 1.0):
        add_tube(bm, p0 + side * (sx * w * 0.5), p1 + side * (sx * w * 0.5), r, 6)
    for i in range(rungs):
        t = (i + 0.5) / float(rungs)
        p = p0 + d * t
        add_tube(bm, p - side * (w * 0.5), p + side * (w * 0.5), r * 0.80, 6)
    if cage:
        n = max(3, int(d.length / 0.70))
        fwd = V(0.0, 0.0, 1.0) if abs(d.z) < 0.5 else V(1.0, 0.0, 0.0)
        for i in range(n):
            t = 0.30 + 0.70 * (i / float(max(1, n - 1)))
            c = p0 + d * t
            add_ring(bm, c + fwd * (w * 0.28), Y, w * 0.60, w * 0.68, 0.030, 9)
    fin()


def hose_run(m, G, name, pts, r=0.030, mat="Black", clamps="Hub", segs=6):
    """A hydraulic hose following a boom, with a clamp where it changes
    direction. A bare boom is a girder; a boom with a hose on it is a machine
    that does something."""
    pts = [V(*p) for p in pts]
    bm, fin = part(m, G, name, mat)
    for a, b in zip(pts, pts[1:]):
        add_tube(bm, a, b, r, segs)
    fin()
    if clamps and len(pts) > 2:
        bm, fin = part(m, G, name + "Clamps", clamps)
        for p in pts[1:-1]:
            add_cone(bm, p, Y, r * 1.9, r * 1.9, r * 1.5, 6)
        fin()


def step_plate(m, G, name, spec, mat="Grouser", w=0.42, d=0.20, t=0.045):
    """Chequer-plate access steps. `spec` = [(x, y, z), ...] -- one per tread,
    positioned wherever a foot would go."""
    bm, fin = part(m, G, name, mat, bevel=0.01)
    for c in spec:
        add_box(bm, V(*c), (w, t, d))
    fin()


def drum_wheel(m, node, c, r, w, parent=None, mat="Metal", rings=2, segs=20,
               spider=False):
    """A road roller's drum: a wide smooth cylinder with a dark hub band, its
    own node, origin on the axle."""
    c = V(*c)
    bm, fin = part(m, node, node + "_Drum", mat)
    add_cone(bm, c, X, r, r, w, segs)
    fin()
    bm, fin = part(m, node, node + "_Bands", "Engine")
    for i in range(rings):
        off = (i - (rings - 1) * 0.5) * (w * 0.5)
        add_ring(bm, c + X * off, X, r * 0.962, r - 0.003, 0.035, segs)
    fin()
    bm, fin = part(m, node, node + "_Hub", "Hub")
    add_cone(bm, c, X, r * 0.30, r * 0.30, w + 0.06, 12)
    fin()
    if spider:
        # A drum end is a SMOOTH PLATE with a hub boss and a bolt circle.
        # Spokes across it made the roller read as a four-wheeled tractor.
        bm, fin = part(m, node, node + "_Boss", "Engine")
        for sk in (-1.0, 1.0):
            add_cone(bm, c + X * (sk * (w * 0.5 + 0.030)), X, r * 0.34, r * 0.30,
                     0.10, 12)
            add_ring(bm, c + X * (sk * (w * 0.5 + 0.014)), X, r * 0.40, r * 0.48,
                     0.035, segs)
        fin()
        bm, fin = part(m, node, node + "_Bolts", "Metal")
        for sk in (-1.0, 1.0):
            for i in range(8):
                a = 2.0 * PI * i / 8.0
                u = Y * COS(a) + Z * SIN(a)
                add_cone(bm, c + X * (sk * (w * 0.5 + 0.026)) + u * (r * 0.22), X,
                         0.036, 0.036, 0.05, 6)
        fin()
    m.mesh_node(node, parent=parent, center=c)


# ==========================================================================
#  CRAWLER TRACKS -- a stadium of shoes round a sprocket and an idler, with
#  the frame and rollers inside it. The whole unit is one node so the game
#  can rock it; the SPROCKET is its own node so something visibly turns.
# ==========================================================================
SHOE_T = 0.060          # a track shoe's plate thickness
GROUSER_PROUD = 0.014   # how far the bar stands off the shoe: the machine
                        # RIDES on its grousers, so this is also the lift


def stadium(z_front, z_rear, r, t):
    """Point + outward normal at parameter t in [0,1) round a track's path:
    two half circles (the idler at z_front, the sprocket at z_rear, both of
    radius r) joined by two straights. Returns ((y, z), (ny, nz), curved) with
    y measured from the BOTTOM of the belt's centreline; `curved` says whether
    the station is on an arc, where a straight shoe cuts the corner."""
    straight = z_front - z_rear
    arc = PI * r
    total = 2.0 * (straight + arc)
    s = (t % 1.0) * total
    if s < straight:                      # along the BOTTOM, front -> rear
        return (0.0, z_front - s), (-1.0, 0.0), False
    s -= straight
    if s < arc:                           # round the REAR sprocket
        a = s / r
        return (r - r * COS(a), z_rear - r * SIN(a)), (-COS(a), -SIN(a)), True
    s -= arc
    if s < straight:                      # along the TOP, rear -> front
        return (2.0 * r, z_rear + s), (1.0, 0.0), False
    s -= straight
    a = s / r                             # round the FRONT idler
    return (r + r * COS(a), z_front + r * SIN(a)), (COS(a), SIN(a)), True


def crawler(m, node, x, z_front, z_rear, r=0.42, w=0.44, shoes=30,
            frame_mat="Engine", parent=None, sprocket_node=None):
    """One track unit centred on the flank x, its belt running between the
    idler at z_front and the sprocket at z_rear, both of radius `r`. The
    node's origin is on the GROUND under the unit's middle, and the grouser
    tips -- not the shoe plates -- are what touches y = 0.

    Returns the axle height, which is what the rest of the machine stacks on.
    """
    zc = (z_front + z_rear) * 0.5
    y0 = GROUSER_PROUD                    # the belt's own bottom, above ground
    axle = y0 + r
    ground = V(x, 0.0, zc)

    def at(t):
        (py, pz), (ny, nz), curved = stadium(z_front, z_rear, r, t)
        return V(x, py + y0, pz), V(0.0, ny, nz), V(0.0, -nz, ny), curved

    # --- the belt: shoes outward-faced onto the path, grousers proud of them
    per = 2.0 * (z_front - z_rear) + 2.0 * PI * r
    seg = per / float(shoes)
    # A straight shoe chorded across an arc bulges past the path by its own
    # sagitta -- on the bottom run, that is the machine sunk into the road.
    sag_s = math.sqrt(r * r + (seg * 0.51) ** 2) - r
    sag_g = math.sqrt(r * r + (seg * 0.17) ** 2) - r
    bm, fin = part(m, node, node + "_Shoes", "Track")
    for i in range(shoes):
        p, n, tang, curved = at((i + 0.5) / float(shoes))
        add_box(bm, p - n * (SHOE_T * 0.5 + (sag_s if curved else 0.0)),
                (w, SHOE_T, seg * 1.02), axes=(X, n, tang))
    fin()
    bm, fin = part(m, node, node + "_Grousers", "Grouser")
    for i in range(0, shoes, 2):
        p, n, tang, curved = at((i + 0.5) / float(shoes))
        add_box(bm, p + n * (GROUSER_PROUD * 0.5 - 0.006 - (sag_g if curved else 0.0)),
                (w * 0.86, GROUSER_PROUD + 0.012, seg * 0.34), axes=(X, n, tang))
    fin()
    # --- frame, rollers, idler -------------------------------------------
    bm, fin = part(m, node, node + "_Frame", frame_mat, bevel=0.03)
    add_box(bm, V(x, axle, zc), (w * 0.62, r * 1.30, (z_front - z_rear) + r * 0.9))
    fin()
    bm, fin = part(m, node, node + "_Rollers", "Hub")
    for i in range(4):
        z = z_rear + (z_front - z_rear) * (i + 0.5) / 4.0
        add_cone(bm, V(x, y0 + r * 0.42, z), X, r * 0.38, r * 0.38, w * 0.66, 10)
    add_cone(bm, V(x, axle, z_front), X, r * 0.82, r * 0.82, w * 0.70, 14)   # idler
    fin()
    bm, fin = part(m, node, node + "_Guard", frame_mat, bevel=0.02)
    add_box(bm, V(x, y0 + r * 1.86, zc), (w * 0.80, 0.07, (z_front - z_rear) * 0.86))
    fin()
    m.mesh_node(node, parent=parent, center=ground)
    # --- the sprocket, its own spinning node ------------------------------
    sn = sprocket_node or (node + "Sprocket")
    sc = V(x, axle, z_rear)
    bm, fin = part(m, sn, sn + "_Hub", "Hub")
    add_cone(bm, sc, X, r * 0.60, r * 0.60, w * 0.72, 14)
    fin()
    bm, fin = part(m, sn, sn + "_Teeth", "Steel")
    for i in range(10):
        a = 2.0 * PI * i / 10.0
        u = Y * COS(a) + Z * SIN(a)
        t = -Y * SIN(a) + Z * COS(a)
        add_box(bm, sc + u * (r * 0.80), (0.07, 0.10, w * 0.52), axes=(u, t, X))
    fin()
    m.mesh_node(sn, parent=node, center=sc)
    return axle


# ==========================================================================
#  HYDRAULIC RAM -- a barrel that AIMS and a rod that really slides out of
#  it. `name` is an empty at the ram's base with +Z down the ram; the game
#  aims that empty at the far anchor and slides `<name>Rod` along local +Z.
# ==========================================================================
def ram(m, name, base, tip, parent=None, r=0.055, rod_r=0.032, barrel=0.55,
        mat="Engine", rod_mat="Metal", pin=(1, 0, 0), mirror_x=None):
    """Returns the ram's length. Three nodes: `name` (empty at the base pin,
    +Z down the ram), `<name>Mesh` (the barrel, fixed to it) and `<name>Rod`
    (the sliding rod, home position = fully seated -- the game slides it
    along the empty's local +Z).

    `pin` is the pin's axis, which the two eyes wrap round. `mirror_x`, when
    given, draws a SECOND barrel and rod at -x too, so a mirrored pair of
    rams is one node pair and not two.
    """
    base, tip = V(*base), V(*tip)
    d = tip - base
    L_ = d.length
    u = d.normalized()
    pin = V(*pin).normalized()
    xh = pin if abs(pin.dot(u)) < 0.9 else V(0, 1, 0)
    m.empty(name, base, parent=parent, zdir=u, xhint=xh)
    bl = L_ * barrel
    offs = [V(0, 0, 0)]
    if mirror_x is not None:
        offs = [X * mirror_x, X * -mirror_x]
    bm, fin = part(m, name + "Mesh", name + "_Barrel", mat)
    for o in offs:
        add_cone(bm, base + o + u * (bl * 0.5), u, r, r, bl, 10)
        add_ring(bm, base + o, pin, rod_r * 0.72, r * 1.15, r * 1.7, 8)
    fin()
    m.mesh_node(name + "Mesh", parent=name, center=base)
    bm, fin = part(m, name + "Rod", name + "_Rod", rod_mat)
    for o in offs:
        add_cone(bm, base + o + u * ((bl + L_) * 0.5), u, rod_r, rod_r, L_ - bl, 8)
        add_ring(bm, tip + o, pin, rod_r * 0.60, rod_r * 1.75, rod_r * 2.1, 8)
    fin()
    m.mesh_node(name + "Rod", parent=name, center=base)
    return L_


# ==========================================================================
#  OPERATOR CAB -- the glass box every machine sits in. Posts, glass, roof,
#  a seat and a console, plus the door line so it reads as a door.
# ==========================================================================
def operator_cab(m, G, c, size, mat="Machine", glass="Glass", post=0.09,
                 seat=True, door_x=None, roof_lip=0.05, floor=True, sides=True):
    """`c` is the cab's centre, `size` = (width, height, depth). The glass is
    inset ON_PANEL inside the posts so no pane is ever flush with a frame."""
    cx, cy, cz = c
    w, h, d = size
    hw, hh, hd = w * 0.5, h * 0.5, d * 0.5
    if floor:
        boxes(m, G, "CabFloor", "Engine",
              [((cx, cy - hh + 0.034, cz), (w - 0.04, 0.06, d - 0.04))])
    bm, fin = part(m, G, "CabPosts", mat, bevel=0.015)
    for sx in (-1.0, 1.0):
        for sz in (-1.0, 1.0):
            add_box(bm, V(cx + sx * (hw - post * 0.5), cy, cz + sz * (hd - post * 0.5)),
                    (post, h, post))
    fin()
    boxes(m, G, "CabRoof", mat,
          [((cx, cy + hh + 0.030, cz), (w + roof_lip, 0.07, d + roof_lip))], bevel=0.02)
    boxes(m, G, "CabRoofTrim", "Engine",
          [((cx, cy + hh - 0.035, cz), (w - 0.03, 0.04, d - 0.03))])
    # Every pane sits `gi` INSIDE the posts' outer faces. Glass flush with its
    # own frame is the commonest z-fight in a cab, and it strobes on a phone.
    gi, g_in = 0.008, post + ON_PANEL
    bm, fin = part(m, G, "CabGlass", glass)
    add_box(bm, V(cx, cy + 0.02, cz + hd - 0.025 - gi), (w - g_in, h - 0.16, 0.05))
    add_box(bm, V(cx, cy + 0.02, cz - hd + 0.025 + gi), (w - g_in, h - 0.16, 0.05))
    if sides:
        for sx in (-1.0, 1.0):
            add_box(bm, V(cx + sx * (hw - 0.025 - gi), cy + 0.02, cz),
                    (0.05, h - 0.16, d - g_in))
    fin()
    if not sides:
        # Open flanks get a CAGE instead of a pane: three bars a side, which
        # is the shape that says "you can see the operator" at 40 px.
        bm, fin = part(m, G, "CabCageBars", "Engine")
        for sx in (-1.0, 1.0):
            for k in range(3):
                add_box(bm, V(cx + sx * (hw - 0.035), cy - hh + 0.34 + k * (h - 0.50) * 0.5,
                              cz), (0.06, 0.07, d - g_in))
            for sz in (-1.0, 1.0):
                add_box(bm, V(cx + sx * (hw - 0.035), cy + 0.02, cz + sz * (hd - post)),
                        (0.06, h - 0.20, 0.07))
        fin()
    if door_x is not None:
        bm, fin = part(m, G, "CabDoor", "Engine")
        add_box(bm, V(cx + door_x * (hw - 0.012), cy - 0.02, cz - hd * 0.10),
                (0.03, h - 0.20, d * 0.52))
        fin()
        bm, fin = part(m, G, "CabHandle", "Metal")
        add_tube(bm, V(cx + door_x * (hw + 0.03), cy - 0.05, cz - hd * 0.36),
                 V(cx + door_x * (hw + 0.03), cy + 0.06, cz - hd * 0.36), 0.018, 6)
        fin()
    if seat:
        boxes(m, G, "Seat", "Plastic",
              [((cx, cy - hh + 0.30, cz - hd * 0.16), (0.34, 0.10, 0.34)),
               ((cx, cy - hh + 0.52, cz - hd * 0.16 - 0.17), (0.34, 0.44, 0.10))],
              bevel=0.02)
        boxes(m, G, "Console", "Engine",
              [((cx, cy - hh + 0.30, cz + hd * 0.48), (w * 0.60, 0.20, 0.14))], bevel=0.02)
        bm, fin = part(m, G, "Levers", "Accent")
        for sx in (-1.0, 1.0):
            add_tube(bm, V(cx + sx * 0.20, cy - hh + 0.36, cz + hd * 0.30),
                     V(cx + sx * 0.20, cy - hh + 0.62, cz + hd * 0.22), 0.022, 6)
        fin()


def beacon(m, node, pos, parent=None, r=0.075, h=0.11, stalk=0.09):
    """The amber beacon, its own node so it can spin, origin at the dome's
    base. Every machine in this fleet wears one."""
    p = V(*pos)
    bm, fin = part(m, node, node + "_Stalk", "Engine")
    add_cone(bm, p + Y * (stalk * 0.5 - 0.01), Y, 0.030, 0.030, stalk, 8)
    fin()
    bm, fin = part(m, node, node + "_Lens", "Yellow")
    add_cone(bm, p + Y * (stalk + h * 0.5), Y, r, r * 0.82, h, 10)
    fin()
    bm, fin = part(m, node, node + "_Cap", "Metal")
    add_cone(bm, p + Y * (stalk + h + 0.012), Y, r * 0.84, r * 0.70, 0.03, 10)
    fin()
    m.mesh_node(node, parent=parent, center=p)


def work_lamps(m, G, pname, spec, mat="Light", housing="Engine", r=0.075):
    """Round work lamps on a bracket: `spec` = [(pos, zdir), ...]."""
    bm, fin = part(m, G, pname + "Housing", housing)
    for pos, zdir in spec:
        u = V(*zdir).normalized()
        add_cone(bm, V(*pos) - u * 0.035, u, r * 1.15, r * 1.15, 0.09, 10)
    fin()
    bm, fin = part(m, G, pname, mat)
    for pos, zdir in spec:
        u = V(*zdir).normalized()
        add_cone(bm, V(*pos) + u * 0.020, u, r, r * 0.92, 0.035, 10)
    fin()


def stack(m, G, pname, base, h=0.62, r=0.055, mat="Engine", cap=True):
    """An exhaust stack up the back of the cab, with its rain cap."""
    b = V(*base)
    bm, fin = part(m, G, pname, mat)
    add_cone(bm, b + Y * (h * 0.5), Y, r, r * 0.88, h, 8)
    add_cone(bm, b + Y * 0.04, Y, r * 1.35, r * 1.35, 0.08, 8)
    if cap:
        add_cone(bm, b + Y * (h + 0.03), Y, r * 1.5, r * 1.5, 0.045, 8)
    fin()


# ==========================================================================
#  TRUCK PARTS -- shared by every road machine in the fleet.
# ==========================================================================
def truck_frame(m, G, z0, z1, y=0.72, x=0.56, t=(0.17, 0.26)):
    """Two chassis rails and their cross members: what every truck here is
    built on, and the reason a body can sit clear of the wheels."""
    bm, fin = part(m, G, "Frame", "Engine")
    for sx in (-1.0, 1.0):
        add_box(bm, V(sx * x, y, (z0 + z1) * 0.5), (t[0], t[1], z1 - z0))
    n = max(2, int((z1 - z0) / 1.3))
    for i in range(n):
        z = z0 + (z1 - z0) * (i + 0.5) / n
        add_box(bm, V(0.0, y, z), (x * 2.0 - t[0], t[1] * 0.62, 0.12))
    fin()


def truck_mirrors(m, G, x, y, z, head=(0.13, 0.34, 0.08), arm=0.16):
    bm, fin = part(m, G, "MirrorArms", "Engine")
    for sx in (-1.0, 1.0):
        add_tube(bm, V(sx * (x - arm), y + 0.10, z), V(sx * x, y + 0.10, z), 0.022, 6)
        add_tube(bm, V(sx * x, y - 0.16, z), V(sx * x, y + 0.20, z), 0.020, 6)
    fin()
    boxes(m, G, "MirrorHeads", "Plastic",
          [((x + head[0] * 0.5, y, z), head)], bevel=0.015, mirror=True)


def trough(m, group, pname, p0, p1, r, mat="Steel", segs=7, rim="Machine"):
    """A half-pipe from p0 to p1, open side UP: a chute's own shape."""
    p0, p1 = V(*p0), V(*p1)
    d = p1 - p0
    ax = d.normalized()
    side = ax.cross(Y).normalized()
    up = side.cross(ax).normalized()
    bm, fin = part(m, group, pname, mat)
    add_shell(bm, (p0 + p1) * 0.5, ax, -up, side, r - 0.035, r,
              RAD(-94.0), RAD(94.0), segs, d.length)
    fin()
    # The rims are TUBES, not boxes -- a rolled edge is what a real chute has.
    # They stop 25 mm short of each end: a cap in the same plane as the
    # shell's own end face is a z-fight, whatever shape drew it.
    bm, fin = part(m, group, pname + "_Rims", rim)
    for sk in (-1.0, 1.0):
        add_tube(bm, p0 + side * (sk * r) + ax * 0.025,
                 p1 + side * (sk * r) - ax * 0.025, 0.045, 8)
    fin()


def lattice(bm, p0, p1, half, bays, leg_r=0.045, brace_r=0.028, chord=True):
    """A square lattice tower/jib from p0 to p1: four legs at +-`half` in the
    two directions across the run, horizontals at every bay and one diagonal
    per face per bay. This is what makes a crane read as a crane and not as a
    stick, and it is only tubes."""
    p0, p1 = V(*p0), V(*p1)
    d = p1 - p0
    ax = d.normalized()
    e1 = ax.cross(Y)
    if e1.length < 1e-6:
        e1 = Vector(X)
    e1 = e1.normalized()
    e2 = ax.cross(e1).normalized()
    corners = [(1, 1), (1, -1), (-1, -1), (-1, 1)]

    def at(t, c):
        return p0 + d * t + e1 * (c[0] * half) + e2 * (c[1] * half)

    for c in corners:
        add_tube(bm, at(0.0, c), at(1.0, c), leg_r, 6)
    for i in range(bays + 1):
        t = i / float(bays)
        if chord or i in (0, bays):
            for k in range(4):
                add_tube(bm, at(t, corners[k]), at(t, corners[(k + 1) % 4]), brace_r, 6)
    for i in range(bays):
        t0, t1 = i / float(bays), (i + 1) / float(bays)
        for k in range(4):
            a, b = corners[k], corners[(k + 1) % 4]
            if i % 2 == 0:
                add_tube(bm, at(t0, a), at(t1, b), brace_r, 6)
            else:
                add_tube(bm, at(t0, b), at(t1, a), brace_r, 6)


def cable_and_hook(m, top, drop, parent=None, r=0.045, hook_r=0.26, block=True):
    """`Cable`, a thin rope whose origin is its TOP (the game scales it down
    its own -Y to pay out), and `Hook` under it, origin at the block's top
    where the cable meets it. Returns the hook's tip."""
    top = V(*top)
    bm, fin = part(m, "Cable", "Cable_Rope", "Metal")
    add_cone(bm, V(top.x, top.y - drop * 0.5, top.z), Y, r, r, drop, 6)
    fin()
    m.mesh_node("Cable", parent=parent, center=top)
    eye = V(top.x, top.y - drop, top.z)
    # A real hook BLOCK: two cheek plates round a sheave, then the hook.
    # This is the part a child reaches for, so it is the chunkiest thing on
    # the machine, not the first to disappear.
    bm, fin = part(m, "Hook", "Hook_Block", "Engine", bevel=0.025)
    if block:
        for sx in (-1.0, 1.0):
            add_box(bm, V(eye.x + sx * 0.17, eye.y - 0.26, eye.z), (0.09, 0.52, 0.34))
        add_box(bm, V(eye.x, eye.y - 0.46, eye.z), (0.43, 0.16, 0.34))
        add_box(bm, V(eye.x, eye.y - 0.05, eye.z), (0.43, 0.12, 0.30))
    fin()
    bm, fin = part(m, "Hook", "Hook_Sheave", "Hub")
    if block:
        add_cone(bm, V(eye.x, eye.y - 0.26, eye.z), X, 0.20, 0.20, 0.20, 12)
        add_ring(bm, V(eye.x, eye.y - 0.26, eye.z), X, 0.16, 0.215, 0.07, 12)
    fin()
    bm, fin = part(m, "Hook", "Hook_J", "Metal")
    y0 = eye.y - (0.54 if block else 0.10)
    c = V(eye.x, y0 - 0.20 - hook_r, eye.z)
    add_cone(bm, V(eye.x, y0 - 0.10, eye.z), Y, 0.075, 0.075, 0.22, 8)
    pts = [c + Y * (COS(RAD(a)) * hook_r) + Z * (SIN(RAD(a)) * hook_r)
           for a in (0.0 + 28.0 * i for i in range(11))]
    for a, b in zip(pts, pts[1:]):
        add_tube(bm, a, b, 0.062, 6)
    add_cone(bm, pts[-1], (pts[-1] - pts[-2]).normalized(), 0.062, 0.014, 0.14, 6)
    fin()
    m.mesh_node("Hook", parent=parent, center=eye)
    return pts[-1]


def outrigger(m, node, base, sx, reach=0.70, beam=(0.16, 0.16), pad_r=0.20,
              parent=None, mat="Machine"):
    """One outrigger: a beam out to |x| = base.x + sx*reach, a jack down to
    the ground and a pad on it, all ONE node whose origin is the beam's root,
    so the game slides it along its own +/-X to stow it. Drawn DEPLOYED."""
    b = V(*base)
    tip = V(b.x + sx * reach, b.y, b.z)
    bm, fin = part(m, node, node + "_Beam", mat, bevel=0.02)
    add_box(bm, (b + tip) * 0.5, (reach + 0.10, beam[1], beam[0]))
    fin()
    bm, fin = part(m, node, node + "_Jack", "Metal")
    add_cone(bm, V(tip.x, b.y * 0.5 + 0.06, tip.z), Y, 0.055, 0.055, b.y - 0.10, 8)
    fin()
    bm, fin = part(m, node, node + "_Pad", "Engine")
    add_cone(bm, V(tip.x, 0.055, tip.z), Y, pad_r, pad_r * 0.86, 0.11, 10)
    fin()
    m.mesh_node(node, parent=parent, center=b)


# ==========================================================================
#  BUCKETS
# ==========================================================================
#  Sweep angles are measured from +Y toward +Z, so 0 = up, 90 = forward,
#  180 = down, 270 = back. A bucket's shell runs from its LIP (a little past
#  forward-down) round the bottom to the top of its back plate; the mouth is
#  the chord left over, facing up and forward.
def _rim(p, a, r):
    return V(p.x, p.y + COS(a) * r, p.z + SIN(a) * r)


def dig_bucket(m, node, pivot, w=0.90, r=0.62, a0=RAD(104.0), a1=RAD(258.0),
               back=0.075, teeth=5, parent=None, mat="Machine",
               tooth_mat="Wear", segs=9, ears=True):
    """An excavator bucket, its own node, origin at the PIN it hangs on.
    `a0` is the lip and `a1` the top of the back plate. Teeth stand off the
    lip along its own radius, so they point where the bucket digs. Returns
    the lip's centre point."""
    p = V(*pivot)
    bm, fin = part(m, node, node + "_Shell", mat)
    add_shell(bm, p, X, Y, Z, r - back, r, a0, a1, segs, w)
    fin()
    bm, fin = part(m, node, node + "_Sides", mat)
    for sx in (-1.0, 1.0):
        add_sector(bm, p + X * (sx * (w * 0.5 + 0.019)), X, Y, Z, r - back - 0.005,
                   a0, a1, segs, 0.038)
    fin()
    if ears:
        bm, fin = part(m, node, node + "_Ears", "Engine")
        for sx in (-1.0, 1.0):
            add_sector(bm, p + X * (sx * w * 0.26), X, Y, Z, r * 0.46,
                       a1 - RAD(66.0), a1 - RAD(3.0), 5, 0.055)
        add_tube(bm, p + X * (w * 0.32), p - X * (w * 0.32), 0.045, 8)
        fin()
    lip = _rim(p, a0, r - back * 0.5)
    u = V(0.0, COS(a0), SIN(a0))
    t = V(0.0, -SIN(a0), COS(a0))
    bm, fin = part(m, node, node + "_Lip", "Wear")
    add_box(bm, lip + u * 0.014, (w + 0.032, 0.058, 0.10), axes=(X, u, t))
    fin()
    if teeth:
        bm, fin = part(m, node, node + "_Teeth", tooth_mat)
        for i in range(teeth):
            off = (i - (teeth - 1) * 0.5) * (w / float(teeth))
            add_cone(bm, lip + u * 0.105 + X * off, u, 0.046, 0.018, 0.14, 4,
                     phase=RAD(45.0))
        fin()
    m.mesh_node(node, parent=parent, center=p)
    return lip


def loader_bucket(m, node, pivot, w=1.90, r=0.66, a0=RAD(94.0), a1=RAD(236.0),
                  back=0.070, teeth=0, parent=None, mat="Machine", segs=8,
                  bolt_edge=True, ribs=True):
    """A wide front-loader bucket: shallower sweep, a straight `Wear` cutting
    edge and (optionally) bolt-on teeth. Origin at the pin."""
    p = V(*pivot)
    bm, fin = part(m, node, node + "_Shell", mat)
    add_shell(bm, p, X, Y, Z, r - back, r, a0, a1, segs, w)
    fin()
    bm, fin = part(m, node, node + "_Sides", mat)
    for sx in (-1.0, 1.0):
        add_sector(bm, p + X * (sx * (w * 0.5 + 0.017)), X, Y, Z, r - back - 0.005,
                   a0, a1, segs, 0.034)
    fin()
    lip = _rim(p, a0, r - back * 0.5)
    u = V(0.0, COS(a0), SIN(a0))
    t = V(0.0, -SIN(a0), COS(a0))
    if bolt_edge:
        bm, fin = part(m, node, node + "_Edge", "Wear")
        add_box(bm, lip + u * 0.022, (w + 0.028, 0.072, 0.11), axes=(X, u, t))
        fin()
    if ribs:
        bm, fin = part(m, node, node + "_Ribs", "Engine")
        for sx in (-1.0, 1.0):
            for k in (0.20, 0.40):
                add_sector(bm, p + X * (sx * w * k), X, Y, Z, r + 0.028, r_in=r - 0.02,
                           a0=a1 - RAD(58.0), a1=a1 - RAD(3.0), segs=5, thick=0.070)
        fin()
    if teeth:
        bm, fin = part(m, node, node + "_Teeth", "Wear")
        for i in range(teeth):
            off = (i - (teeth - 1) * 0.5) * (w / float(teeth))
            add_cone(bm, lip + u * 0.110 + X * off, u, 0.050, 0.020, 0.15, 4,
                     phase=RAD(45.0))
        fin()
    m.mesh_node(node, parent=parent, center=p)
    return lip


# ==========================================================================
#  Z-FIGHT CHECK -- ported unchanged in spirit from Car Fixer's
#  make_vehicles.py: two parts whose faces share a plane strobe on a real
#  screen, and it is invisible in a still render, so it is CHECKED.
# ==========================================================================
COPLANAR_NORMAL_DOT = 0.999
COPLANAR_GAP = 0.001          # 1 mm
COPLANAR_AREA = 5e-6          # 5 mm^2
_AABB_SLACK = 0.01


def _face_data(obj, poly):
    verts = [C3 @ obj.data.vertices[vi].co for vi in poly.vertices]
    return C3 @ poly.normal, verts


def _project2d(verts, normal, origin):
    ref = Z if abs(normal.z) < 0.9 else X
    u = normal.cross(ref).normalized()
    v = normal.cross(u)
    return [((p - origin).dot(u), (p - origin).dot(v)) for p in verts]


def _clip_poly(subject, clip):
    """Sutherland-Hodgman; either polygon may wind either way."""
    def area2(poly):
        s = 0.0
        for i in range(len(poly)):
            x0, y0 = poly[i]
            x1, y1 = poly[(i + 1) % len(poly)]
            s += x0 * y1 - x1 * y0
        return s
    if area2(clip) < 0.0:
        clip = list(reversed(clip))
    out = subject
    n = len(clip)
    for i in range(n):
        if len(out) < 3:
            return []
        cx0, cy0 = clip[i]
        cx1, cy1 = clip[(i + 1) % n]
        ex, ey = cx1 - cx0, cy1 - cy0

        def inside(p, cx0=cx0, cy0=cy0, ex=ex, ey=ey):
            return (p[0] - cx0) * ey - (p[1] - cy0) * ex <= 1e-12

        def isect(p0, p1, cx0=cx0, cy0=cy0, ex=ex, ey=ey):
            dx, dy = p1[0] - p0[0], p1[1] - p0[1]
            denom = dx * ey - dy * ex
            if abs(denom) < 1e-15:
                return p1
            t = ((cx0 - p0[0]) * ey - (cy0 - p0[1]) * ex) / denom
            return (p0[0] + t * dx, p0[1] + t * dy)

        inp = out
        out = []
        for j in range(len(inp)):
            cur, prev = inp[j], inp[j - 1]
            cur_in, prev_in = inside(cur), inside(prev)
            if cur_in:
                if not prev_in:
                    out.append(isect(prev, cur))
                out.append(cur)
            elif prev_in:
                out.append(isect(prev, cur))
    return out


def _poly_area(poly):
    if len(poly) < 3:
        return 0.0
    s = 0.0
    for i in range(len(poly)):
        x0, y0 = poly[i]
        x1, y1 = poly[(i + 1) % len(poly)]
        s += x0 * y1 - x1 * y0
    return abs(s) * 0.5


def check_coplanar(machine):
    """Pairs of DIFFERENT parts with a face pair parallel, same-facing, within
    COPLANAR_GAP of one plane and overlapping by more than COPLANAR_AREA.
    Returns (part_a, part_b, area, gap, normal, point), worst first."""
    faces = []
    for objs in machine.groups.values():
        for o in objs:
            if o.type != "MESH":
                continue
            for poly in o.data.polygons:
                if poly.area < 1e-9:
                    continue
                n, verts = _face_data(o, poly)
                lo = Vector((min(p.x for p in verts), min(p.y for p in verts),
                             min(p.z for p in verts)))
                hi = Vector((max(p.x for p in verts), max(p.y for p in verts),
                             max(p.z for p in verts)))
                faces.append((o.name, n, verts[0], verts, lo, hi))
    pairs = {}
    nf = len(faces)
    for i in range(nf):
        name_a, na, origin_a, verts_a, lo_a, hi_a = faces[i]
        poly_a = None
        for j in range(i + 1, nf):
            name_b, nb, origin_b, verts_b, lo_b, hi_b = faces[j]
            if name_a == name_b:
                continue
            if na.dot(nb) < COPLANAR_NORMAL_DOT:
                continue
            s = _AABB_SLACK
            if (lo_a.x > hi_b.x + s or lo_b.x > hi_a.x + s or
                    lo_a.y > hi_b.y + s or lo_b.y > hi_a.y + s or
                    lo_a.z > hi_b.z + s or lo_b.z > hi_a.z + s):
                continue
            gap = abs(na.dot(origin_b - origin_a))
            if gap > COPLANAR_GAP:
                continue
            if abs(na.y) > 0.999 and abs(origin_a.y) < 0.02:
                continue        # both faces are on the ground, facing down
            if poly_a is None:
                poly_a = _project2d(verts_a, na, origin_a)
            poly_b = _project2d(verts_b, na, origin_a)
            area = _poly_area(_clip_poly(poly_a, poly_b))
            if area > 1e-9:
                key = (name_a, name_b) if name_a <= name_b else (name_b, name_a)
                acc = pairs.setdefault(key, [0.0, gap, na, origin_a])
                acc[0] += area
                acc[1] = min(acc[1], gap)
    hits = [(a, b, area, gap, n, o) for (a, b), (area, gap, n, o) in pairs.items()
            if area > COPLANAR_AREA]
    hits.sort(key=lambda h: -h[2])
    return hits


# ==========================================================================
#  GLB node contract check -- read back out of the exported file.
# ==========================================================================
def glb_world(path):
    js = L.glb_json(path)
    nodes = js.get("nodes", [])
    world = {}

    def walk(i, pm):
        mtx = pm @ L.node_matrix(nodes[i])
        world[nodes[i].get("name", "?")] = mtx
        for c in nodes[i].get("children", []):
            walk(c, mtx)
    from mathutils import Matrix
    for scene in js.get("scenes", []):
        for r in scene.get("nodes", []):
            walk(r, Matrix.Identity(4))
    return js, world


def check_nodes(name, path, want):
    """Every node in `want` must exist in the GLB. Returns (ok, missing)."""
    js, world = glb_world(path)
    missing = [n for n in want if n not in world]
    if missing:
        log("%s: MISSING NODES %s" % (name, ", ".join(missing)))
    return (not missing), missing
