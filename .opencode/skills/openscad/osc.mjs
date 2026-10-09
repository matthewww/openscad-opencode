#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const VIEWS = {
  iso: [1000, -1000, 900],
  front: [0, -1000, 0],
  back: [0, 1000, 0],
  left: [-1000, 0, 0],
  right: [1000, 0, 0],
  top: [0, 0, 1000],
  bottom: [0, 0, -1000],
};
const ALL_VIEWS = ["iso", "front", "right", "top"];
const DENSITIES = { pla: 1.24, petg: 1.27, abs: 1.04, resin: 1.1 };

function die(msg, code = 1) {
  console.error(msg);
  process.exit(code);
}

function usage() {
  console.log(`osc - OpenSCAD CLI helper

Usage: node osc.mjs <command> [options] <file>

Commands:
  preview <file.scad>   Render PNG preview(s) you can open or attach to a chat
  render  <file.scad>   Export mesh (stl|3mf|off|amf)
  export  <file.scad>   Export each entry of the model's print_parts to its own file, then check each is one watertight body
  check   <file.scad>   Fast compile/evaluate check (errors, warnings, echo output)
  stats   <file.stl>    Mesh report: triangles, bounding box, volume, watertight
  version               Print OpenSCAD version

Options:
  --view <name|all>    iso|front|back|left|right|top|bottom|all (default: iso)
  --size <WxH>         preview image size (default: 800x600)
  --out <path>         output file, or folder for export (default: alongside input, export: <name>_parts/)
  --format <fmt>       render format (default: stl)
  --ortho              orthographic projection (recommended for proportion checks)
  --render             full CGAL render for previews instead of fast OpenCSG preview
  --colorscheme <n>    OpenSCAD color scheme
  -D, --define <v=e>   override a top-level variable (repeatable)
  --strict             (check) fail on warnings too
  --overhang <deg>     (stats, export) steepest printable overhang from vertical (default: 45)
  --timeout <sec>      per-invocation timeout (default: 300)
  --openscad <path>    path to openscad binary (default: $OPENSCAD or auto-detect)`);
  process.exit(2);
}

function parseArgs(argv) {
  const opts = { defines: [], _pos: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const next = () => {
      if (i + 1 >= argv.length) die(`Missing value for ${a}`, 2);
      return argv[++i];
    };
    if (a === "-D" || a === "--define") opts.defines.push(next());
    else if (a.startsWith("-D") && a.length > 2) opts.defines.push(a.slice(2));
    else if (a === "--out" || a === "-o") opts.out = next();
    else if (a === "--view") opts.view = next();
    else if (a === "--size") opts.size = next();
    else if (a === "--format") opts.format = next();
    else if (a === "--colorscheme") opts.colorscheme = next();
    else if (a === "--openscad") opts.openscad = next();
    else if (a === "--timeout") opts.timeout = Number(next());
    else if (a === "--overhang") opts.overhang = Number(next());
    else if (a === "--ortho") opts.ortho = true;
    else if (a === "--render") opts.render = true;
    else if (a === "--strict") opts.strict = true;
    else if (a === "-h" || a === "--help") usage();
    else if (a === "-") opts._pos.push(a);
    else if (a.startsWith("--")) die(`Unknown option: ${a}`, 2);
    else if (a.startsWith("-") && a.length > 1) die(`Unknown option: ${a}`, 2);
    else opts._pos.push(a);
  }
  for (const d of opts.defines) {
    if (!d.includes("=")) die(`Bad define "${d}" — expected name=value`, 2);
  }
  return opts;
}

function findOpenSCAD(override) {
  const cands = [];
  if (override) cands.push(override);
  if (process.env.OPENSCAD) cands.push(process.env.OPENSCAD);
  if (process.platform === "win32") {
    for (const root of [process.env["ProgramFiles"], process.env["ProgramFiles(x86)"]]) {
      if (!root) continue;
      cands.push(path.join(root, "OpenSCAD", "openscad.com"));
      cands.push(path.join(root, "OpenSCAD", "openscad.exe"));
    }
  } else if (process.platform === "darwin") {
    cands.push("/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD");
  } else {
    cands.push("/usr/bin/openscad", "/usr/local/bin/openscad");
  }
  cands.push("openscad");
  for (const c of cands) {
    const isPath = path.isAbsolute(c) || c.includes("/") || c.includes("\\");
    if (isPath) {
      if (fs.existsSync(c)) return c;
      continue;
    }
    const probe = spawnSync(c, ["--version"], { stdio: "ignore" });
    if (!probe.error) return c;
  }
  die("OpenSCAD executable not found. Install OpenSCAD, set OPENSCAD, or pass --openscad <path>.", 2);
}

