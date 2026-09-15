"""Shared Blender helpers for Car Fixer's cartoon garage (copied from tree-chop 2026-09-06).

Used by tools/make_equipment.py (and usable by the older make_woodchipper /
make_stump_grinder scripts' successors). Everything is authored in GODOT
coordinates (Y up, X/Z horizontal, metres) and converted to Blender's Z-up
frame on the way into the mesh, so every number in a builder can be read
straight off a design sketch. Machines face +Z unless a builder says otherwise.

A `Machine` collects parts into named groups; each group becomes ONE mesh node
in the exported GLB. Groups can be parented to marker empties (or to other
groups) and re-centred on a pivot, so the game can rotate or slide them by
name: glTF node transforms ARE Godot Node3D transforms.

The export is verified by parsing the GLB back as raw JSON: every node must
have the parent asked for, and every empty the exact basis asked for.
"""
import json
import math
import os
import struct

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector

# --------------------------------------------------------------------------
# Godot (Y-up) <-> Blender (Z-up) change of basis.
#   C  : blender -> godot      (bx, by, bz) -> (bx, bz, -by)
#   CI : godot   -> blender    (gx, gy, gz) -> (gx, -gz, gy)
# --------------------------------------------------------------------------
C3 = Matrix(((1, 0, 0), (0, 0, 1), (0, -1, 0)))
CI3 = C3.transposed()
C4 = C3.to_4x4()
CI4 = CI3.to_4x4()

X = Vector((1.0, 0.0, 0.0))
Y = Vector((0.0, 1.0, 0.0))
Z = Vector((0.0, 0.0, 1.0))


def g2b(v):
    return CI3 @ Vector(v)


def V(*a):
    return Vector(a)


def nrm(*a):
    return Vector(a).normalized()


def log(*a):
    print("EQUIP", *a)


# --------------------------------------------------------------------------
# Palette: the woodchipper's colours, so every machine reads as one family.
# sRGB as seen on screen; converted to linear for glTF (Godot converts back).
# --------------------------------------------------------------------------
MATERIALS = {
    "Body":    (0.95, 0.45, 0.08),   # safety orange
    "Engine":  (0.20, 0.21, 0.24),   # dark grey engine / frames
    "Tyre":    (0.07, 0.07, 0.08),   # black rubber
    "Hub":     (0.58, 0.60, 0.64),   # mid grey hubs & fittings
    "Metal":   (0.80, 0.82, 0.85),   # pale metal: blades, tubes, teeth
    "Accent":  (0.86, 0.11, 0.09),   # red grips, knobs, caps
    "Caliper": (0.84, 0.16, 0.12),   # (unused since 2026-09-08: a red caliper vanished into a red car's arch; the caliper is Steel)
    "Pad":     (0.62, 0.58, 0.52),   # a fresh brake pad's friction block; worn is painted black in Godot
    "Disc":    (0.30, 0.31, 0.34),   # cutter / saw discs
    "Wood":    (0.62, 0.44, 0.26),   # timber parts (sawhorse)
    "WoodDark": (0.26, 0.17, 0.09),  # the shadowed end of a timber part: the
                                     # same brown the HUD draws its outlines in,
                                     # so a wooden thing can step hard in value
                                     # without stepping out of the wood
    "Glass":   (0.62, 0.80, 0.92),   # cab windows, lamps
    "Belt":    (0.12, 0.12, 0.13),   # conveyor rubber
    "Rope":    (0.93, 0.88, 0.72),   # starter cord / lashings: cream, a shade
                                     # under the drawn rope so a knot modelled
                                     # in it never out-glares the Line2D it ties
    "Preview": (0.55, 0.38, 0.22),   # preview-only stand-ins (never exported)
    # ---- Car Fixer additions (frozen 2026-09-06; see docs/DESIGN.md) ----
    "Paint":   (0.86, 0.16, 0.12),   # vehicle body panels ONLY: the game recolours
                                     # every material named Equip_Paint at load
    "Light":   (0.98, 0.95, 0.72),   # headlamps, work lamps
    "Tail":    (0.92, 0.12, 0.10),   # tail lamps
    "Plastic": (0.15, 0.15, 0.16),   # bumpers, grilles, mirrors, dark trim
    "Concrete": (0.64, 0.64, 0.62),  # garage floor and apron
    "Wall":    (0.88, 0.87, 0.82),   # painted block walls, ceiling
    "Steel":   (0.42, 0.46, 0.52),   # galvanised shelving, door tracks, racks
    "Yellow":  (0.98, 0.78, 0.12),   # bay lines, safety stripes, jack stands
    "Blue":    (0.20, 0.42, 0.78),   # a second machine colour: compressor tank, balancer
    "Cardboard": (0.72, 0.56, 0.36), # parts boxes on the shelves
}
MATS = {}


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def build_materials():
    MATS.clear()
    for name, rgb in MATERIALS.items():
        lin = tuple(srgb_to_linear(c) for c in rgb)
        mat = bpy.data.materials.new("Equip_" + name)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = (lin[0], lin[1], lin[2], 1.0)
            bsdf.inputs["Roughness"].default_value = 0.62
            bsdf.inputs["Metallic"].default_value = 0.0
        mat.diffuse_color = (lin[0], lin[1], lin[2], 1.0)
        mat.roughness = 0.62
        mat.metallic = 0.0
        MATS[name] = mat


