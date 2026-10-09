# openscad-opencode

Self-contained [OpenSCAD](https://openscad.org) integration for agent tools: a dependency-free wrapper around OpenSCAD's command-line mode (`osc.mjs`) plus an agent **skill** that encodes a closed-loop modeling workflow — check, render, visually critique previews, refine, export, and verify mesh stats.

Works with [opencode](https://opencode.ai) out of the box (skill loader), and with any agent that can run shell commands and read images.

## Why CLI + skill instead of an MCP server

MCP servers for OpenSCAD exist mainly for clients without shell/filesystem access. If your agent already has a shell and can read PNGs, a small CLI plus a workflow skill does the same job natively: fast, full-featured OpenSCAD binary (not WASM), visible logs, and verification stats (bounding box, volume, watertightness, connected-shell count) that MCP servers don't provide.

## Requirements

- Node 18+
- OpenSCAD installed (auto-detected; override with `--openscad <path>` or the `OPENSCAD` env var)

## Install (opencode)

The skill folder is self-contained — `osc.mjs` ships inside it.

**Per project:** copy `.opencode/skills/openscad/` into your project root.

**Global:** point `skills.paths` at this repo's skill directory in `~/.config/opencode/opencode.json`:

```json
{
  "skills": {
    "paths": ["/path/to/openscad-opencode/.opencode/skills"]
  }
}
```

Optional: allow the CLI to run without approval prompts in a project's `opencode.json`:

```json
{
  "permission": {
    "bash": {
      "node *osc.mjs*": "allow"
    }
  }
}
```

Restart the agent after config changes.

**CLI anywhere:** `npm link` in this repo (exposes `osc` on PATH), or just run `node .opencode/skills/openscad/osc.mjs`.

## CLI usage

```
node .opencode/skills/openscad/osc.mjs <command> [options] <file>
```

| Command | Purpose |
| --- | --- |
| `check part.scad` | Fast parse/evaluate: errors, warnings, `echo()` output |
| `preview part.scad` | PNG preview, default `iso` view; `--view all` for 4 views |
| `render part.scad` | Export mesh (`--format stl|3mf|off|amf`) |
| `export model.scad` | Export each part listed in the model's `print_parts` echo to its own file in `model_parts/`, each checked to be a single watertight body. Import the folder into the slicer and let it arrange. |
| `stats part.stl` | Triangles, bounding box, volume, surface area, watertightness, connected shells, print weight estimate, regions that need support (`--overhang <deg>`, default 45) |
| `version` | OpenSCAD version |

Common options: `--view iso|front|back|left|right|top|bottom|all`, `--size 800x600`, `--out file`, `--ortho`, `--render`, `-D "name=value"` (repeatable), `--timeout <sec>`, `--strict`.

## How it works

`osc.mjs` is a thin wrapper around OpenSCAD's built-in command-line mode. Passing `-o <file>` makes OpenSCAD skip the GUI, evaluate the script, write the output and exit. The output extension selects the job:

| Extension | OpenSCAD does | Used by |
| --- | --- | --- |
| `.stl` `.3mf` `.off` `.amf` | Full geometry render, writes the mesh | `render` |
| `.png` | Renders the scene with `--camera`, `--imgsize`, `--viewall`, `--projection` | `preview` |
| `.echo` | Evaluates the script only, no geometry (fast) | `check` |

The wrapper adds what the raw binary lacks for agent use:

- **Binary discovery:** `--openscad`, then `$OPENSCAD`, then standard install paths, then `PATH`. On Windows it prefers `openscad.com` over `openscad.exe`. The `.exe` is a GUI-subsystem binary, so it detaches from the console and its output and exit code are lost.
- **Reliable failure detection:** OpenSCAD can exit 0 after script errors, so a run counts as failed on a non-zero exit, any `ERROR:` line, or a missing output file.
- **Filtered logs:** only `ERROR`, `WARNING`, `ECHO` and render-summary lines are printed.
- **Camera presets** for the named views.
- **Mesh stats** in plain JS (`stats` never calls OpenSCAD). It merges duplicate vertices, then checks that every edge is shared by exactly two triangles (watertight) in opposite directions (consistent winding), and counts shells with union-find. Volume comes from a signed tetrahedron sum.

Processes run via `spawnSync` with no shell, so `-D 'part="lid"'` needs no extra escaping on any platform.

**Headless Linux:** mesh and echo exports need no display. PNG export uses OpenGL, so on a machine with no display (CI, containers) wrap it in `xvfb-run` or use a recent OpenSCAD build with offscreen EGL support. Windows and macOS work as-is.

## The workflow the skill teaches

1. `check` — fast compile/eval check (errors, warnings, `echo()` output)
2. `preview` — render PNGs and **look at them** (agent reads the image)
3. critique → smallest fix → repeat
4. `render` — export STL (watch for `Simple: yes`)
5. `stats` — verify exact dimensions, watertightness, single shell
6. deliver

`stats` fails (exit 1) on non-watertight or multi-shell meshes — the two silent killers of agent-generated geometry (tangent cutters, rings sliced into floating pieces).

## Example

```
node .opencode/skills/openscad/osc.mjs check examples/bracket.scad
node .opencode/skills/openscad/osc.mjs preview examples/bracket.scad --view all
node .opencode/skills/openscad/osc.mjs render examples/bracket.scad
node .opencode/skills/openscad/osc.mjs stats examples/bracket.stl
```

## License

MIT