function run(bin, args, timeoutSec) {
  const r = spawnSync(bin, args, {
    timeout: (timeoutSec > 0 ? timeoutSec : 300) * 1000,
    maxBuffer: 64 * 1024 * 1024,
  });
  return {
    status: r.status === null || r.status === undefined ? 1 : r.status,
    stdout: (r.stdout ?? Buffer.alloc(0)).toString("utf8"),
    stderr: (r.stderr ?? Buffer.alloc(0)).toString("utf8"),
    timedOut: Boolean(r.error && r.error.code === "ETIMEDOUT"),
  };
}

const LOG_RE =
  /^(ERROR|WARNING|ECHO|TRACE|Top level object is|Simple:|Vertices:|Facets:|Volumes:|Total rendering time)/;

function logLines(out, err) {
  return (out + "\n" + err)
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => LOG_RE.test(l));
}

function definesArgs(opts) {
  const args = [];
  for (const d of opts.defines) args.push("-D", d);
  return args;
}

function requireInput(opts, ext) {
  const file = opts._pos[0];
  if (!file) die(`Missing input file. See --help.`, 2);
  const src = path.resolve(file);
  if (!fs.existsSync(src)) die(`Input not found: ${src}`, 2);
  if (ext && !src.toLowerCase().endsWith(ext))
    die(`Expected a ${ext} file: ${src}`, 2);
  return src;
}

function outPath(src, opts, suffix, ext) {
  if (opts.out) return path.resolve(opts.out);
  const dir = path.dirname(src);
  const base = path.basename(src).replace(/\.(scad|escad|jscad)$/i, "");
  return path.join(dir, `${base}${suffix}${ext}`);
}

function cmdPreview(bin, opts) {
  const src = requireInput(opts, ".scad");
  const view = opts.view ?? "iso";
  const views =
    view === "all" ? ALL_VIEWS : VIEWS[view] ? [view] : null;
  if (!views) die(`Unknown view "${view}". Options: ${Object.keys(VIEWS).join(", ")}|all`, 2);
  if (views.length > 1 && opts.out) die(`--out cannot be combined with --view all`, 2);
  const [w, h] = String(opts.size ?? "800x600")
    .split(/[xX,]/)
    .map((n) => Number(n));
  if (!Number.isFinite(w) || !Number.isFinite(h) || w < 1 || h < 1)
    die(`Bad --size "${opts.size}" — expected WxH, e.g. 800x600`, 2);
  for (const v of views) {
    const out = outPath(src, opts, `-${v}`, ".png");
    const args = [
      "-o",
      out,
      `--imgsize=${w},${h}`,
      `--camera=${VIEWS[v].join(",")},0,0,0`,
      "--viewall",
      "--autocenter",
      ...(opts.ortho ? ["--projection=o"] : []),
      ...(opts.render ? ["--render=cgal"] : []),
      ...(opts.colorscheme ? [`--colorscheme=${opts.colorscheme}`] : []),
      ...definesArgs(opts),
      src,
    ];
    const r = run(bin, args, opts.timeout);
    const logs = logLines(r.stdout, r.stderr);
    if (r.timedOut) die(`preview timed out after ${opts.timeout}s`, 1);
    if (r.status !== 0 || logs.some((l) => l.startsWith("ERROR")) || !fs.existsSync(out)) {
      for (const l of logs) console.error(l);
      die(`preview failed (view: ${v})`, r.status || 1);
    }
    for (const l of logs) console.log(l);
    console.log(`wrote ${out} (${fs.statSync(out).size} bytes)`);
  }
}

