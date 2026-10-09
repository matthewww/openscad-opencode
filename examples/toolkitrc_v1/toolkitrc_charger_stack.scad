// Stand and travel stack for ToolkitRC M6 / M7 chargers and the ADP100 adapter.
// cradle: the charger sits on corner posts, raised over a hex plate. The base fan
//         draws air in from all sides and both long-side vent rows are left open.
// band:   a sleeve around the ADP100. A plate snaps into each open end.
// cap:    a bare plate that closes the band when only one charger travels.
// Desk: a cradle on its own. Travel: cradle + band + cap, or two cradles + band.
// Every part prints in its preview orientation with no supports. Fit tested in PETG.
// Sizes come from published specs and reference prints (Printables 629363,
// 217503, 781836); measure your own units and adjust before printing.
/* [Part] */
part = "stack"; // [cradle, band, cap, stack]

/* [Charger] */
charger = "M7"; // [M6, M7, custom]
// Used when charger = custom: length, width, height
custom_size = [73, 51, 27];
// Gap around the charger body
charger_clr = 0.4; // [0:0.1:1.5]
// Air gap under the charger for the base fan
lift = 8; // [3:1:20]
post_t = 2.4; // [1.6:0.2:4]
// Length of each corner post leg; short keeps the side vents and end ports clear
post_arm = 7; // [4:0.5:15]
// Retaining lip over the charger top edge; 0 = loose fit
lip = 1; // [0:0.2:2]

/* [Power supply] */
psu_size = 90; // [80:0.5:100]
psu_h = 32; // [25:0.5:40]
psu_r = 6; // [0:0.5:15]
psu_clr = 0.5; // [0:0.1:1.5]
band_t = 2.4; // [1.6:0.2:4]
// AC inlet window on the -Y face: offset from centre, width, height
inlet_offset = 25; // [-40:1:40]
inlet_w = 18; // [0:1:40]
inlet_h = 14; // [0:1:30]
// DC lead slot on the -X face, open to the top rim: offset from centre, width
cable_offset = -30; // [-40:1:40]
cable_w = 10; // [0:0.5:20]

/* [Plate] */
plate_t = 3; // [2:0.5:6]
// Solid border around the hex field
rim_w = 5; // [2:0.5:15]
// Hex pitch across flats; 0 = solid plate
hex_pitch = 10; // [0:1:20]
hex_web = 2; // [1:0.2:4]

/* [Snap fit] */
// Gap between the plate edge and the band
fit_clr = 0.3; // [0:0.05:0.8]
// Height the snap bead protrudes inward
bead = 0.6; // [0:0.1:1.2]
bead_h = 1.4; // [0.8:0.1:3]
bead_len = 30; // [10:1:60]

/* [Hidden] */
$fn = 48;
presets = [["M6", [70, 50, 26]], ["M7", [73, 51, 27]]];
cs = charger == "custom" ? custom_size : presets[search([charger], presets)[0]][1];
cl = cs[0] + 2 * charger_clr;
cw = cs[1] + 2 * charger_clr;
ch = cs[2];
psu_in = psu_size + 2 * psu_clr;
r_in = max(psu_r + psu_clr, 0.01);
plate_s = psu_in - 2 * fit_clr;
plate_r = max(r_in - fit_clr, 0.01);
band_h = psu_h + psu_clr + 2 * (plate_t + bead_h);
post_h = lift + ch + lip;

assert(cl + 2 * post_t <= plate_s - 2 * band_t, "charger longer than the plate");

module rsquare(s, r) { offset(r) square(s - 2 * r, center = true); }

module hex_holes(s) {
  rr = (hex_pitch - hex_web) / 2 / cos(30);
  nx = ceil(s / (hex_pitch * cos(30))) + 1;
  ny = ceil(s / hex_pitch) + 1;
  for (i = [-nx:nx], j = [-ny:ny])
    translate([i * hex_pitch * cos(30), (j + (i % 2) / 2) * hex_pitch])
      rotate(30) circle(r = rr, $fn = 6);
}

// Corner-post footprints in plan
module post_plan() {
  for (sx = [-1, 1], sy = [-1, 1]) scale([sx, sy])
    translate([cl / 2 - post_arm, cw / 2 - post_arm])
      square([post_arm + post_t, post_arm + post_t]);
}

