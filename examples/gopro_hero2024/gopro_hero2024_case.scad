// TPU crash case for the GoPro HERO (2024), for an FPV drone using the camera's own folding fingers.
// The front plate is solid around a window for the lens module, which stands proud of the camera
// body at one top corner and overhangs it, so the case bulges around that corner.
// A separate snap-in guard ring (part = "guard") fills the window and stands proud of the lens.
// It prints flat, so neither part needs supports. Print the case front-down, the guard front-down.
// Entry picks the side the camera goes in from:
//   back      from the screen side, past a stretchy lip on all four sides
//   bottom    from the fingers side; the plate gets a slot so the lens module can slide up
//   lens_side from the lens / power button side; the plate gets a slot out to that edge
// Side entries leave the entry wall open over the camera depth, keep the rear lip as a bar across
// it, and add small catches that the camera snaps past.
// Viewed from the back (the top view), +X is screen right: the lens side is -X and the door side +X.
// Sizes are estimates from GoPro renders and two reference cases. Check against calipers.
/* [Part] */
part = "case"; // [case, guard, assembly, fit_test]
// Side the camera loads from
entry = "back"; // [back, bottom, lens_side]

/* [Camera body] */
// Body without the lens module overhang or the fingers: width, height, depth
body = [53.2, 38.6, 25.5];
// Folded fingers hang below the body
fingers_h = 5.5; // [0:0.5:10]
// Body corner radius seen from the front
cam_r = 4; // [0:0.5:10]
// Gap per side; TPU stretches, so keep it small
clr = 0.2; // [0:0.05:1]

/* [Lens module] */
mod_size = 26.2; // [20:0.2:32]
mod_r = 5; // [0:0.5:12]
// How far the module stands in front of the body face
mod_proud = 4; // [1:0.25:8]
// Overhang past the lens-side face and past the body top
mod_over = [3.4, 3.2]; // [0:0.2:6]
// How far back the overhang runs behind the body front face
mod_depth = 8; // [4:0.5:20]

/* [Lens guard] */
// Guard front edge stands this far in front of the lens module
guard_proud = 5; // [2:0.5:9]
// Depth of the lens module behind the case front face
lens_guard = 1.5; // [0:0.25:4]
// Opening clear of the module on each side
guard_extra = 0.75; // [0.25:0.25:3]
guard_wall = 1.8; // [1.2:0.2:3]
// Flange width beyond the stem on each side
guard_flange = 2; // [1:0.5:5]
// Inner 45 deg flare at the front edge, to keep the view clear
guard_flare = 1.5; // [0:0.25:3]
// Snap bead height; the case window carries a matching groove
bead_h = 0.6; // [0.3:0.1:1]
// Gap per side between stem and window; TPU is soft, so keep it near zero
guard_fit = 0.05; // [0:0.05:0.3]
// Case material kept around the guard window
lens_border = 2; // [1:0.5:4]
// Assumed lens half field of view across and up/down, used only to report vignetting
fov_half = [60, 40];

/* [Case] */
wall_t = 2; // [1.2:0.2:4]

/* [Rear window] */
// How far the rear lip overlaps the camera back on each side; 0 = open to that edge
// A bigger lip makes the screen window smaller. All four sides keep their lip, entry side included.
lip_top = 3; // [0:0.5:12]
lip_bottom = 3; // [0:0.5:12]
// Door side (+X)
lip_door = 3; // [0:0.5:12]
// Lens side (-X)
lip_lens = 3; // [0:0.5:12]
// Corner radius of the screen window
win_r = 3; // [0.5:0.5:10]

/* [Side entry] */
// Extra cavity on the entry side, where the catches sit
entry_room = 2.5; // [1.5:0.5:6]
// Catch height on the two walls beside the entry; 0 = none, rely on friction
catch_h = 0.8; // [0:0.1:1.5]
// Plate slot width beyond the lens module, for the module to slide along
slot_clr = 1; // [0:0.5:4]
// Bottom entry: open the lens-side wall front so the module overhang can slide past it
bottom_module_channel = false;