function cmdRender(bin, opts) {
  const src = requireInput(opts, ".scad");
  const fmt = opts.format ?? "stl";
  if (!/^(stl|3mf|off|amf)$/i.test(fmt)) die(`Unsupported format "${fmt}" (stl|3mf|off|amf)`, 2);
  const out = outPath(src, opts, "", `.${fmt.toLowerCase()}`);
  const args = ["-o", out, ...definesArgs(opts), src];
  const r = run(bin, args, opts.timeout);
  const logs = logLines(r.stdout, r.stderr);
  if (r.timedOut) die(`render timed out after ${opts.timeout}s`, 1);
  if (r.status !== 0 || logs.some((l) => l.startsWith("ERROR")) || !fs.existsSync(out)) {
    for (const l of logs) console.error(l);
    die(`render failed`, r.status || 1);
  }
  for (const l of logs) console.log(l);
  console.log(`wrote ${out} (${fs.statSync(out).size} bytes)`);
}

// Evaluate without building geometry (.echo export); returns the exit status and log lines
function evaluate(bin, src, opts) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "osc-check-"));
  try {
    const echoPath = path.join(tmp, "out.echo");
    const args = [
      "-o",
      echoPath,
      ...definesArgs(opts),
      ...(opts.strict ? ["--hardwarnings"] : []),
      src,
    ];
    const r = run(bin, args, opts.timeout ?? 120);
    if (r.timedOut) die(`evaluation timed out after ${opts.timeout ?? 120}s`, 1);
    const echoText = fs.existsSync(echoPath) ? fs.readFileSync(echoPath, "utf8") : "";
    const lines = (echoText + "\n" + r.stdout + "\n" + r.stderr)
      .split(/\r?\n/)
      .map((l) => l.trim())
      .filter(Boolean);
    return { status: r.status, lines };
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}

function cmdCheck(bin, opts) {
  const src = requireInput(opts, ".scad");
  const { status, lines } = evaluate(bin, src, opts);
  const seen = new Set();
  for (const l of lines) {
    if (!seen.has(l) && /^(ERROR|WARNING|ECHO|TRACE)/.test(l)) {
      seen.add(l);
      console.log(l);
    }
  }
  const hasWarning = lines.some((l) => l.startsWith("WARNING"));
  const hasError = lines.some((l) => l.startsWith("ERROR"));
  if (status !== 0 || hasError || (opts.strict && hasWarning)) {
    console.log(`check: FAILED`);
    process.exit(status || 1);
  }
  console.log(`check: OK`);
}

// Turn a JSON value into an OpenSCAD literal for -D (strings, numbers, booleans, vectors)
const scadLiteral = (v) => JSON.stringify(v);

function cmdExport(bin, opts) {
  const src = requireInput(opts, ".scad");
  const ext = (opts.format ?? "stl").toLowerCase();
  if (!/^(stl|3mf|off|amf)$/.test(ext)) die(`Unsupported format "${ext}" (stl|3mf|off|amf)`, 2);
  const { status, lines } = evaluate(bin, src, opts);
  const errors = lines.filter((l) => l.startsWith("ERROR"));
  if (status !== 0 || errors.length) {
    for (const l of errors) console.error(l);
    die(`export failed: model does not evaluate`, status || 1);
  }
  const line = lines.find((l) => l.startsWith("ECHO: print_parts = "));
  if (!line)
    die(`No print_parts in ${path.basename(src)}. Add: echo(print_parts = [[name, [[variable, value], ...]], ...]);`, 2);
  let parts;
  try {
    parts = JSON.parse(line.slice("ECHO: print_parts = ".length));
  } catch {
    die(`Could not parse print_parts: ${line}`, 2);
  }
  const dir = opts.out ? path.resolve(opts.out) : outPath(src, {}, "_parts", "");
  fs.mkdirSync(dir, { recursive: true });
  let bad = 0;
  for (const [name, overrides] of parts) {
    if (!/^[\w-][\w.-]*$/.test(String(name))) die(`Bad part name "${name}" (letters, digits, - _ . only)`, 2);
    const out = path.join(dir, `${name}.${ext}`);
    const defs = overrides.flatMap(([k, v]) => ["-D", `${k}=${scadLiteral(v)}`]);
    // Part overrides come last, so they win over the user's -D values
    const r = run(bin, ["-o", out, ...definesArgs(opts), ...defs, src], opts.timeout);
    const logs = logLines(r.stdout, r.stderr);
    if (r.timedOut || r.status !== 0 || logs.some((l) => l.startsWith("ERROR")) || !fs.existsSync(out)) {
      for (const l of logs) console.error(l);
      die(`export failed on part "${name}"`, r.status || 1);
    }
    if (ext !== "stl") {
      console.log(`${name}: wrote ${out}`);
      continue;
    }
    const s = meshStats(fs.readFileSync(out), opts.overhang ?? 45);
    const ohArea = s.overhangs.reduce((n, g) => n + g.area, 0);
    const ok = s.openEdges === 0 && s.shells === 1;
    if (!ok) bad++;
    console.log(
      `${name}: ${s.size.map((n) => fmt(n, 1)).join(" x ")} mm, ${fmt(s.volume / 1000)} cm3, ` +
        `${ok ? "single watertight body" : `${s.shells} shell(s), ${s.openEdges} open edge(s)`}, ` +
        `${fmt(ohArea, 0)} mm2 overhang in ${s.overhangs.length} region(s)`
    );
  }
  console.log(`wrote ${parts.length} part(s) to ${dir}`);
  if (bad) process.exit(1);
}

