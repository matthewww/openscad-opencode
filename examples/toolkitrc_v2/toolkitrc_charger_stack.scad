// Tiered stand and travel stack for ToolkitRC M6 / M7 chargers on an ADP100 adapter.
// tray: holds the ADP100 at the bottom. Hex floor and walls let the fanless brick shed heat.
// seat: tilts one charger back on four corner posts. It pins onto the tray, or onto
//       the rear tower of the seat below, so the second charger sits higher and further back.
//       Both short ends stay clear for plugs, and the base fan has an open wedge underneath.
// cap:  a light hex roof that pins onto the top seat's tower and guards its screen.
// Desk: a seat on its own, or tray + seat(s). Travel: the same stack in one piece.
// Prints in its preview orientation with no supports. Sizes come from published specs
// and reference prints (Printables 629363, 217503, 781836); check them against your own units.
/* [Part] */
part = "stack"; // [seat, tray, cap, stack]
// Leave on for every seat that carries another seat or the cap
tower = true;
// Stack preview: add the cap on top of the last seat
show_cap = true;

/* [Charger] */
charger = "M7"; // [M6, M7, custom]
// Tiers above the first, used only by the stack preview; none ends the stack
tier2 = "M6"; // [none, M6, M7, custom]
tier3 = "none"; // [none, M6, M7, custom]
tier4 = "none"; // [none, M6, M7, custom]
// Used when charger = custom: length, width, height
custom_size = [73, 51, 27];
charger_clr = 0.4; // [0:0.1:1.5]
// Screen tilt back from horizontal
tilt = 35; // [15:1:60]
// Height of the charger front edge above the seat base
lift = 8; // [6:1:20]
// Air gap between the lower charger top and the upper charger
tier_gap = 15; // [8:1:30]
post_t = 2.4; // [1.6:0.2:4]
// Length of each corner post leg; short keeps the vents and end ports clear
post_arm = 7; // [4:0.5:15]
// Retaining lip over the charger top edge; 0 = loose fit
lip = 1; // [0:0.2:2]
pad_t = 4; // [2:0.5:6]

/* [Power supply] */
psu_size = 90; // [80:0.5:100]
psu_h = 32; // [25:0.5:40]
psu_r = 6; // [0:0.5:15]
psu_clr = 0.5; // [0:0.1:1.5]
wall_t = 2.4; // [1.6:0.2:4]
floor_t = 2; // [1.2:0.2:4]
// Outward rim the seats stand on
flange = 4.6; // [3:0.2:8]
// AC inlet window on the rear (+Y) face: offset from centre, width, height
inlet_offset = 25; // [-40:1:40]
inlet_w = 18; // [0:1:40]
inlet_h = 14; // [0:1:30]
// DC lead slot on the right (+X) face, open to the top: offset from centre, width
cable_offset = 30; // [-40:1:40]
cable_w = 10; // [0:0.5:20]

/* [Frame] */
frame_t = 3; // [2:0.5:6]
foot_w = 7; // [5:0.5:10]
foot_h = 7; // [5:0.5:12]
// Pin positions front-to-back, shared by tray and seat towers
pin_y = [-12, 16];
pin_d = 4; // [3:0.5:6]
pin_h = 5; // [3:0.5:8]
pin_clr = 0.2; // [0:0.05:0.5]

/* [Cap] */
roof_t = 2.4; // [1.6:0.2:4]
// Extra height of the roof above the pins; more clearance over the top charger
cap_lift = 0; // [0:0.5:20]
// Roof reach past the tray rim at the front; negative shortens it, stopping at the front pins
cap_front = -55; // [-55:1:20]
// Roof reach behind the rear pins
cap_rear = 6; // [4:1:30]
// Roof reach past the frames at each side
cap_side = 0; // [-5:0.5:15]
cap_corner_r = 5; // [0:0.5:20]
// Boss diameter around each pin hole
cap_boss_d = 8; // [6:0.5:14]

/* [Hex] */
// Hex pitch across flats; 0 = solid
hex_pitch = 18; // [0:1:30]
hex_web = 2.4; // [1.2:0.2:5]
hex_border = 4; // [2:0.5:10]

/* [Hidden] */
$fn = 48;
presets = [["M6", [70, 50, 26]], ["M7", [73, 51, 27]]];
function raw(name) = name == "custom" ? custom_size : presets[search([name], presets)[0]][1];
function pocket(name) = let(s = raw(name)) [s[0] + 2 * charger_clr, s[1] + 2 * charger_clr, s[2]];
// Envelope over every preset, so seats for different chargers still stack
E = [for (i = [0:2]) max(pocket("M6")[i], pocket("M7")[i], pocket("custom")[i])];

psu_in = psu_size + 2 * psu_clr;
r_in = max(psu_r + psu_clr, 0.01);
tray_half = psu_in / 2 + wall_t;
tray_h = floor_t + psu_h + psu_clr;
flange_h = 3;
x_f = psu_in / 2 + (wall_t + flange) / 2;     // frame and pin centre line
O_y = -tray_half + E[2] * sin(tilt);           // charger front-bottom edge, seat coords
pad_h = 5;
y_back = pin_y[1] + 10;