/* [Openings] */
// Cut button windows; off leaves hex mesh to poke buttons through
button_holes = false;
// Positions: [across the face, depth behind the camera front face]; sizes: [across, along depth]
// Shutter and status light on top; the door side is +X
shutter_pos = [10.6, 9.5];
shutter_size = [15, 17];
// Power / mode on the lens-side wall: across = Y
mode_pos = [-8.2, 17];
mode_size = [10, 16];
// Folding fingers through the bottom wall (back and lens_side entry): across = X
fingers_pos = [0, 12];
fingers_size = [40, 20];
// Run the fingers opening out through the rear lip
fingers_to_rear = false;
// Widest flat bridge at an opening top; the rest is a 45 deg roof
max_bridge = 5; // [2:0.5:10]

/* [Hex] */
// Hex pitch across flats; 0 = solid walls
hex_pitch = 8; // [0:0.5:16]
hex_web = 1.6; // [1:0.2:4]
// Solid band kept around edges and openings
hex_border = 2.5; // [1:0.5:6]

/* [Hidden] */
$fn = 48;
t_f = mod_proud + lens_guard;                 // front plate
z0 = t_f;                                     // camera front face
z1 = z0 + body[2] + clr;                      // camera back face
// Cavity box in XY: origin at the body centre, fingers hang below, entry side gets extra room
rc = cam_r + clr;
cx0 = -(body[0] / 2 + clr) - (entry == "lens_side" ? entry_room : 0);
cx1 = body[0] / 2 + clr;
cy1 = body[1] / 2 + clr;
cy0 = -(body[1] / 2 + fingers_h + clr) - (entry == "bottom" ? entry_room : 0);
// Lips sit behind the camera, so every side keeps one, including the entry side
l_top = lip_top;
l_bot = lip_bottom;
l_door = lip_door;
l_lens = lip_lens;
lip_h = max(l_top, l_bot, l_door, l_lens, 0.5);
z_top = z1 + lip_h + 1;
// Lens module centre, flush with the top and lens-side overhang
lens_pos = [-(body[0] / 2 + mod_over[0] - mod_size / 2), body[1] / 2 + mod_over[1] - mod_size / 2];
L = mod_size + 2 * clr;
fl_t = guard_proud - lens_guard;              // flange stands this far in front of the face
B = L + 2 * guard_extra;                      // guard opening
rB = mod_r + guard_extra;
S = B + 2 * guard_wall;                       // stem
rS = rB + guard_wall;
bz = t_f - 3;                                 // bead start, from the case front face
g_win = guard_fit + bead_h;
sw = L + slot_clr;                            // plate slot width

assert(lip_h < min(cx1 - cx0, cy1 - cy0) / 4, "rear lip too wide");
assert(guard_proud > lens_guard, "guard must stand proud of the face");

module rsquare(s, r) { offset(r) square([s[0] - 2 * r, s[1] - 2 * r], center = true); }
module rrect(x0, y0, x1, y1, r) translate([(x0 + x1) / 2, (y0 + y1) / 2]) rsquare([x1 - x0, y1 - y0], r);

module hex_holes(s) {
  rr = (hex_pitch - hex_web) / 2 / cos(30);
  n = ceil(s / hex_pitch) + 1;
  for (i = [-n:n], j = [-n:n])
    translate([i * hex_pitch * cos(30), (j + (i % 2) / 2) * hex_pitch])
      circle(r = rr, $fn = 6);
}

module cavity2d() rrect(cx0, cy0, cx1, cy1, rc);
module bulge2d() translate(lens_pos) rsquare([S + 2 * (g_win + lens_border), S + 2 * (g_win + lens_border)], rS + g_win + lens_border);