function stlFormat(buf) {
  if (buf.length >= 84) {
    const n = buf.readUInt32LE(80);
    if (84 + 50 * n === buf.length) return "binary";
  }
  const head = buf.subarray(0, 2048).toString("latin1");
  if (/^\s*solid/i.test(head) && /facet/i.test(head)) return "ascii";
  if (buf.length >= 84) return "binary";
  die(`Not a valid STL file (${buf.length} bytes)`, 2);
}

function parseSTL(buf) {
  const verts = [];
  const tris = [];
  const vmap = new Map();
  const addVertex = (x, y, z, key, readFloat) => {
    let id = vmap.get(key);
    if (id === undefined) {
      id = verts.length / 3;
      verts.push(x, y, z);
      vmap.set(key, id);
    }
    return id;
  };
  if (stlFormat(buf) === "binary") {
    const n = buf.readUInt32LE(80);
    if (84 + 50 * n > buf.length) die(`Truncated binary STL (${buf.length} bytes, expected ${84 + 50 * n})`, 2);
    for (let i = 0; i < n; i++) {
      const off = 84 + i * 50;
      const tri = [];
      for (let v = 0; v < 3; v++) {
        const p = off + 12 + v * 12;
        const key = buf.toString("latin1", p, p + 12);
        tri.push(
          addVertex(
            buf.readFloatLE(p),
            buf.readFloatLE(p + 4),
            buf.readFloatLE(p + 8),
            key
          )
        );
      }
      tris.push(tri);
    }
  } else {
    const text = buf.toString("latin1");
    const re = /vertex\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)/g;
    let m;
    const tri = [];
    while ((m = re.exec(text))) {
      const x = Number(m[1]);
      const y = Number(m[2]);
      const z = Number(m[3]);
      tri.push(addVertex(x, y, z, `${x},${y},${z}`));
      if (tri.length === 3) {
        tris.push(tri.slice());
        tri.length = 0;
      }
    }
    if (tri.length !== 0) die(`Malformed ASCII STL: vertex count not a multiple of 3`, 2);
  }
  return { verts, tris };
}

function fmt(n, d = 2) {
  return n.toFixed(d);
}

function makeFind(parent) {
  return (x) => {
    while (parent[x] !== x) {
      parent[x] = parent[parent[x]];
      x = parent[x];
    }
    return x;
  };
}