# --------------------------------------------------------------------------
# Geometry helpers. All take GODOT-space coordinates.
# --------------------------------------------------------------------------
def frame(x_dir, y_dir):
    """Right-handed orthonormal frame from two (roughly) perpendicular hints."""
    x = Vector(x_dir).normalized()
    y = Vector(y_dir)
    y = (y - x * y.dot(x)).normalized()
    z = x.cross(y)
    return x, y, z


def perp_in_plane(d, up=Y):
    """A unit vector perpendicular to d, as close to `up` as possible."""
    d = Vector(d).normalized()
    u = Vector(up)
    u = (u - d * u.dot(d))
    if u.length < 1e-6:
        u = Vector(X)
        u = (u - d * u.dot(d))
    return u.normalized()


def add_box(bm, center, sizes, axes=None):
    """Box centred at `center`; `sizes` measured along `axes` (default Godot XYZ)."""
    if axes is None:
        axes = (X, Y, Z)
    ax, ay, az = (Vector(a) for a in axes)
    c = Vector(center)
    hx, hy, hz = (s * 0.5 for s in sizes)
    corners = []
    for sz in (-1, 1):
        for sy in (-1, 1):
            for sx in (-1, 1):
                corners.append(bm.verts.new(c + ax * (sx * hx) + ay * (sy * hy) + az * (sz * hz)))

    def vi(x, y, z):
        return corners[x + 2 * y + 4 * z]
    quads = [
        (vi(0, 0, 0), vi(1, 0, 0), vi(1, 1, 0), vi(0, 1, 0)),
        (vi(0, 0, 1), vi(0, 1, 1), vi(1, 1, 1), vi(1, 0, 1)),
        (vi(0, 0, 0), vi(0, 1, 0), vi(0, 1, 1), vi(0, 0, 1)),
        (vi(1, 0, 0), vi(1, 0, 1), vi(1, 1, 1), vi(1, 1, 0)),
        (vi(0, 0, 0), vi(0, 0, 1), vi(1, 0, 1), vi(1, 0, 0)),
        (vi(0, 1, 0), vi(1, 1, 0), vi(1, 1, 1), vi(0, 1, 1)),
    ]
    for q in quads:
        bm.faces.new(q)


def add_box_between(bm, p0, p1, w, h, up=Y):
    """Box running from point p0 to p1 with cross-section w (sideways) x h (along `up`)."""
    p0 = Vector(p0)
    p1 = Vector(p1)
    d = p1 - p0
    dn = d.normalized()
    u = perp_in_plane(dn, up)
    s = dn.cross(u)
    add_box(bm, (p0 + p1) * 0.5, (w, h, d.length), axes=(s, u, dn))


def add_cone(bm, center, axis, r1, r2, length, segs, cap1=True, cap2=True, phase=0.0):
    """Cylinder / truncated cone centred at `center`, symmetric about `axis`."""
    a = Vector(axis).normalized()
    ref = Z if abs(a.z) < 0.9 else X
    e1 = a.cross(ref).normalized()
    e2 = a.cross(e1).normalized()
    c = Vector(center)
    p0 = c - a * (length * 0.5)
    p1 = c + a * (length * 0.5)
    r_a, r_b = [], []
    for i in range(segs):
        th = 2.0 * math.pi * i / segs + phase
        off = e1 * math.cos(th) + e2 * math.sin(th)
        r_a.append(bm.verts.new(p0 + off * r1))
        r_b.append(bm.verts.new(p1 + off * r2))
    for i in range(segs):
        j = (i + 1) % segs
        bm.faces.new((r_a[i], r_a[j], r_b[j], r_b[i]))
    if cap1:
        bm.faces.new(list(reversed(r_a)))
    if cap2:
        bm.faces.new(r_b)


