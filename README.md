# openscad-opencode

Self-contained [OpenSCAD](https://openscad.org) integration for agent tools: a dependency-free CLI (`osc.mjs`) plus an agent **skill** that encodes a closed-loop modeling workflow — check, render, visually critique previews, refine, export, and verify mesh stats.

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
| `stats part.stl` | Triangles, bounding box, volume, surface area, watertightness, connected shells, print weight estimate |
| `version` | OpenSCAD version |

Common options: `--view iso|front|back|left|right|top|bottom|all`, `--size 800x600`, `--out file`, `--ortho`, `--render`, `-D "name=value"` (repeatable), `--timeout <sec>`, `--strict`.

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