// Screen window at fraction f of the lip: f = 1 is the finished opening
module win2d(f) rrect(cx0 + f * l_lens, cy0 + f * l_bot, cx1 - f * l_door, cy1 - f * l_top,
                      max(rc + f * (win_r - rc), 0.5));

// Plate slot the lens module slides along on a side entry, 2D in plate coords
module slot2d() {
  if (entry == "bottom") translate([lens_pos[0] - sw / 2, cy0 - wall_t - 1]) square([sw, lens_pos[1] - (cy0 - wall_t - 1)]);
  if (entry == "lens_side") translate([-60, lens_pos[1] - sw / 2]) square([lens_pos[0] + sw / 2 + 60, sw]);
}

// Wall opening in face coords (u across, w = print height), with a 45 deg roof up to max_bridge
module opening(pos, size) {
  c = [pos[0], z0 + pos[1]];
  b = min(size[0], max_bridge);
  hull() {
    translate(c) square(size, center = true);
    translate([c[0], c[1] + size[1] / 2 + (size[0] - b) / 2 - 0.01]) square([b, 0.02], center = true);
  }
}

// Cut a wall panel u0..u1 across, w0..w1 deep: the openings, then hexes clear of them
module wall_cut(u0, u1, anchor = [0, 0], w0 = z0, w1 = z1) {
  children();
  if (hex_pitch > 0) intersection() {
    difference() {
      translate([u0 + hex_border, w0 + hex_border]) square([u1 - u0 - 2 * hex_border, w1 - w0 - 2 * hex_border]);
      offset(hex_border) children();
    }
    translate(anchor) rotate(90) hex_holes(120);   // vertex up, so each hole closes with a 60 deg roof
  }
}

// Cutters in face coords (u, w) -> world
module top_bottom(y) translate([0, y, 0]) rotate([90, 0, 0]) linear_extrude(wall_t + 2, center = true) children();
module side(x) translate([x, 0, 0]) rotate([90, 0, 90]) linear_extrude(wall_t + 2, center = true) children();

// ---------- lens guard ----------

// Slice of the guard stem, grown by g per side
module stem_slice(g, z) translate([0, 0, z]) linear_extrude(0.01) rsquare([S + 2 * g, S + 2 * g], rS + g);

// Window through the plate, with the bead groove; case coords, front face at z = 0
module lens_window() translate(lens_pos) {
  g = guard_fit;
  translate([0, 0, -1]) linear_extrude(t_f + 1.01) rsquare([S + 2 * g, S + 2 * g], rS + g);
  hull() { stem_slice(g, bz); stem_slice(g + bead_h, bz + bead_h); }
  hull() { stem_slice(g + bead_h, bz + bead_h); stem_slice(g + bead_h, bz + bead_h + 1); }
  hull() { stem_slice(g + bead_h, bz + bead_h + 1); stem_slice(g, bz + 2 * bead_h + 1); }
}

// Snap-in guard, printed front-down: z = 0 is the front edge, flange then stem
module guard() difference() {
  union() {
    // Flange with a steep outer front edge
    c = min(1.5, fl_t);
    hull() {
      linear_extrude(0.01) rsquare([S + 2 * (guard_flange - 0.8 * c), S + 2 * (guard_flange - 0.8 * c)], rS + guard_flange - 0.8 * c);
      translate([0, 0, c]) linear_extrude(0.01) rsquare([S + 2 * guard_flange, S + 2 * guard_flange], rS + guard_flange);
    }
    translate([0, 0, c]) linear_extrude(fl_t - c + 0.01) rsquare([S + 2 * guard_flange, S + 2 * guard_flange], rS + guard_flange);
    // Stem and bead
    translate([0, 0, fl_t]) linear_extrude(t_f) rsquare([S, S], rS);
    translate([0, 0, fl_t]) {
      hull() { stem_slice(0, bz); stem_slice(bead_h, bz + bead_h); }
      hull() { stem_slice(bead_h, bz + bead_h); stem_slice(bead_h, bz + bead_h + 1); }
      hull() { stem_slice(bead_h, bz + bead_h + 1); stem_slice(0, bz + 2 * bead_h + 1); }
    }
  }
  translate([0, 0, -1]) linear_extrude(fl_t + t_f + 2) rsquare([B, B], rB);
  if (guard_flare > 0) hull() {
    translate([0, 0, -0.01]) linear_extrude(0.01) rsquare([B + 2 * guard_flare, B + 2 * guard_flare], rB + guard_flare);
    translate([0, 0, guard_flare * 1.25]) linear_extrude(0.01) rsquare([B, B], rB);
  }
}

