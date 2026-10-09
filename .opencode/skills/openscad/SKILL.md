---
name: openscad
description: Design, validate, render, and export 3D-printable parts with OpenSCAD using the osc CLI (osc.mjs) — compile-check .scad, render PNG previews to visually critique, export STL/3MF, and verify mesh stats (bounding box, volume, watertight). Use when the user asks for OpenSCAD or .scad work, a 3D model, parametric part, bracket/enclosure/mount/gear, STL export, 3D printing, or anything expressible as CSG geometry.
---

# OpenSCAD workflow (osc CLI)

This skill is self-contained: `osc.mjs` sits next to this SKILL.md. Run commands as
`node <this-skill-folder>/osc.mjs <command> ...` — the skill loader reports the base
directory for this skill, so use that path. The script is dependency-free (Node 18+)
and wraps the native OpenSCAD binary (auto-detected at `C:\Program Files\OpenSCAD`
on Windows, `/Applications/OpenSCAD.app` on macOS, PATH elsewhere; override with
`--openscad <path>` or the `OPENSCAD` env var). All commands work from any working
directory and exit 0 on success, 1 on failure, 2 on usage error.

## The loop (always follow this order)

1. **Write** parametric SCAD to a `.scad` file in the project (mm units).
2. **Check** — fast parse/evaluate, does not build meshes:
   ```
   node <skill-folder>/osc.mjs check part.scad
   ```
   Shows `ERROR`/`WARNING` lines and any `echo()` output. Exit 0 = compiles.
3. **Preview** — render PNG(s), then **Read the PNG file** so you can actually see the model:
   ```
   node <skill-folder>/osc.mjs preview part.scad
   node <skill-folder>/osc.mjs preview part.scad --view all
   ```
4. **Critique** the image: proportions, feature presence, placement/alignment, orientation. Apply the smallest fix, go to step 2.
5. **Render** when previews look right:
   ```
   node <skill-folder>/osc.mjs render part.scad
   ```
   Watch for `Simple: yes` in the output (mesh validity from CGAL).
6. **Verify stats** — never trust dimensions from a PNG; trust numbers:
   ```
   node <skill-folder>/osc.mjs stats part.stl
   ```
   Confirms bounding box dimensions match the request exactly, volume, watertightness, and that the mesh is a single connected body (Shells: 1).
7. Deliver only after stats confirm dimensions and previews look right.

## Multi-part models

Never deliver an assembly as one STL: touching or pinned parts fuse into one mesh and the slicer can't split them back into logical parts. Give the model a `part` selector that puts each part in its print orientation, and echo the print set:

```
// [file name, [[variable, value], ...]] — one entry per physical part
echo(print_parts = [["base", [["part", "base"]]], ["lid", [["part", "lid"], ["vented", true]]]]);
```

```
node <skill-folder>/osc.mjs export model.scad    # -> model_parts/base.stl, lid.stl
```

`export` renders each entry to its own file, then fails if any part is not a single watertight body. Build `print_parts` from the same parameters as the assembly view so the set always matches it. User `-D` values apply to every part; entry overrides win.

## Views

| View | Camera | Use to verify |
| --- | --- | --- |
| `iso` (default) | 3D from front-right-above | Overall shape, proportions |
| `front` | looking from -Y, +Z up, +X right | Heights, steps, profiles |
| `top` | looking down, +X right, +Y up-screen | Plan layout, hole positions |
| `right` | looking at +X face | Lateral features |
| `back`/`left`/`bottom` | opposite sides | Hidden features |
| `--view all` | iso, front, right, top in one call | Quick full inspection |

Add `--ortho` for orthographic projection when judging proportions/dimensions (perspective can visually distort tall features near the frame edge); `--size 1200x900` for detail; `--render` for full CGAL render (slower, exact) instead of fast OpenCSG preview.

## Parameter changes without editing files

```
node <skill-folder>/osc.mjs check part.scad -D "width=60" -D "hole_d=5.2"
```
Overrides top-level variables — good for variants and sweeps (render each variant to its own `--out`).

## SCAD rules for agents

- Millimeters. Set `$fn = 48` (or 64 for visible curves) once at top.
- Use named variables for every dimension the user mentioned; keep values easy to override via `-D`.
- Center geometry at origin when practical; otherwise sit on Z=0 print bed.
- Cutters in `difference()` must extend past surfaces (e.g. `translate(z - 1)` + extra height). Never end a cutter exactly tangent to a surface — coincident/tangent faces cause CGAL non-manifold errors.
- Cutters that slice a ring/tube can disconnect it into floating shells — check `stats` reports `Shells: 1`.
- Debug values with `echo(width=width)` — output shows in `check`.
- Prefer `import()` only for external geometry; keep designs self-contained otherwise.

## Printability checklist (before delivering STL)

- Flat, stable face down (or note needed supports to the user).
- Min wall thickness ~1.2 mm (3 perimeters at 0.4 nozzle); holes ≥ 2 mm diameter where possible.
- Clearance for press/slide fits: add 0.2–0.4 mm per mating interface.
- Overhangs ≤ 45° from vertical, or chamfer/bridge them. `stats` reports every region that would need support, with its area and bounding box (`--overhang 50` if the user's printer handles more).

### Reducing supports (when the user asks for it)

Read the `Overhang` regions from `stats` (or the per-part total from `export`), map each bounding box back to a feature, fix the biggest first, re-render and compare totals.

| Region looks like | Usual fix |
| --- | --- |
| `sloped`, small, on the underside of a ledge or boss | 45° chamfer or `hull()` gusset under it |
| `flat` ceiling of a horizontal round hole | teardrop hole (point up), or flat-topped hole if under ~6 mm |
| `flat` tops of hex/polygon holes in a vertical wall | rotate the polygon so a vertex points up (`rotate(30)` for `$fn = 6`) |
| `flat`, spans between two walls | a bridge: fine up to ~10–15 mm, otherwise add a centre rib |
| large, unavoidable in this orientation | flip the part or split it into pieces that each print flat |

Flat regions are often bridges, which print without support, so treat them as warnings. Don't trade away strength or fit to remove a few mm² that the slicer bridges anyway, and report the before/after totals.
- `stats` says watertight: yes, Shells: 1, and bounding box matches requested dimensions.

## Failure triage

- `check` fails with syntax error → fix the quoted line first; errors cascade.
- Preview renders blank → geometry likely empty (everything subtracted) or scale vs. `--viewall` issue; run `check`, then preview a single primitive to isolate.
- Render `WARNING: ` about non-manifold/holes → run `stats`; if not watertight, look for coincident faces or cutters exactly on surfaces.
- `stats` exits 1 → read the Shells/Watertight lines; fix the SCAD, never the STL.
- Slow render → reduce `$fn`, simplify, or raise `--timeout 600`.

## Do not

- Never hand-edit or "fix" STL contents; change the SCAD and re-render.
- Never deliver an STL without running `stats` and reading at least one preview PNG.