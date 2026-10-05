$fn = 48;
width = 40;
depth = 30;
height = 25;
thickness = 4;
hole_d = 4.3;
csink_d = 8.5;
csink_depth = 2.4;

difference() {
  union() {
    cube([width, depth, thickness]);
    cube([thickness, depth, height]);
  }
  for (x = [10, width - 10]) {
    translate([x, depth / 2, -1]) cylinder(h = thickness + 2, d = hole_d);
    translate([x, depth / 2, thickness - csink_depth])
      cylinder(h = csink_depth + 1, d1 = hole_d, d2 = csink_d);
  }
}