def add_tube(bm, p0, p1, r, segs=8):
    """Cylinder from point p0 to point p1."""
    p0 = Vector(p0)
    p1 = Vector(p1)
    d = p1 - p0
    add_cone(bm, (p0 + p1) * 0.5, d, r, r, d.length, segs)


def add_arc_shell(bm, c0, r0, c1, r1, e_a, e_b, a0, a1, segs):
    """Open strip between two circles (angles a0..a1 measured from e_a toward e_b)."""
    e_a = Vector(e_a)
    e_b = Vector(e_b)
    ring0, ring1 = [], []
    for i in range(segs + 1):
        th = a0 + (a1 - a0) * i / float(segs)
        off = e_a * math.cos(th) + e_b * math.sin(th)
        ring0.append(bm.verts.new(Vector(c0) + off * r0))
        ring1.append(bm.verts.new(Vector(c1) + off * r1))
    for i in range(segs):
        bm.faces.new((ring0[i], ring0[i + 1], ring1[i + 1], ring1[i]))


def add_ring(bm, center, axis, r_in, r_out, length, segs, phase=0.0):
    """Flat washer: an annulus of thickness `length` about `axis`, with a real
    hole through it. `add_cone` can only give a solid disc and `add_arc_shell`
    an open strip, so anything that has to be seen THROUGH -- a key's bow, a
    split ring, a bezel -- needs this."""
    a = Vector(axis).normalized()
    ref = Z if abs(a.z) < 0.9 else X
    e1 = a.cross(ref).normalized()
    e2 = a.cross(e1).normalized()
    c = Vector(center)
    p0 = c - a * (length * 0.5)
    p1 = c + a * (length * 0.5)
    back_in, back_out, front_in, front_out = [], [], [], []
    for i in range(segs):
        th = 2.0 * math.pi * i / segs + phase
        off = e1 * math.cos(th) + e2 * math.sin(th)
        back_in.append(bm.verts.new(p0 + off * r_in))
        back_out.append(bm.verts.new(p0 + off * r_out))
        front_in.append(bm.verts.new(p1 + off * r_in))
        front_out.append(bm.verts.new(p1 + off * r_out))
    for i in range(segs):
        j = (i + 1) % segs
        bm.faces.new((back_out[i], back_out[j], front_out[j], front_out[i]))
        bm.faces.new((back_in[j], back_in[i], front_in[i], front_in[j]))
        bm.faces.new((back_in[i], back_in[j], back_out[j], back_out[i]))
        bm.faces.new((front_out[i], front_out[j], front_in[j], front_in[i]))


def add_prism(bm, tri, axis, length):
    """Triangle `tri` (3 points) extruded symmetrically along `axis` by `length`."""
    a = Vector(axis).normalized() * (length * 0.5)
    p = [Vector(t) for t in tri]
    v0 = [bm.verts.new(q - a) for q in p]
    v1 = [bm.verts.new(q + a) for q in p]
    bm.faces.new(v0)
    bm.faces.new(list(reversed(v1)))
    for i in range(3):
        j = (i + 1) % 3
        bm.faces.new((v0[i], v0[j], v1[j], v1[i]))


def add_teeth(bm, center, axis, r_center, count, size, stagger=0.0, phase=0.0):
    """`count` tooth boxes around a circle of radius r_center in the plane
    perpendicular to `axis`; `size` = (radial, tangential, axial)."""
    a = Vector(axis).normalized()
    ref = Z if abs(a.z) < 0.9 else X
    e1 = a.cross(ref).normalized()
    e2 = a.cross(e1).normalized()
    c = Vector(center)
    for i in range(count):
        th = 2.0 * math.pi * i / count + phase
        radial = e1 * math.cos(th) + e2 * math.sin(th)
        tangent = -e1 * math.sin(th) + e2 * math.cos(th)
        off = a * (stagger if i % 2 == 0 else -stagger)
        add_box(bm, c + radial * r_center + off, size, axes=(radial, tangent, a))