// Downward faces past the overhang limit and off the bed, grouped into connected regions
function overhangs(verts, tris, nzs, areas, zmin, limitDeg) {
  const cut = -Math.sin((limitDeg * Math.PI) / 180);
  const hits = [];
  for (let i = 0; i < tris.length; i++) {
    if (!(nzs[i] < cut)) continue;
    if (tris[i].every((v) => verts[v * 3 + 2] - zmin < 0.01)) continue; // sits on the bed
    hits.push(i);
  }
  const parent = hits.map((_, k) => k);
  const find = makeFind(parent);
  const owner = new Map();
  hits.forEach((ti, k) => {
    for (const v of tris[ti]) {
      const o = owner.get(v);
      if (o === undefined) owner.set(v, k);
      else parent[find(k)] = find(o);
    }
  });
  const regions = new Map();
  hits.forEach((ti, k) => {
    const r = find(k);
    let g = regions.get(r);
    if (!g) regions.set(r, (g = { area: 0, flat: true, min: [Infinity, Infinity, Infinity], max: [-Infinity, -Infinity, -Infinity] }));
    g.area += areas[ti];
    if (nzs[ti] > -0.999) g.flat = false;
    for (const v of tris[ti])
      for (let a = 0; a < 3; a++) {
        g.min[a] = Math.min(g.min[a], verts[v * 3 + a]);
        g.max[a] = Math.max(g.max[a], verts[v * 3 + a]);
      }
  });
  return [...regions.values()].sort((a, b) => b.area - a.area);
}

function meshStats(buf, overhangDeg = 45) {
  const { verts, tris } = parseSTL(buf);
  const min = [Infinity, Infinity, Infinity];
  const max = [-Infinity, -Infinity, -Infinity];
  let volume = 0;
  let area = 0;
  let degenerate = 0;
  const und = new Map();
  const dir = new Map();
  const addEdge = (a, b) => {
    const ukey = a < b ? `${a},${b}` : `${b},${a}`;
    und.set(ukey, (und.get(ukey) ?? 0) + 1);
    const dkey = `${a},${b}`;
    dir.set(dkey, (dir.get(dkey) ?? 0) + 1);
  };
  const nzs = new Float64Array(tris.length);
  const areas = new Float64Array(tris.length);
  for (let t = 0; t < tris.length; t++) {
    const [a, b, c] = tris[t];
    const ax = verts[a * 3], ay = verts[a * 3 + 1], az = verts[a * 3 + 2];
    const bx = verts[b * 3], by = verts[b * 3 + 1], bz = verts[b * 3 + 2];
    const cx = verts[c * 3], cy = verts[c * 3 + 1], cz = verts[c * 3 + 2];
    for (const [v, axis] of [
      [ax, 0], [ay, 1], [az, 2],
      [bx, 0], [by, 1], [bz, 2],
      [cx, 0], [cy, 1], [cz, 2],
    ]) {
      if (v < min[axis]) min[axis] = v;
      if (v > max[axis]) max[axis] = v;
    }
    const ux = bx - ax, uy = by - ay, uz = bz - az;
    const vx = cx - ax, vy = cy - ay, vz = cz - az;
    const nx = uy * vz - uz * vy;
    const ny = uz * vx - ux * vz;
    const nz = ux * vy - uy * vx;
    const nlen = Math.hypot(nx, ny, nz);
    if (nlen === 0) degenerate++;
    area += nlen / 2;
    nzs[t] = nlen === 0 ? 0 : nz / nlen;
    areas[t] = nlen / 2;
    volume +=
      (ax * (by * cz - bz * cy) +
        ay * (bz * cx - bx * cz) +
        az * (bx * cy - by * cx)) / 6;
    addEdge(a, b);
    addEdge(b, c);
    addEdge(c, a);
  }
  let openEdges = 0;
  let badWinding = 0;
  for (const [key, count] of und) {
    if (count !== 2) {
      openEdges++;
      continue;
    }
    const [i, j] = key.split(",").map(Number);
    if (dir.get(`${i},${j}`) !== 1 || dir.get(`${j},${i}`) !== 1) badWinding++;
  }
  const parent = Array.from({ length: verts.length / 3 }, (_, i) => i);
  const find = makeFind(parent);
  for (const [a, b, c] of tris) {
    parent[find(a)] = find(b);
    parent[find(a)] = find(c);
  }
  const roots = new Set();
  for (let i = 0; i < verts.length / 3; i++) roots.add(find(i));
  return {
    triangles: tris.length,
    vertices: verts.length / 3,
    degenerate,
    min,
    max,
    size: [max[0] - min[0], max[1] - min[1], max[2] - min[2]],
    volume: Math.abs(volume),
    inverted: volume < 0,
    area,
    openEdges,
    badWinding,
    shells: roots.size,
    overhangs: overhangs(verts, tris, nzs, areas, min[2], overhangDeg),
  };
}