// Tilted charger coords (a up the slope, b out of the screen) to seat (y, z)
function P(a, b) = [O_y + a * cos(tilt) - b * sin(tilt), lift + a * sin(tilt) + b * cos(tilt)];
function rectP(a0, a1, b0, b1) = [P(a0, b0), P(a1, b0), P(a1, b1), P(a0, b1)];
D = P(E[1], E[2] + tier_gap) - P(0, 0);        // offset from one seat to the next

assert(tier_gap >= lip + pad_t + 2, "tier_gap too small for the posts below");
assert(E[0] / 2 + post_t < x_f - foot_w / 2, "charger too long for the tray");

module rsquare(s, r) { offset(r) square(s - 2 * r, center = true); }

module hex_holes(s) {
  rr = (hex_pitch - hex_web) / 2 / cos(30);
  n = ceil(s / hex_pitch) + 1;
  for (i = [-n:n], j = [-n:n])
    translate([i * hex_pitch * cos(30), (j + (i % 2) / 2) * hex_pitch])
      circle(r = rr, $fn = 6);
}

// Hex holes inside a 2D shape, clear of a solid border
module hex_cut() {
  if (hex_pitch > 0) intersection() { offset(-hex_border) children(); hex_holes(220); }
}

module hexed() { difference() { children(); hex_cut() children(); } }

module tilted() translate([0, O_y, lift]) rotate([tilt, 0, 0]) children();

// ---------- seat ----------

module frame2d(cw, with_tower) {
  hull() {
    translate([-tray_half, 0]) square([y_back + tray_half, foot_h]);
    polygon(rectP(-post_t, post_arm, -pad_t, 0));
    polygon(rectP(cw - post_arm, cw + post_t, -pad_t, 0));
  }
  if (with_tower) hull() {
    translate([pin_y[1] - 6, 0]) square([y_back - pin_y[1] + 6, foot_h]);
    polygon(rectP(E[1], E[1] + post_t, -pad_t, 0));
    translate([pin_y[0] + D[0] - 6, D[1] - pad_h]) square([pin_y[1] - pin_y[0] + 12, pad_h]);
  }
}

// One corner block in charger coords, mirrored to corner (sx, sy), spanning x0..x1
module corner_block(sx, sy, c, x0, x1) {
  translate([0, c[1] / 2, 0]) scale([sx, sy, 1])
    translate([x0, c[1] / 2 - post_arm, -pad_t]) cube([x1 - x0, post_arm + post_t, pad_t]);
}

module posts(c) {
  translate([0, c[1] / 2, 0]) for (sx = [-1, 1], sy = [-1, 1]) scale([sx, sy, 1]) {
    translate([0, 0, -pad_t]) linear_extrude(pad_t + c[2] + lip) difference() {
      translate([c[0] / 2 - post_arm, c[1] / 2 - post_arm]) square([post_arm + post_t, post_arm + post_t]);
      translate([c[0] / 2 - post_arm - 1, c[1] / 2 - post_arm - 1]) square([post_arm + 1, post_arm + 1]);
    }
    // Lip: flat underside holds the charger, 45 deg top guides it in
    if (lip > 0) translate([0, 0, c[2]]) {
      hull() {
        translate([c[0] / 2 - lip, c[1] / 2 - post_arm, 0]) cube([lip, post_arm, 0.01]);
        translate([c[0] / 2 - 0.01, c[1] / 2 - post_arm, lip - 0.01]) cube([0.01, post_arm, 0.01]);
      }
      hull() {
        translate([c[0] / 2 - post_arm, c[1] / 2 - lip, 0]) cube([post_arm, lip, 0.01]);
        translate([c[0] / 2 - post_arm, c[1] / 2 - 0.01, lip - 0.01]) cube([post_arm, 0.01, 0.01]);
      }
    }
  }
}

module seat(name, with_tower) {
  c = pocket(name);
  x_in = x_f - frame_t / 2;
  drop = x_in - (c[0] / 2 - post_arm);
  wall_top = with_tower ? D[1] : 15;
  difference() {
    union() {
      for (s = [-1, 1]) translate([s * x_f, 0, 0]) {
        rotate([90, 0, 90]) linear_extrude(frame_t, center = true) hexed() frame2d(c[1], with_tower);
        translate([-foot_w / 2, -tray_half, 0]) cube([foot_w, y_back + tray_half, foot_h]);
        if (with_tower) translate([-foot_w / 2, pin_y[0] + D[0] - 6, D[1] - pad_h])
          cube([foot_w, pin_y[1] - pin_y[0] + 12, pad_h]);
      }
      // Rear wall ties the frames together
      translate([0, y_back, 0]) rotate([90, 0, 0]) linear_extrude(3) hexed()
        translate([-x_f, 0]) square([2 * x_f, wall_top]);
      tilted() posts(c);
      // Corner pads reach out to the frames over 45 deg gussets
      for (sx = [-1, 1], sy = [-1, 1]) intersection() {
        hull() {
          tilted() corner_block(sx, sy, c, c[0] / 2 - post_arm, x_f);
          translate([0, 0, -drop]) tilted() corner_block(sx, sy, c, x_in, x_f);
        }
        translate([-x_f - 5, -tray_half - 5, 0]) cube([2 * x_f + 10, 2 * tray_half + 10, 100]);
      }
      if (with_tower) for (s = [-1, 1], y = pin_y) translate([s * x_f, y + D[0], D[1]]) pin();
    }
    for (s = [-1, 1], y = pin_y) translate([s * x_f, y, -0.01])
      cylinder(h = pin_h + 0.5, d = pin_d + 2 * pin_clr);
  }
  if (part == "stack") let(r = raw(name))
    %tilted() translate([-r[0] / 2, charger_clr, 0]) cube(r);
}

