// Run: npm test (needs OpenSCAD). Checks the overhang metric on geometry with a known answer.
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const osc = path.join(import.meta.dirname, "..", ".opencode", "skills", "openscad", "osc.mjs");
const dir = fs.mkdtempSync(path.join(os.tmpdir(), "osc-test-"));
const stats = (name, scad, ...args) => {
  const src = path.join(dir, `${name}.scad`);
  fs.writeFileSync(src, scad);
  const r = spawnSync("node", [osc, "render", src], { encoding: "utf8" });
  assert.equal(r.status, 0, r.stderr);
  return spawnSync("node", [osc, "stats", src.replace(/scad$/, "stl"), ...args], { encoding: "utf8" }).stdout;
};

try {
  // 10 x 10 slab sticking out of a cube: exactly 100 mm2 of flat overhang, cube bottom excluded
  const ledge = stats("ledge", "cube(20); translate([20, 0, 10]) cube([10, 10, 2]);");
  assert.match(ledge, /Overhang > 45 deg: 100\.00 mm2 in 1 region/, ledge);
  assert.match(ledge, /flat \(bridge\?\)\s+x 20\.0\.\.30\.0/, ledge);
  // 60 deg slope from horizontal (30 from vertical) prints without support
  const ramp = stats("ramp", "rotate([90, 0, 0]) linear_extrude(10) polygon([[0, 0], [20, 0], [20 + 20 / tan(60), 20], [0, 20]]);");
  assert.match(ramp, /Overhang > 45 deg: 0\.00 mm2 in 0 region/, ramp);
  // ...but a 20 deg limit flags its 10 x 23.09 underside
  const strict = stats("ramp", "rotate([90, 0, 0]) linear_extrude(10) polygon([[0, 0], [20, 0], [20 + 20 / tan(60), 20], [0, 20]]);", "--overhang", "20");
  assert.match(strict, /Overhang > 20 deg: 230\.94 mm2 in 1 region/, strict);
  console.log("overhang tests: OK");
} finally {
  fs.rmSync(dir, { recursive: true, force: true });
}
