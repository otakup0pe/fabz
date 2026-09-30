// ============================================================
// fan_grille.scad
// Circular friction-fit shelf grille with fan mounting for
// custom network cabinet.
//
// Press-fits into a round hole (cut with a keyhole/hole saw)
// from below. Friction tabs grip the hole wall. Fan posts
// accept M3 screws at 32mm spacing (standard 40mm fan pattern).
//
// Designed for PETG. No overhangs exceed 45 deg.
//
// Print orientation: face-down (grille surface on bed).
// Supports: none needed.
// ============================================================

/* [Shelf & Cutout] */

// Thickness of the shelf in mm. ~19mm = 3/4" nominal lumber.
shelf_thickness = 19;

// Diameter of the round hole cut in the shelf (keyhole saw).
cutout_diameter = 90;

// How far the friction tabs extend above the grille lip
// to grip the shelf hole wall. Should be <= shelf_thickness.
tab_grip_depth = 12;

// Clearance between tab OD and hole wall for friction fit.
// Decrease for tighter fit, increase if tabs are too stiff.
// Start at 0.2 and tune after first print.
friction_clearance = 0.2;

/* [Fan Configuration] */

// Fan body size (NF-A4x10 = 40mm). Used for post placement.
fan_size = 40;

// Fan mounting hole spacing (32mm = standard 40mm fan pattern).
fan_hole_spacing = 32;

// Fan depth (axial thickness). NF-A4x10 = 10mm.
fan_depth = 10;

// Diameter of fan mounting screw holes. M3 = 3.0mm clearance.
// Tap threads directly into PETG or use M3 heat-set inserts.
fan_screw_dia = 3.2;

// Fan post outer diameter. Posts are solid cylinders.
// Must be wide enough to contain screw hole + wall.
fan_post_dia = 8;

// Height of fan mounting posts above grille body floor.
// Should position fan flush with or slightly below shelf top.
fan_post_height = 10;

// Diameter of fan post pad (base that sits on grille plate).
// Slightly wider than post for adhesion to thin plate.
fan_post_pad_dia = 10;

// Thickness of the pad under each fan post.
fan_post_pad_height = 1.5;

/* [Grille Body] */

// Thickness of the main grille plate.
grille_plate_thickness = 3;

// Width of the outer border/lip that overhangs the shelf hole
// (sits flush against the underside of the shelf).
border_width = 6;

// Number of friction tabs around the circumference.
tab_count = 6;

// Angular width of each tab in degrees.
tab_arc_deg = 20;

// Wall thickness of friction tabs (radial).
tab_wall_thickness = 2.5;

/* [Grille Pattern] */

// Which airflow pattern to use for the grille disc.
grille_pattern = "hex"; // [hex, grid, lines]

// Hex pattern: circumradius of each hexagon cell.
hex_cell_radius = 5;

// Hex pattern: wall thickness between cells.
hex_wall = 1.5;

// Grid pattern: width of each square opening.
grid_cell_size = 8;

// Grid pattern: wall thickness between openings.
grid_wall = 1.5;

// Lines pattern: width of each slot opening.
lines_slot_width = 4;

// Lines pattern: wall thickness between slots.
lines_wall = 2;

/* [Cable Channel] */

// Add a cable routing notch at the edge of the grille?
cable_channel = true;

// Width of the cable channel notch (arc chord).
cable_channel_width = 10;

// Depth of the cable notch into the grille (radial).
cable_channel_depth = 12;

// ============================================================
// Derived dimensions
// ============================================================

// Radius of the hole in the shelf.
cutout_radius = cutout_diameter / 2;

// Outer radius of the grille disc (includes border lip).
outer_radius = cutout_radius + border_width;

// Radius of the grille area inside the tabs (usable pattern area).
inner_radius = cutout_radius - tab_wall_thickness;

// Fan post positions (32mm square pattern centered at origin).
function fan_post_pos(i) =
    let(s = fan_hole_spacing / 2)
    [[-s, -s], [s, -s], [s, s], [-s, s]][i];

// ============================================================
// Module: hex_grille_disc
// Fills a circular area with hexagonal honeycomb by subtracting
// hex cells from a solid disc.
// ============================================================
module hex_grille_disc(radius, thickness) {
    r  = hex_cell_radius;
    t  = hex_wall;
    hex_w = r * sqrt(3);
    col_step = hex_w + t;
    row_step = r * 1.5 + t * sin(60);

    cols = ceil(radius * 2 / col_step) + 2;
    rows = ceil(radius * 2 / row_step) + 2;

    intersection() {
        cylinder(h = thickness, r = radius, $fn = 128, center = true);
        difference() {
            cylinder(h = thickness, r = radius + 1, $fn = 128, center = true);
            for (row = [-rows : rows]) {
                for (col = [-cols : cols]) {
                    offset_x = (row % 2 != 0) ? col_step / 2 : 0;
                    translate([col * col_step + offset_x, row * row_step, 0])
                        cylinder(h = thickness + 1, r = r, $fn = 6, center = true);
                }
            }
        }
    }
}

// ============================================================
// Module: grid_grille_disc
// Fills a circular area with a rectangular grid of square
// openings by subtracting cubes from a solid disc.
// ============================================================
module grid_grille_disc(radius, thickness) {
    cell = grid_cell_size;
    wall = grid_wall;
    pitch = cell + wall;

    cols = ceil(radius * 2 / pitch) + 1;
    rows = cols;

    intersection() {
        cylinder(h = thickness, r = radius, $fn = 128, center = true);
        difference() {
            cylinder(h = thickness, r = radius + 1, $fn = 128, center = true);
            for (row = [-rows : rows]) {
                for (col = [-cols : cols]) {
                    translate([col * pitch, row * pitch, 0])
                        cube([cell, cell, thickness + 1], center = true);
                }
            }
        }
    }
}