# --------------------------------------------------------------------------
# One machine = groups of parts -> mesh nodes, plus marker empties.
# --------------------------------------------------------------------------
class Machine:
    def __init__(self, name):
        self.name = name
        self.groups = {}          # mesh node name -> [part objects]
        self.parents = {}         # node name -> parent node name
        self.centers = {}         # mesh node name -> Godot point to re-centre on
        self.empties = {}         # empty name -> (pos, zdir, xhint)
        self.previews = []        # preview-only objects (rendered, not exported)
        self.notes = []           # free text lines for the summary
        self.tris = 0
        # Opt-in (Car Fixer DESIGN 22, the dent): mesh node name -> [(key
        # name, fn(obj, key_name))], each fn run on the JOINED, re-centred
        # object just before export, to add a shape key (a glTF morph target
        # Godot drives as a blend shape). Empty for every machine that does
        # not ask, so their GLBs export exactly as before.
        self.shape_keys = {}

    # ---- authoring -------------------------------------------------------
    def part(self, group, pname, mat, bevel=0.0, solidify=0.0, preview=False):
        """Returns (bmesh, finish); finish() turns it into an object in `group`."""
        bm = bmesh.new()

        def finish():
            return self._emit(group, pname, bm, mat, bevel, solidify, preview)
        return bm, finish

    def mesh_node(self, group, parent=None, center=None):
        """Declares a group's parent (default: the root) and pivot."""
        self.groups.setdefault(group, [])
        self.parents[group] = parent or self.name
        if center is not None:
            self.centers[group] = Vector(center)

    def empty(self, name, pos, parent=None, zdir=(0, 0, 1), xhint=(1, 0, 0)):
        self.empties[name] = (Vector(pos), Vector(zdir), Vector(xhint))
        self.parents[name] = parent or self.name

    def note(self, text):
        self.notes.append(text)

    def shape_key(self, group, name, fn):
        """Asks for `fn(obj, name)` to be run on `group`'s joined object at
        export, to add the shape key `name` to it (see `self.shape_keys`)."""
        self.shape_keys.setdefault(group, []).append((name, fn))

    def _emit(self, group, pname, bm, mat, bevel, solidify, preview):
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bmesh.ops.transform(bm, matrix=CI4, verts=bm.verts)
        mesh = bpy.data.meshes.new(pname)
        bm.to_mesh(mesh)
        bm.free()
        for p in mesh.polygons:
            p.use_smooth = False
        obj = bpy.data.objects.new(pname, mesh)
        bpy.context.scene.collection.objects.link(obj)
        mesh.materials.append(MATS[mat])
        if solidify:
            m = obj.modifiers.new("solidify", "SOLIDIFY")
            m.thickness = solidify
            m.offset = 0.0
            m.use_even_offset = True
        if bevel:
            m = obj.modifiers.new("bevel", "BEVEL")
            m.width = bevel
            m.segments = 1
            m.limit_method = "ANGLE"
            m.angle_limit = math.radians(35)
            m.miter_outer = "MITER_ARC"
        if preview:
            self.previews.append(obj)
        else:
            self.groups.setdefault(group, []).append(obj)
            self.parents.setdefault(group, self.name)
        return obj

    # ---- build & export --------------------------------------------------
    def export(self, out_path, preview_dir=None, views=None):
        for objs in self.groups.values():
            for o in list(objs):
                apply_modifiers(o)
        for o in self.previews:
            apply_modifiers(o)
        nodes = {}
        root = bpy.data.objects.new(self.name, None)
        root.empty_display_type = "PLAIN_AXES"
        root.empty_display_size = 0.5
        bpy.context.scene.collection.objects.link(root)
        nodes[self.name] = root
        for group, objs in self.groups.items():
            if not objs:
                raise RuntimeError("%s: group %s has no parts" % (self.name, group))
            obj = join_group(objs, group)
            if group in self.centers:
                recenter(obj, self.centers[group])
            for key_name, fn in self.shape_keys.get(group, []):
                fn(obj, key_name)
                log("%s: shape key %s on %s (%d verts)" % (self.name, key_name, group, len(obj.data.vertices)))
            nodes[group] = obj
        for name, (pos, zdir, xhint) in self.empties.items():
            nodes[name] = make_empty(name, pos, zdir, xhint)
        for name, parent in self.parents.items():
            if name not in nodes:
                raise RuntimeError("%s: parent declared for unknown node %s" % (self.name, name))
            if parent not in nodes:
                raise RuntimeError("%s: node %s wants unknown parent %s" % (self.name, name, parent))
            parent_keep_world(nodes[name], nodes[parent])
        for name, obj in nodes.items():
            if name != self.name and obj.parent is None:
                parent_keep_world(obj, root)
        for name, obj in nodes.items():
            if obj.type == "MESH":
                log("%s: mesh %-12s verts %5d polys %5d slots %s" % (
                    self.name, name, len(obj.data.vertices), len(obj.data.polygons),
                    [s.material.name.replace("Equip_", "") for s in obj.material_slots]))
        if preview_dir:
            render_previews(self, list(nodes.values()) + self.previews, preview_dir, views)
        out_dir = os.path.dirname(out_path)
        if out_dir:
            os.makedirs(out_dir, exist_ok=True)
        for o in bpy.data.objects:
            o.select_set(False)
        for o in nodes.values():
            o.select_set(True)
        bpy.context.view_layer.objects.active = root
        bpy.ops.export_scene.gltf(
            filepath=out_path,
            export_format="GLB",
            use_selection=True,
            export_yup=True,
            export_materials="EXPORT",
            export_animations=False,
            # Apply Modifiers is what prevents the glTF exporter from writing
            # shape keys; every modifier here was applied by hand above, so a
            # machine with a shape key exports the mesh it already is.
            export_apply=not self.shape_keys,
            export_morph=bool(self.shape_keys),
            export_morph_normal=bool(self.shape_keys),
            export_cameras=False,
            export_lights=False,
        )
        log("%s: exported %s (%d bytes)" % (self.name, out_path, os.path.getsize(out_path)))
        ok, tris = verify_glb(self, out_path)
        self.tris = tris
        return ok


