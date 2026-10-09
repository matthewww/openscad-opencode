# TODO

## Done

- **README "How it works"**: how `osc.mjs` drives OpenSCAD with no UI (`-o` plus the output extension picks the job), what the wrapper adds, and the headless Linux caveat for PNG previews.
- **`osc export`**: a model echoes `print_parts = [[name, [[variable, value], ...]], ...]`. `export` renders each entry to `<model>_parts/<name>.stl` and fails unless every part is a single watertight body. This replaces splitting a fused assembly STL in the slicer.
  - `examples/toolkitrc_v3` builds `print_parts` from the same parameters as the stack view. It exports 7 parts.
- **Overhang report** in `stats` (regions with area, bounding box, flat or sloped) and a per-part total in `export`. `--overhang <deg>` sets the limit (default 45). Covered by `npm test`.
- `SKILL.md`: "Multi-part models" and "Reducing supports" sections.
- `osc --help` works (it used to fail with "Unknown command").

## Next (small, ready to do)

- [ ] Reduce supports on toolkitrc v3, then compare totals before and after (seat 1811 mm², tray 958 mm²):
  - rotate the hexes in vertical walls 30° so a point faces up (removes the flat bridge tops)
  - chamfer or gusset under the tower pad blocks (about 232 mm² each)
- [ ] Add `print_parts` to `examples/toolkitrc_charger_stack.scad` (the drawer version)
- [ ] Only look up the OpenSCAD binary for commands that need it. `stats` currently fails on machines without OpenSCAD even though it never calls it.

## Later: discuss and plan

1. **Test orientations to reduce support.** Rotate the mesh through candidate orientations and score each one with the overhang metric. Candidates could be the 6 axis directions plus each large flat face turned down. Open questions: should `osc` report a suggested `rotate()` or apply it in the export? And how does this overlap with Orca's auto-orient?
2. **Account for layer direction when strength matters.** Layer lines are the weak axis. A part loaded in tension or bending across its layers can fail where the same part printed another way holds. This needs a way to state the load direction per part (maybe in `print_parts`), then trading support area against strength when scoring orientations.
3. **Study OrcaSlicer's orientation code.** Look at how its auto-orient works (Orca forked from Bambu Studio, whose orient code I believe is based on Tweaker-3; check this). Note the scoring terms (overhang area, bed contact area, height, first-layer area) and decide what to reuse or port.
