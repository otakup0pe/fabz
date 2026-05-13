// Aeotec WallMote Quad Mollyguard Cover
//
// A snap-on cover with hinged doors for each button.
// Designed to be print-in-place and multi-color compatible.
// Adheres to the following requirements:
// - Slip-over cover with an open back for the magnetic mount.
// - Print-in-place hinges.
// - Hinges open to the left for buttons 1 & 3.
// - Hinges open to the right for buttons 2 & 4.
// - Doors are flush with the frame and hinged on the outer edge.
// - Doors are inset from the frame walls.
// - Outer door corners are rounded to match the frame's inner curvature.

include <BOSL2/std.scad>
include <BOSL2/hinges.scad>

// --- Configurable Parameters ---

// Adjust for a tighter or looser fit.
// Positive values = tighter fit, Negative = looser.
snugness = 0.1; // [0:0.01:1]

// Labels for the four button covers.
cover_1_label = "1";
cover_2_label = "2";
cover_3_label = "3";
cover_4_label = "4";

// Angle to render the doors for visualization. 0 = closed.
door_open_angle = 30; // [0:1:120]

// Inset gap between the door and the frame wall.
cover_inset = 0.5; // [0:0.1:2]

// Scale factor for the labels on the doors.
label_scale = 0.8;

// --- Model Constants ---

// Device dimensions (Aeotec WallMote Quad ZW130)
device_w = 76.8;
device_h = 76.8;
device_d = 10.9;
device_r = 10; // User-specified corner radius

// Cover design
wall_thickness = 2.0;
cover_wall_depth = device_d; // The total depth of the cover's side walls

// Hinge parameters
hinge_pin_d = 1.5; // Diameter of the hinge pin
hinge_knuckle_d = hinge_pin_d * 3; // Knuckle diameter, BOSL2 default
hinge_offset = hinge_knuckle_d / 2; // Required offset from edge to center
hinge_segs = 5; // Number of knuckle segments per hinge

// Door and layout calculations
door_gap_y = 0.4; // Gap between doors on the Y axis
door_gap_x = 0.4; // Gap between doors on the X axis
inner_w = device_w - wall_thickness * 2;
inner_h = device_h - wall_thickness * 2;
inner_r = device_r - wall_thickness;

door_width = (inner_w - door_gap_x - cover_inset * 2) / 2;
door_height = (inner_h - door_gap_y - cover_inset * 2) / 2;
door_corner_r = inner_r - cover_inset;



// Tab parameters
tab_width = 10;
tab_height = 2;
tab_overhang = 2;

// Label text parameters
font_name = "Liberation Sans:style=Bold";
font_size = 10;
font_depth = 0.6; // Depth for multi-color printing (e.g., 3 layers at 0.2mm)

// --- Main Assembly ---

// For multi-color printing, render and export `cover_body()` and `cover_labels()`
// as separate STL files. By default, both are shown together.

$fn = 64; // Set resolution for curves

// 1. Render the main body and hinged doors (with text cut out)
color("lightgrey")
    cover_body();

// 2. Render the labels that fit flush into the doors
color("black")
    cover_labels();


// --- Modules ---

// Defines the 2D footprint of a rounded square
module rounded_square_footprint(w, h, r) {
    hull() {
        translate([-w/2 + r, -h/2 + r]) circle(r=r);
        translate([ w/2 - r, -h/2 + r]) circle(r=r);
        translate([-w/2 + r,  h/2 - r]) circle(r=r);
        translate([ w/2 - r,  h/2 - r]) circle(r=r);
    }
}

// Builds the main slip-over frame (walls only)
module frame() {
    union() {
        difference() {
            difference() {
                linear_extrude(height = cover_wall_depth) {
                    rounded_square_footprint(device_w, device_h, device_r);
                }
                translate([0, 0, -1]) {
                    linear_extrude(height = cover_wall_depth + 2) {
                        rounded_square_footprint(
                            device_w - (wall_thickness - snugness) * 2,
                            device_h - (wall_thickness - snugness) * 2,
                            device_r - wall_thickness + snugness
                        );
                    }
                }
            }
            // Subtract the 3D notches for the tabs from the completed frame
            notches_3d();
        }
        // Add the frame-side hinge knuckles
        frame_hinge_knuckles();
    }
}

// Creates 3D cutouts for the door tabs
module notches_3d() {
    // Add tolerance for a clean fit
    notch_w = tab_width + 0.4;
    notch_d = wall_thickness + 1; // Ensure it cuts fully through the wall
    notch_h = tab_height + 0.4;

    // Z-position should be centered on the door's thickness
    z_pos = cover_wall_depth - wall_thickness + notch_h/2;

    // Recalculate door center X-positions to align the notches
    door_center_x_left = -door_gap_x/2 - door_width/2;
    door_center_x_right = door_gap_x/2 + door_width/2;

    // Top notches
    notch_y_pos_top = inner_h/2 + notch_d/2 - cover_inset;
    translate([door_center_x_left, notch_y_pos_top, z_pos])
        cube([notch_w, notch_d, notch_h], center=true);
    translate([door_center_x_right, notch_y_pos_top, z_pos])
        cube([notch_w, notch_d, notch_h], center=true);

