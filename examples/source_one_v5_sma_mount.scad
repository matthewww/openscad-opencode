// SMA antenna mount for TBS Source One V5/V5.1, rear standoff pair.
// Sleeves fill the gap between plates so the mount can't slide or spin;
// the SMA face cantilevers out behind the frame. Slide on with the top plate off.
// X = across the frame, -Y = rearward, Z = up (installed). Print top-down (flip in slicer).
// Defaults measured from published V5 mounts (Printables 242325 / 255747) and TBS specs.
/* [Frame] */
// Rear standoff pair, centre-to-centre
standoff_spacing = 19; // [15:0.1:35]
// TPU: 4.85-5.0 grips the 5 mm standoff; PETG/PLA: 5.2-5.3 slides
bore_d = 5.0; // [4.6:0.05:5.6]
sleeve_wall = 1.5; // [1:0.1:3]
// Clear height between the plates the mount spans; 6 = short rings
sleeve_h = 22; // [6:0.5:30]

/* [SMA face] */
// Antenna angle above horizontal (references use 30-45)
sma_elev = 30; // [0:1:60]
// Face length along the slope; must fit the flange and screws
face_len = 11; // [8:0.5:16]
// Gap from the sleeve rear to the face top edge
face_setback = 1; // [0:0.5:6]
// Clamp wall: 3 for TBS pigtails, 2 for Rush
face_t = 3; // [1.5:0.5:5]
// Flat under the face bottom edge
lip_h = 1.5; // [0.5:0.5:4]

/* [SMA pigtail] */
// 1/4"-36 barrel clearance
sma_d = 6.5; // [6:0.1:7.5]
// Relief behind the clamp wall for the pigtail body / nut
pocket_d = 8.5; // [6:0.5:12]
// Self-tapping screws into the block (references: 2.75-3.1)
flange_hole_d = 2.8; // [0:0.1:3.5]
// TBS flange, confirmed on two references
flange_hole_spacing = 12; // [8:0.5:16]
// Blind depth; keep clear of the standoff bores
flange_hole_depth = 5; // [2:0.5:8]

/* [Shape] */
// Vertical corner radius of the block, front pair (4 matches round legs)
corner_r_front = 4; // [0:0.25:8]
// Vertical corner radius of the block, back pair (face side)
corner_r_back = 1; // [0:0.25:8]
// Square off the front half of both legs (uses corner_r_front)
square_legs_front = false;
// Square off the back half of both legs (uses corner_r_back)
square_legs_back = false;

/* [Hidden] */
$fn = 64;
sleeve_od = bore_d + 2 * sleeve_wall;
width = standoff_spacing + sleeve_od;
face_dz = face_len * cos(sma_elev);
face_dy = face_len * sin(sma_elev);
face_top_y = -sleeve_od / 2 - face_setback;
face_bot_y = face_top_y - face_dy;
block_z = sleeve_h - face_dz - lip_h;      // underside of the cantilever

assert(block_z > 0, "face too long for sleeve_h; shorten face_len or raise sma_elev");

// Children placed on the face centre, local +Z out of the face (rear and up).
module on_face() {
  translate([0, (face_top_y + face_bot_y) / 2, sleeve_h - face_dz / 2])
    rotate([90 - sma_elev, 0, 0]) children();
}

// Plan-view rectangle with separate front (+Y) and back (-Y) corner radii; r = 0 is square.
module rounded_rect(x0, x1, y0, y1, rf, rb) {
  f = max(rf, 0.01);
  b = max(rb, 0.01);
  hull() for (sx = [-1, 1]) {
    translate([sx < 0 ? x0 + f : x1 - f, y1 - f]) circle(r = f);
    translate([sx < 0 ? x0 + b : x1 - b, y0 + b]) circle(r = b);
  }
}

// Leg footprint: round by default; a squared half takes the matching corner radius.
module leg_plan() {
  r = sleeve_od / 2;
  rounded_rect(-r, r, -r, r,
               square_legs_front ? min(corner_r_front, r) : r,
               square_legs_back ? min(corner_r_back, r) : r);
}

module block() {
  depth = sleeve_od / 2 - face_bot_y;
  rmax = min(width / 2, depth / 2);
  intersection() {
    // YZ profile extruded along X: covers the sleeve tops, face cuts the top-rear corner
    rotate([90, 0, 90]) translate([0, 0, -width / 2])
      linear_extrude(width)
        polygon([[sleeve_od / 2, sleeve_h], [sleeve_od / 2, block_z],
                 [face_bot_y, block_z], [face_bot_y, block_z + lip_h],
                 [face_top_y, sleeve_h]]);
    translate([0, 0, -1]) linear_extrude(sleeve_h + 2)
      rounded_rect(-width / 2, width / 2, face_bot_y, sleeve_od / 2,
                   min(corner_r_front, rmax), min(corner_r_back, rmax));
  }
}

difference() {
  union() {
    for (s = [-1, 1]) translate([s * standoff_spacing / 2, 0, 0])
      linear_extrude(sleeve_h) leg_plan();
    block();
  }
  for (s = [-1, 1]) translate([s * standoff_spacing / 2, 0, -1])
    cylinder(h = sleeve_h + 2, d = bore_d);
  on_face() {
    translate([0, 0, -face_t - 1]) cylinder(h = face_t + 2, d = sma_d);
    translate([0, 0, -50 - face_t]) cylinder(h = 50, d = pocket_d);   // exits under/front for the cable
    for (s = [-1, 1]) translate([s * flange_hole_spacing / 2, 0, -flange_hole_depth])
      cylinder(h = flange_hole_depth + 1, d = flange_hole_d);
  }
}

echo(width = width, sleeve_od = sleeve_od, block_z = block_z, overhang_y = -face_bot_y);