def apply_modifiers(obj):
    if not obj.modifiers:
        return
    for o in bpy.context.selected_objects:
        o.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    for m in list(obj.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)
    for p in obj.data.polygons:
        p.use_smooth = False


def join_group(objs, name):
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name + "_Mesh"
    for p in obj.data.polygons:
        p.use_smooth = False
    return obj


def recenter(obj, center_g):
    """Moves the object's origin to a Godot-space point without moving the mesh,
    so a rotation of the node in Godot turns about that point."""
    c_b = g2b(center_g)
    for v in obj.data.vertices:
        v.co -= c_b
    obj.location = c_b


def parent_keep_world(child, parent):
    # A fresh `location` (recenter) is not in matrix_world until the view layer
    # updates; reading it stale put re-centred nodes back at the origin.
    bpy.context.view_layer.update()
    mw = child.matrix_world.copy()
    child.parent = parent
    child.matrix_parent_inverse = Matrix.Identity(4)
    child.matrix_world = mw


def godot_basis(zdir, xhint):
    z = Vector(zdir).normalized()
    x = Vector(xhint)
    x = (x - z * x.dot(z)).normalized()
    y = z.cross(x)
    return Matrix(((x.x, y.x, z.x, 0.0),
                   (x.y, y.y, z.y, 0.0),
                   (x.z, y.z, z.z, 0.0),
                   (0.0, 0.0, 0.0, 1.0)))


def make_empty(name, pos_g, zdir_g=(0, 0, 1), xhint_g=(1, 0, 0), size=0.25):
    obj = bpy.data.objects.new(name, None)
    obj.empty_display_type = "ARROWS"
    obj.empty_display_size = size
    bpy.context.scene.collection.objects.link(obj)
    mg = Matrix.Translation(Vector(pos_g)) @ godot_basis(zdir_g, xhint_g)
    obj.matrix_world = CI4 @ mg @ C4
    return obj


# --------------------------------------------------------------------------
# Previews (Workbench, no GPU needed). Camera auto-fits the machine's bounds.
# --------------------------------------------------------------------------
DEFAULT_VIEWS = {
    "hero": (1.0, 0.65, 1.15),     # front-left three-quarter (machines face +Z)
    "back": (-1.0, 0.55, -1.0),    # back-right three-quarter
}