function cmdStats(opts) {
  const file = requireInput(opts, ".stl");
  const buf = fs.readFileSync(file);
  const format = stlFormat(buf);
  const limit = opts.overhang ?? 45;
  const { triangles, vertices, degenerate, min, max, size, volume: volumeAbs, inverted, area, openEdges, badWinding, shells, overhangs: oh } =
    meshStats(buf, limit);
  const cm3 = volumeAbs / 1000;
  console.log(`${path.basename(file)} - ${format} STL`);
  console.log(`Triangles:          ${triangles} (${degenerate} degenerate)`);
  console.log(`Unique vertices:    ${vertices}`);
  console.log(
    `Bounding box (mm):  ${fmt(size[0])} x ${fmt(size[1])} x ${fmt(size[2])}`
  );
  console.log(
    `  min:              ${fmt(min[0])}, ${fmt(min[1])}, ${fmt(min[2])}`
  );
  console.log(
    `  max:              ${fmt(max[0])}, ${fmt(max[1])}, ${fmt(max[2])}`
  );
  console.log(`Volume:             ${fmt(volumeAbs)} mm3 (${fmt(cm3)} cm3)`);
  console.log(`Surface area:       ${fmt(area)} mm2`);
  const watertight = openEdges === 0;
  if (watertight) {
    console.log(
      `Watertight:         yes - manifold${badWinding === 0 ? ", consistent winding" : ", INCONSISTENT winding"}`
    );
  } else {
    console.log(
      `Watertight:         NO - ${openEdges} open/non-manifold edge(s)`
    );
  }
  console.log(
    `Est. print weight:  ${fmt(cm3 * DENSITIES.pla)} g PLA / ${fmt(cm3 * DENSITIES.petg)} g PETG (100% infill)`
  );
  console.log(
    `Shells:             ${shells}${shells > 1 ? " - NOT A SINGLE BODY" : ""}`
  );
  const ohArea = oh.reduce((n, g) => n + g.area, 0);
  console.log(`Overhang > ${limit} deg: ${fmt(ohArea)} mm2 in ${oh.length} region(s), bed contact excluded`);
  for (const g of oh.slice(0, 8))
    console.log(
      `  ${fmt(g.area, 1).padStart(8)} mm2 ${g.flat ? "flat (bridge?)" : "sloped       "}` +
        `  x ${fmt(g.min[0], 1)}..${fmt(g.max[0], 1)}  y ${fmt(g.min[1], 1)}..${fmt(g.max[1], 1)}  z ${fmt(g.min[2], 1)}..${fmt(g.max[2], 1)}`
    );
  if (oh.length > 8) console.log(`  ... ${oh.length - 8} smaller region(s)`);
  if (inverted) console.log(`Note: negative volume - facet winding is inverted (mirrored STL?)`);
  if (!watertight || shells > 1) process.exit(1);
}

function cmdVersion(bin) {
  const r = run(bin, ["--version"], 30);
  const line = (r.stdout.trim() || r.stderr.trim()).split(/\r?\n/)[0];
  console.log(line || "unknown");
  if (r.status !== 0) process.exit(r.status);
}

function main() {
  const argv = process.argv.slice(2);
  if (argv.length === 0 || argv[0] === "-h" || argv[0] === "--help") usage();
  const cmd = argv[0];
  const opts = parseArgs(argv.slice(1));
  const bin = findOpenSCAD(opts.openscad);
  if (cmd === "preview") cmdPreview(bin, opts);
  else if (cmd === "render") cmdRender(bin, opts);
  else if (cmd === "export") cmdExport(bin, opts);
  else if (cmd === "check") cmdCheck(bin, opts);
  else if (cmd === "stats") cmdStats(opts);
  else if (cmd === "version") cmdVersion(bin);
  else die(`Unknown command "${cmd}". See --help.`, 2);
}

main();