module plate() {
  linear_extrude(plate_t) difference() {
    rsquare(plate_s, plate_r);
    if (hex_pitch > 0) difference() {
      intersection() { rsquare(plate_s - 2 * rim_w, max(plate_r - rim_w, 0.01)); hex_holes(plate_s); }
      offset(hex_web) post_plan();
    }
  }
}

module posts() {
  translate([0, 0, plate_t]) for (sx = [-1, 1], sy = [-1, 1]) scale([sx, sy, 1]) {
    // L-wall hugging the charger corner
    linear_extrude(post_h) difference() {
      translate([cl / 2 - post_arm, cw / 2 - post_arm]) square([post_arm + post_t, post_arm + post_t]);
      translate([cl / 2 - post_arm - 1, cw / 2 - post_arm - 1]) square([post_arm + 1, post_arm + 1]);
    }
    // Pad the charger corner rests on
    translate([cl / 2 - post_arm, cw / 2 - post_arm, 0]) cube([post_arm, post_arm, lift]);
    // Lip: flat underside holds the charger, 45 deg top guides it in
    if (lip > 0) translate([0, 0, lift + ch]) {
      hull() {
        translate([cl / 2 - lip, cw / 2 - post_arm, 0]) cube([lip, post_arm, 0.01]);
        translate([cl / 2 - 0.01, cw / 2 - post_arm, lip - 0.01]) cube([0.01, post_arm, 0.01]);
      }
      hull() {
        translate([cl / 2 - post_arm, cw / 2 - lip, 0]) cube([post_arm, lip, 0.01]);
        translate([cl / 2 - post_arm, cw / 2 - 0.01, lip - 0.01]) cube([post_arm, 0.01, 0.01]);
      }
    }
  }
}

module cradle() {
  plate();
  posts();
  if (part == "stack") %translate([0, 0, plate_t + lift + ch / 2]) cube([cs[0], cs[1], ch], center = true);
}

// V-shaped bead segments on the inside of each face, centred at height z
module beads(z) {
  for (a = [0:90:270]) rotate(a) translate([psu_in / 2, 0, z]) rotate([90, 0, 0])
    linear_extrude(bead_len, center = true)
      polygon([[0.01, -bead_h / 2], [-bead, 0], [0.01, bead_h / 2]]);
}

module band() {
  difference() {
    linear_extrude(band_h) difference() {
      rsquare(psu_in + 2 * band_t, r_in + band_t);
      rsquare(psu_in, r_in);
    }
    // AC inlet window
    if (inlet_w > 0) translate([inlet_offset, -psu_in / 2, band_h / 2])
      cube([inlet_w, 3 * band_t, inlet_h], center = true);
    // DC lead slot, open to the top rim so the lead can drop in
    if (cable_w > 0) translate([-psu_in / 2, cable_offset, band_h / 2]) {
      rotate([0, 90, 0]) cylinder(h = 3 * band_t, d = cable_w, center = true);
      translate([0, 0, band_h / 4 + 1]) cube([3 * band_t, cable_w, band_h / 2 + 2], center = true);
    }
    // Thumb notches for prising a plate out, one at each rim
    for (z = [0, band_h]) translate([psu_in / 2 - 18, psu_in / 2, z])
      rotate([90, 0, 0]) cylinder(h = 3 * band_t, r = plate_t + bead_h + 2, center = true);
  }
  beads(bead_h / 2);
  beads(band_h - bead_h / 2);
}

if (part == "cradle") cradle();
else if (part == "cap") plate();
else if (part == "band") band();
else {
  // Two cradles on the band, with a ghost of the ADP100
  translate([0, 0, bead_h]) mirror([0, 0, 1]) translate([0, 0, -plate_t]) cradle();
  band();
  translate([0, 0, band_h - bead_h - plate_t]) cradle();
  %translate([0, 0, bead_h + plate_t]) linear_extrude(psu_h) rsquare(psu_size, psu_r);
}

echo(charger = charger, pocket = [cl, cw], plate = plate_s, band_outer = psu_in + 2 * band_t,
     band_h = band_h, stack_h = band_h - 2 * bead_h + 2 * post_h);