def render_previews(machine, objs, preview_dir, views=None):
    os.makedirs(preview_dir, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    sh = scene.display.shading
    sh.light = "STUDIO"
    sh.color_type = "MATERIAL"
    sh.show_shadows = True
    sh.shadow_intensity = 0.30
    sh.show_cavity = True
    sh.cavity_type = "BOTH"
    sh.background_type = "VIEWPORT"
    sh.background_color = (0.62, 0.76, 0.88)
    try:
        scene.view_settings.view_transform = "Standard"
        scene.view_settings.look = "None"
        scene.view_settings.exposure = 0.0
        scene.view_settings.gamma = 1.0
    except Exception as exc:
        log("view transform:", exc)
    scene.render.resolution_x = 640
    scene.render.resolution_y = 480
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"
    if "PreviewCam" not in bpy.data.objects:
        cd = bpy.data.cameras.new("PreviewCam")
        cd.lens = 45
        scene.collection.objects.link(bpy.data.objects.new("PreviewCam", cd))
    cam = bpy.data.objects["PreviewCam"]
    scene.camera = cam
    # Bounds in Godot space.
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        if o.type != "MESH":
            continue
        for corner in o.bound_box:
            w = C3 @ (o.matrix_world @ Vector(corner))
            lo = Vector((min(lo.x, w.x), min(lo.y, w.y), min(lo.z, w.z)))
            hi = Vector((max(hi.x, w.x), max(hi.y, w.y), max(hi.z, w.z)))
    centre = (lo + hi) * 0.5
    size = max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z, 0.5)
    dist = size * 1.45 + 0.6
    for label, direction in (views or DEFAULT_VIEWS).items():
        d = Vector(direction).normalized()
        loc_g = centre + d * dist
        loc = g2b(loc_g)
        tgt = g2b(centre)
        cam.location = loc
        cam.rotation_euler = (tgt - loc).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(preview_dir, "%s_%s.png" % (machine.name, label))
        bpy.ops.render.render(write_still=True)
    log("%s: previews in %s (size %.2f m)" % (machine.name, preview_dir, size))


# --------------------------------------------------------------------------
# GLB verification: parent links and marker bases, straight from the file.
# --------------------------------------------------------------------------
def glb_json(path):
    with open(path, "rb") as f:
        data = f.read()
    assert data[:4] == b"glTF", "not a GLB"
    off = 12
    while off < len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        chunk = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:
            return json.loads(chunk.decode("utf-8"))
        off += 8 + clen
    raise RuntimeError("no JSON chunk")


def node_matrix(n):
    if "matrix" in n:
        m = n["matrix"]
        return Matrix(((m[0], m[4], m[8], m[12]),
                       (m[1], m[5], m[9], m[13]),
                       (m[2], m[6], m[10], m[14]),
                       (m[3], m[7], m[11], m[15])))
    t = Vector(n.get("translation", (0.0, 0.0, 0.0)))
    q = n.get("rotation", (0.0, 0.0, 0.0, 1.0))
    s = Vector(n.get("scale", (1.0, 1.0, 1.0)))
    rot = Quaternion((q[3], q[0], q[1], q[2])).to_matrix().to_4x4()
    scl = Matrix.Diagonal((s.x, s.y, s.z, 1.0))
    return Matrix.Translation(t) @ rot @ scl


def verify_glb(machine, path):
    js = glb_json(path)
    nodes = js.get("nodes", [])
    world = {}
    parent_of = {}

    def walk(i, parent, pm):
        m = pm @ node_matrix(nodes[i])
        world[i] = m
        parent_of[i] = parent
        for c in nodes[i].get("children", []):
            walk(c, i, m)

    for scene in js.get("scenes", []):
        for r in scene.get("nodes", []):
            walk(r, None, Matrix.Identity(4))
    names = {i: n.get("name", "?") for i, n in enumerate(nodes)}
    by_name = {}
    for i, n in names.items():
        by_name.setdefault(n, i)
    ok = True
    for name, parent in machine.parents.items():
        if name not in by_name:
            log("%s: MISSING node %s" % (machine.name, name))
            ok = False
            continue
        p = names.get(parent_of.get(by_name[name]))
        if p != parent:
            log("%s: BAD PARENT %s -> %s (want %s)" % (machine.name, name, p, parent))
            ok = False
    for name, (pos, zdir, xhint) in machine.empties.items():
        if name not in by_name:
            continue
        m = world[by_name[name]]
        want = godot_basis(zdir, xhint)
        got_pos = m.translation
        err = max(abs(m[r][c] - want[r][c]) for r in range(3) for c in range(3))
        perr = (got_pos - pos).length
        if err > 1e-3 or perr > 1e-3:
            log("%s: BAD MARKER %s pos err %.4f basis err %.4f" % (machine.name, name, perr, err))
            ok = False
    tris = 0
    for mesh in js.get("meshes", []):
        for prim in mesh["primitives"]:
            tris += js["accessors"][prim["indices"]]["count"] // 3
    tree = [(names[i], names.get(parent_of.get(i))) for i in range(len(nodes))]
    log("%s: nodes %s" % (machine.name, tree))
    log("%s: %s triangles=%d materials=%s" % (
        machine.name, "OK" if ok else "FAIL", tris,
        [m.get("name", "").replace("Equip_", "") for m in js.get("materials", [])]))
    return ok, tris


def fresh_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.world = bpy.data.worlds.new("PreviewWorld")
    build_materials()