    // Bottom notches
    notch_y_pos_bottom = -inner_h/2 - notch_d/2 + cover_inset;
    translate([door_center_x_left, notch_y_pos_bottom, z_pos])
        cube([notch_w, notch_d, notch_h], center=true);
    translate([door_center_x_right, notch_y_pos_bottom, z_pos])
        cube([notch_w, notch_d, notch_h], center=true);
}





// --- Part-Specific Assemblies ---

// Assembly for the main body including doors
module cover_body() {
     union() {
        frame();
        place_doors(part="body");
    }
}

// Assembly for just the labels
module cover_labels() {
    place_doors(part="label");
}

// Places the four hinged door assemblies
module place_doors(part="both") {
    // Doors are flush with the top of the frame - print flat
    z_pos = cover_wall_depth - wall_thickness;

    // --- Symmetrical Door Placement ---
    // Calculate the center-point for each door based on the desired gaps.
    // This ensures consistent spacing on both X and Y axes.
    door_center_x_left = -door_gap_x/2 - door_width/2;
    door_center_x_right = door_gap_x/2 + door_width/2;
    door_center_y_top = door_gap_y/2 + door_height/2;
    door_center_y_bottom = -door_gap_y/2 - door_height/2;

    // Place doors by their calculated center points. The `hinged_door_assembly`
    // module will handle offsetting the hinge rotation point.

    // Button 1 (Top-Left)
    translate([door_center_x_left, door_center_y_top, z_pos])
        hinged_door_assembly(label = cover_1_label, hinge_side = "left", corner_vec = [-1, 1], part=part);
    // Button 2 (Top-Right)
    translate([door_center_x_right, door_center_y_top, z_pos])
        hinged_door_assembly(label = cover_2_label, hinge_side = "right", corner_vec = [1, 1], part=part);
    // Button 3 (Bottom-Left)
    translate([door_center_x_left, door_center_y_bottom, z_pos])
        hinged_door_assembly(label = cover_3_label, hinge_side = "left", corner_vec = [-1, -1], part=part);
    // Button 4 (Bottom-Right)
    translate([door_center_x_right, door_center_y_bottom, z_pos])
        hinged_door_assembly(label = cover_4_label, hinge_side = "right", corner_vec = [1, -1], part=part);
}

// Creates the frame-side hinge knuckles
module frame_hinge_knuckles() {
    // Position hinges recessed into the top surface to be flush
    // Knuckles centered vertically so their top is at the door surface
    z_pos = cover_wall_depth - wall_thickness - (hinge_knuckle_d / 2);

    // --- Symmetrical Door Placement ---
    door_center_x_left = -door_gap_x/2 - door_width/2;
    door_center_x_right = door_gap_x/2 + door_width/2;
    door_center_y_top = door_gap_y/2 + door_height/2;
    door_center_y_bottom = -door_gap_y/2 - door_height/2;

    // The hinge is placed at the door's edge (frame hinge aligns with door hinge)
    hinge_x_left = door_center_x_left - door_width/2;
    hinge_x_right = door_center_x_right + door_width/2;

    // Button 1 (Top-Left) - hinge opens to left, pin runs along Y-axis, knuckles face right
    translate([hinge_x_left, door_center_y_top, z_pos])
        rotate([90, 0, 90])
        knuckle_hinge(length=door_height, pin_diam=hinge_pin_d, knuckle_diam=hinge_knuckle_d, segs=hinge_segs, offset=hinge_offset, inner=true);
    // Button 2 (Top-Right) - hinge opens to right, pin runs along Y-axis, knuckles face left
    translate([hinge_x_right, door_center_y_top, z_pos])
        rotate([90, 0, -90])
        knuckle_hinge(length=door_height, pin_diam=hinge_pin_d, knuckle_diam=hinge_knuckle_d, segs=hinge_segs, offset=hinge_offset, inner=true);
    // Button 3 (Bottom-Left) - hinge opens to left, pin runs along Y-axis, knuckles face right
    translate([hinge_x_left, door_center_y_bottom, z_pos])
        rotate([90, 0, 90])
        knuckle_hinge(length=door_height, pin_diam=hinge_pin_d, knuckle_diam=hinge_knuckle_d, segs=hinge_segs, offset=hinge_offset, inner=true);
    // Button 4 (Bottom-Right) - hinge opens to right, pin runs along Y-axis, knuckles face left
    translate([hinge_x_right, door_center_y_bottom, z_pos])
        rotate([90, 0, -90])
        knuckle_hinge(length=door_height, pin_diam=hinge_pin_d, knuckle_diam=hinge_knuckle_d, segs=hinge_segs, offset=hinge_offset, inner=true);
}

// Creates a complete door with its knuckles, and rotates it
module hinged_door_assembly(label = "", hinge_side = "left", corner_vec = [0,0], part="both") {
    rotation_angle = (hinge_side == "left") ? -door_open_angle : door_open_angle;
    // The hinge pin is offset from the door edge. The rotation must be around the pin.
    hinge_offset_x = (hinge_side == "left") ? -door_width/2 - hinge_offset : door_width/2 + hinge_offset;