// ============================================================
// Module: lines_grille_disc
// Fills a circular area with parallel slot openings.
// Slots run along the X axis; spacing along Y.
// ============================================================
module lines_grille_disc(radius, thickness) {
    slot_w = lines_slot_width;
    wall   = lines_wall;
    pitch  = slot_w + wall;

    count = ceil(radius * 2 / pitch) + 1;

    intersection() {
        cylinder(h = thickness, r = radius, $fn = 128, center = true);
        difference() {
            cylinder(h = thickness, r = radius + 1, $fn = 128, center = true);
            for (i = [-count : count]) {
                translate([0, i * pitch, 0])
                    cube([radius * 2 + 2, slot_w, thickness + 1], center = true);
            }
        }
    }
}

// ============================================================
// Module: fan_post
// A single mounting post with a blind screw hole, sitting on
// a small pad. No solid floor under the fan -- air flows freely.
// ============================================================
module fan_post() {
    screw_depth = 8;

    // Pad (wider base for plate adhesion)
    cylinder(h = fan_post_pad_height, d = fan_post_pad_dia, $fn = 32);

    // Post
    translate([0, 0, fan_post_pad_height])
    difference() {
        cylinder(h = fan_post_height - fan_post_pad_height, d = fan_post_dia, $fn = 32);
        translate([0, 0, fan_post_height - fan_post_pad_height - screw_depth])
            cylinder(h = screw_depth + 0.1, d = fan_screw_dia, $fn = 24);
    }
}

// ============================================================
// Module: fan_mount_group
// Places 4 posts at the standard fan hole pattern.
// ============================================================
module fan_mount_group() {
    for (i = [0 : 3]) {
        p = fan_post_pos(i);
        translate([p[0], p[1], grille_plate_thickness / 2])
            fan_post();
    }
}

// ============================================================
// Module: friction_tabs
// Radial tabs around the perimeter that grip the hole wall.
// ============================================================
module friction_tabs() {
    tab_ir = cutout_radius - tab_wall_thickness;
    tab_or = cutout_radius - friction_clearance;
    angle_step = 360 / tab_count;

    for (i = [0 : tab_count - 1]) {
        angle = i * angle_step;
        rotate([0, 0, angle])
        translate([0, 0, grille_plate_thickness / 2])
        linear_extrude(height = tab_grip_depth)
        difference() {
            // Tab arc (sector of annulus)
            intersection() {
                difference() {
                    circle(r = tab_or, $fn = 128);
                    circle(r = tab_ir, $fn = 128);
                }
                // Slice to arc width
                polygon([
                    [0, 0],
                    [tab_or * 1.5 * cos(-tab_arc_deg/2),
                     tab_or * 1.5 * sin(-tab_arc_deg/2)],
                    [tab_or * 1.5 * cos(tab_arc_deg/2),
                     tab_or * 1.5 * sin(tab_arc_deg/2)]
                ]);
            }
        }
    }
}

// ============================================================
// Module: cable_notch
// A rectangular notch cut from the edge for wire routing.
// ============================================================
module cable_notch() {
    translate([0, -(outer_radius), 0])
        cube([cable_channel_width, cable_channel_depth * 2,
              grille_plate_thickness + tab_grip_depth + 10],
             center = true);
}

// ============================================================
// Module: border_lip
// Solid ring that overhangs the shelf hole (sits against the
// underside of the shelf). Only the outer border -- inner area
// is provided by the hex grille pattern.
// ============================================================
module border_lip() {
    difference() {
        cylinder(h = grille_plate_thickness, r = outer_radius, $fn = 128, center = true);
        cylinder(h = grille_plate_thickness + 1, r = inner_radius, $fn = 128, center = true);
    }
}

// ============================================================
// Module: grille_infill
// Selected pattern filling the entire inner disc area. Extends
// under the fan -- fan pushes/pulls air through the pattern,
// which also serves as a blade guard.
// ============================================================
module grille_infill() {
    if (grille_pattern == "hex") {
        hex_grille_disc(inner_radius, grille_plate_thickness);
    } else if (grille_pattern == "grid") {
        grid_grille_disc(inner_radius, grille_plate_thickness);
    } else if (grille_pattern == "lines") {
        lines_grille_disc(inner_radius, grille_plate_thickness);
    }
}

// ============================================================
// Top-level assembly
// ============================================================
module shelf_grille() {
    difference() {
        union() {
            border_lip();
            grille_infill();
            fan_mount_group();
            friction_tabs();
        }

        // Cable routing notch (subtracted from everything)
        if (cable_channel) {
            cable_notch();
        }
    }
}

// Render the assembly.
shelf_grille();


// ============================================================
// PRINT NOTES
// ============================================================
// Print face-down (grille surface on build plate).
// PETG settings: 240C nozzle, 70-85C bed, 3-4 perimeters,
//   20-30% infill (gyroid). No supports needed.
//
// POST-PRINT TUNING:
// - If tabs are too loose: decrease friction_clearance (try 0.1).
// - If tabs crack on insertion: increase friction_clearance
//   (try 0.3) or sand the hole edges lightly.
// - Fan screws: M3x8 self-tapping works directly into PETG
//   posts. For removable fans: install M3 heat-set inserts
//   (4.5mm OD, 4mm L) with a soldering iron at ~220C.
//
// SHELF CUTOUT:
// - Use a keyhole saw / hole saw at cutout_diameter.
// - Clean up edges with sandpaper -- no precision needed,
//   friction tabs are tolerant.
//
// AIRFLOW DIRECTION:
// - Mount fan to pull air upward (intake from lower zone).
//   Fan label side faces down (toward lower zone) for intake.
// - Hex grille provides additional passive airflow area
//   around the fan perimeter.