module pin() {
  translate([0, 0, -0.5]) cylinder(h = pin_h - 0.1, d = pin_d);
  translate([0, 0, pin_h - 0.6]) cylinder(h = 0.6, d1 = pin_d, d2 = pin_d - 1.2);
}

// ---------- cap ----------

// Seat coords of the position a next seat would take; roof sits above the bosses
module cap() {
  boss_h = pin_h + 0.5 + cap_lift;
  y0 = min(-(tray_half + flange) - D[0] - cap_front, pin_y[0] - cap_boss_d / 2 - 2);
  y1 = pin_y[1] + cap_rear;
  w = 2 * (x_f + foot_w / 2 + cap_side);
  r = min(max(cap_corner_r, 0.01), w / 2 - 0.1, (y1 - y0) / 2 - 0.1);
  difference() {
    union() {
      translate([0, (y0 + y1) / 2, boss_h]) linear_extrude(roof_t)
        hexed() offset(r) square([w - 2 * r, y1 - y0 - 2 * r], center = true);
      for (s = [-1, 1], y = pin_y) translate([s * x_f, y, 0]) cylinder(h = boss_h + 0.01, d = cap_boss_d);
    }
    for (s = [-1, 1], y = pin_y) translate([s * x_f, y, -0.01])
      cylinder(h = pin_h + 0.5, d = pin_d + 2 * pin_clr);
  }
}

// ---------- tray ----------

module tray() {
  outer = psu_in + 2 * wall_t;
  zm = floor_t + psu_h / 2;
  panel_h = tray_h - flange_h - flange - floor_t;
  difference() {
    union() {
      linear_extrude(tray_h) rsquare(outer, r_in + wall_t);
      // Rim with a 45 deg underside, so it prints without support
      hull() {
        translate([0, 0, tray_h - flange_h - flange]) linear_extrude(0.01) rsquare(outer, r_in + wall_t);
        translate([0, 0, tray_h - flange_h]) linear_extrude(flange_h) rsquare(outer + 2 * flange, r_in + wall_t + flange);
      }
    }
    translate([0, 0, floor_t]) linear_extrude(tray_h) rsquare(psu_in, r_in);
    translate([0, 0, -1]) linear_extrude(floor_t + 2) hex_cut() rsquare(psu_in, r_in);
    // Wall vents; the corners stay solid
    for (a = [0:90:270]) rotate(a) translate([psu_in / 2 - 1, 0, floor_t]) rotate([90, 0, 90])
      linear_extrude(wall_t + 2) hex_cut() translate([-(psu_in / 2 - r_in), 0]) square([psu_in - 2 * r_in, panel_h]);
    if (inlet_w > 0) translate([inlet_offset, psu_in / 2 + wall_t / 2, zm])
      cube([inlet_w, 3 * wall_t, inlet_h], center = true);
    if (cable_w > 0) translate([psu_in / 2 + (wall_t + flange) / 2, cable_offset, zm]) {
      rotate([0, 90, 0]) cylinder(h = wall_t + flange + 2, d = cable_w, center = true);
      translate([0, 0, tray_h / 2]) cube([wall_t + flange + 2, cable_w, tray_h], center = true);
    }
  }
  for (s = [-1, 1], y = pin_y) translate([s * x_f, y, tray_h]) pin();
}

// Tiers in order, stopping at the first "none"
tiers = let(t = [charger, tier2, tier3, tier4])
  [for (i = [0:3]) if (len([for (j = [0:i]) if (t[j] == "none") 1]) == 0) t[i]];

if (part == "seat") seat(charger, tower);
else if (part == "tray") tray();
else if (part == "cap") translate([0, 0, pin_h + 0.5 + cap_lift + roof_t]) mirror([0, 0, 1]) cap();   // roof on the bed
else {
  tray();
  %translate([0, 0, floor_t]) linear_extrude(psu_h) rsquare(psu_size, psu_r);
  // Identical seats: each carries the next on its tower; the top one follows `tower`
  translate([0, 0, tray_h]) for (i = [0:len(tiers) - 1])
    translate(i * [0, D[0], D[1]]) seat(tiers[i], i < len(tiers) - 1 || tower || show_cap);
  if (show_cap) translate([0, 0, tray_h] + len(tiers) * [0, D[0], D[1]]) cap();
}

echo(seat_step = D, tiers = tiers, stack_h = tray_h + (len(tiers) - 1) * D[1] + P(E[1], E[2] + lip)[1], width = 2 * (x_f + foot_w / 2));