// ---------- case ----------

// Entry wall removed between the corners over the camera depth only; the rear lip stays as a bar
// across the open side. Plus the plate slot. A thin skin stays across the
// slot in front of the module, so the front stays closed and the walls stay tied to the plate.
module entry_cut() {
  skin = max(lens_guard - 0.3, 0.8);
  if (entry == "bottom") {
    translate([cx0, cy0 - wall_t - 1, z0]) cube([cx1 - cx0, wall_t + 1 + rc, z1 - z0 + 0.01]);
    // Only if the module overhang rubs the lens-side wall on the way up: a channel as wide as the
    // overhang opens in that wall's front part, from the bottom edge to the module's final spot
    mx = lens_pos[0] - sw / 2;
    if (bottom_module_channel) translate([mx, cy0 - wall_t - 1, z0 - 0.01]) cube([cx0 - mx + 0.01, lens_pos[1] + sw / 2 - (cy0 - wall_t - 1), mod_depth + 0.5]);
  }
  if (entry == "lens_side") {
    translate([cx0 - wall_t - 1, cy0, z0]) cube([wall_t + 1 + rc, cy1 - cy0, z1 - z0 + 0.01]);
    // The module slides in through the bulge, so the bulge opens over the module's height only
    translate([-60, lens_pos[1] - sw / 2, z0 - 0.01]) cube([60 + cx0 + rc, sw, mod_depth + 0.5]);
  }
  if (entry != "back") translate([0, 0, skin]) linear_extrude(z0 - skin + 0.01) slot2d();
}

// Ridge along z on a wall beside the entry; the ramp faces the entry, the flat catch faces the camera
module catch_rib(pts, za, zb) translate([0, 0, za]) linear_extrude(zb - za) polygon(pts);

module catches() {
  if (catch_h > 0 && entry == "bottom") {
    yp = -body[1] / 2 - catch_h;   // catch face just below the body edge
    catch_rib([[cx0 - 0.01, cy0 + 0.3], [cx0 + catch_h, yp], [cx0 - 0.01, yp]], z0 + 2, z1 - 2);
    catch_rib([[cx1 + 0.01, cy0 + 0.3], [cx1 - catch_h, yp], [cx1 + 0.01, yp]], z0 + 2, z1 - 2);
  }
  if (catch_h > 0 && entry == "lens_side") {
    xp = -body[0] / 2 - catch_h;
    catch_rib([[cx0 + 0.3, cy0 - 0.01], [xp, cy0 + catch_h], [xp, cy0 - 0.01]], z0 + 2, z1 - 2);
    catch_rib([[cx0 + 0.3, cy1 + 0.01], [xp, cy1 - catch_h], [xp, cy1 + 0.01]], z0 + mod_depth + 1, z1 - 2);
  }
}