    // 1. Translate to the hinge's center of rotation.
    // 2. Rotate around the Y-axis (hinge opens left/right).
    // 3. Translate back.
    translate([hinge_offset_x, 0, 0]) {
        rotate([0, rotation_angle, 0]) {
            translate([-hinge_offset_x, 0, 0]) {
                union() {
                    door(
                        label = label,
                        hinge_side = hinge_side,
                        corner_vec = corner_vec,
                        part = part
                    );
                    // Door-side hinge knuckles - only create if rendering body
                    if (part == "body" || part == "both") {
                        // Door-side hinges must be at same position as frame-side for pins to align
                        // Frame hinges are at the edge: -door_width/2 for left, door_width/2 for right
                        hinge_x_door = (hinge_side == "left") ?
                            (-door_width/2) :
                            (door_width/2);

                        // Rotate 180° around Y to flip the knuckles so flat surface faces the door
                        // Frame left uses 90°, frame right uses -90°
                        door_rotation = (hinge_side == "left") ? 90 : -90;

                        // Pin runs along Y-axis, knuckles extend toward frame (outward from door)
                        translate([hinge_x_door, 0, -(hinge_knuckle_d / 2)])
                            rotate([90, 180, door_rotation])
                            knuckle_hinge(length=door_height, pin_diam=hinge_pin_d, knuckle_diam=hinge_knuckle_d, segs=hinge_segs, offset=hinge_offset, inner=false);
                    }
                }
            }
        }
    }
}

// Creates the 2D footprint of a door panel with one rounded corner.
// corner_vec specifies which corner to round, e.g., [1, 1] for top-right.
module door_panel_shape(w, h, r, corner_vec=[0,0]) {
    corner_x = corner_vec[0];
    corner_y = corner_vec[1];
    tiny_r = 0.01; // Use a very small radius for sharp corners in hull()

    hull() {
        // Place circles for the hull. Only the designated corner gets the full radius.
        // Bottom-left
        translate([-w/2 + (corner_x == -1 && corner_y == -1 ? r : tiny_r), -h/2 + (corner_x == -1 && corner_y == -1 ? r : tiny_r)])
            circle(r = (corner_x == -1 && corner_y == -1 ? r : tiny_r));
        // Bottom-right
        translate([w/2 - (corner_x == 1 && corner_y == -1 ? r : tiny_r), -h/2 + (corner_x == 1 && corner_y == -1 ? r : tiny_r)])
            circle(r = (corner_x == 1 && corner_y == -1 ? r : tiny_r));
        // Top-left
        translate([-w/2 + (corner_x == -1 && corner_y == 1 ? r : tiny_r), h/2 - (corner_x == -1 && corner_y == 1 ? r : tiny_r)])
            circle(r = (corner_x == -1 && corner_y == 1 ? r : tiny_r));
        // Top-right
        translate([w/2 - (corner_x == 1 && corner_y == 1 ? r : tiny_r), h/2 - (corner_x == 1 && corner_y == 1 ? r : tiny_r)])
            circle(r = (corner_x == 1 && corner_y == 1 ? r : tiny_r));
    }
}

// Creates the 2D shape for the text label
module label_shape(label) {
    scale([label_scale, label_scale, 1])
        text(label, size = font_size, font = font_name, halign = "center", valign = "center");
}

// Creates the door panel and/or the flush-fit label
module door(label, hinge_side, corner_vec, part="both") {
    width = door_width;
    height = door_height;
    thickness = wall_thickness;
    radius = door_corner_r;

    // --- Part 1: Door Panel Body (with cutout for label) ---
    if (part == "body" || part == "both") {
        union() {
            // Panel - now centered at the origin
            difference() {
                // 1. The solid door panel
                linear_extrude(height = thickness) {
                    door_panel_shape(width, height, radius, corner_vec);
                }

                // 2. The text shape to subtract
                if (label != "") {
                    epsilon = 0.01; // Small offset to prevent z-fighting
                    // Start the cut slightly inside the door and make it slightly taller
                    translate([0, 0, thickness - font_depth - epsilon]) {
                        linear_extrude(height = font_depth + (2 * epsilon)) {
                            label_shape(label);
                        }
                    }
                }
            }

            // Tab for opening
            // Positioned on the top or bottom edge of the door.
            if (corner_vec[1] != 0) {
                tab_y_center = corner_vec[1] * (height / 2 + tab_overhang / 2);
                translate([0, tab_y_center, thickness / 2]) {
                    cube([tab_width, tab_overhang, tab_height], center = true);
                }
            }
        }
    }

    // --- Part 2: The Label itself ---
    if ((part == "label" || part == "both") && label != "") {
        epsilon = 0.01; // Small offset to prevent z-fighting
        // Position the label to sit slightly recessed within the cutout.
        translate([0, 0, thickness - font_depth - epsilon]) {
            linear_extrude(height = font_depth) {
                label_shape(label);
            }
        }
    }
}