module case() {
  yt = cy1 + wall_t / 2;
  yb = cy0 - wall_t / 2;
  xr = cx1 + wall_t / 2;
  xl = cx0 - wall_t / 2;
  // Fingers opening, optionally run out through the rear lip
  f_start = fingers_pos[1] - fingers_size[1] / 2;
  f_len = fingers_to_rear ? z_top - z0 - f_start + 1 : fingers_size[1];
  f_pos = [fingers_pos[0], f_start + f_len / 2];
  f_size = [fingers_size[0], f_len];
  difference() {
    union() {
      difference() {
        union() {
          linear_extrude(z_top) offset(r = wall_t) cavity2d();
          linear_extrude(z0 + mod_depth + wall_t) bulge2d();
        }
        // Camera body, the module overhang pocket, then the rear lip as a 45 deg chamfer
        translate([0, 0, z0]) linear_extrude(z1 - z0) cavity2d();
        translate([0, 0, z0 - 0.01]) linear_extrude(mod_depth) translate(lens_pos) rsquare([L, L], mod_r + clr);
        n = 6;
        for (i = [0:n - 1]) translate([0, 0, z1 - 0.01 + i * lip_h / n])
          linear_extrude(lip_h / n + 0.02) win2d((i + 1) / n);
        translate([0, 0, z1 + lip_h - 0.01]) linear_extrude(2) win2d(1);
      }
      catches();
    }
    lens_window();
    entry_cut();
    // Front plate hexes, clear of the guard window and any slot
    if (hex_pitch > 0) translate([0, 0, -1]) linear_extrude(t_f + 2) intersection() {
      difference() {
        offset(-hex_border) cavity2d();
        offset(hex_border) hull() translate(lens_pos) rsquare([S + 2 * g_win, S + 2 * g_win], rS + g_win);
        offset(hex_border) slot2d();
      }
      hex_holes(120);
    }
    // Top wall right of the bulge; shutter and status light
    top_bottom(yt) wall_cut(lens_pos[0] + S / 2 + g_win + lens_border, cx1 - rc, [shutter_pos[0], z0 + shutter_pos[1]])
      if (button_holes) opening(shutter_pos, shutter_size);
    // Bottom wall, fingers
    if (entry != "bottom") top_bottom(yb) wall_cut(cx0 + rc, cx1 - rc) opening(f_pos, f_size);
    // Door side stays closed
    side(xr) wall_cut(cy0 + rc, cy1 - rc) {}
    if (entry != "lens_side") {
      // Lens side below the bulge, power / mode
      side(xl) wall_cut(cy0 + rc, lens_pos[1] - S / 2 - g_win - lens_border, [mode_pos[0], z0 + mode_pos[1]])
        if (button_holes) opening(mode_pos, mode_size);
      // Above the bulge the lens-side wall is flat again, so the mode button sits behind this panel
      side(xl) wall_cut(lens_pos[1] - S / 2 - g_win - lens_border - 2 * hex_border, cy1 - rc, [mode_pos[0], z0 + mode_pos[1]], z0 + mod_depth + wall_t, z1) {}
    }
  }
}

if (part == "guard") guard();
else if (part == "fit_test") intersection() {   // front plate and a short collar: checks the lens window
  case();
  translate([-100, -100, -1]) cube([200, 200, t_f + 4]);
}
else {
  case();
  // Camera ghost: body, fingers and lens module
  %translate([0, 0, z0]) linear_extrude(body[2]) translate([0, -fingers_h / 2]) rsquare([body[0], body[1] + fingers_h], cam_r);
  %translate([lens_pos[0], lens_pos[1], z0 - mod_proud]) linear_extrude(mod_proud + mod_depth) rsquare([mod_size, mod_size], mod_r);
  if (part == "assembly") translate([lens_pos[0], lens_pos[1], -fl_t]) guard();
}

// Vignetting: half angle from the module front to the guard's front opening edge
// ponytail: assumes the lens sits at the module front, centred in the opening
va = atan((B / 2 + guard_flare) / guard_proud);
echo(guard_front_above_face = fl_t, view_half_angle_clear = va, needed = fov_half);
echo(entry = entry, outer = [cx1 - cx0 + 2 * wall_t, cy1 - cy0 + 2 * wall_t, z_top], front_plate = t_f, lens_pos = lens_pos);
