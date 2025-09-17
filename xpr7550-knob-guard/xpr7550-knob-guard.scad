//
// Parametric Motorola XPR7550 Radio Knob Guard
// ===========================================
//
// This script generates a 3d model of a "knob guard" for a common
// form of Motorola radio. The antenna nestles in one hole, and the
// other holes should fit over the volume and channel knobs. There are
// two included presets for the antennas I have stumbled across (1mm
// difference).
//
// There are a lot of configurable options, as folks have feelings
// about how they use their radios. The plate thickness, plate
// padding, tolerance, and antenna diameter, all affect the base
// layout of the knob guard.
//
// There are additional parameters for lanyard clip and the shoulder
// mic (or "squid") accessory.  The channel and volume knobs can have
// their heigh, coverage angle, position angle, and slope
// configured. There is a single wall thickness parameter. You can can
// also change the distance from the antenna to channel knob and the
// channel to volume knob - this may allow adaptation for other XPR
// series radios.

//
// --- Configuration ---
//

// --- Primary Dimensions ---
// Diameter of the antenna base where it meets the radio body (in mm).
antenna_diameter = 13.5;
// Diameter of the channel selector knob (in mm).
channel_knob_diameter = 13.1;
// Diameter of the volume/power knob (in mm).
volume_knob_diameter = 15.1;
// Thickness of the base plate that sits on top of the radio (in mm).
plate_thickness = 3;

// --- Channel Knob Guard ---
// Height of the protective wall around the channel knob (in mm).
channel_guard_height = 8.5;
// How much of the channel knob to surround with a solid wall (in degrees).
channel_guard_coverage_angle = 270;
// The position of the guard. 0=right, 90=front, 180=left, 270=back.
channel_guard_position_angle = 180;
// Rounded Slope Inset: How far (in mm) the top of the guard is inset.
channel_guard_slope_inset = 2.1;

// --- Volume Knob Guard ---
// Height of the protective wall around the volume knob (in mm).
volume_guard_height = 7.1;
// How much of the volume knob to surround with a solid wall (in degrees).
volume_guard_coverage_angle = 220;
// The position of the guard. 0=right, 90=front, 180=left, 270=back.
volume_guard_position_angle = 0;
// Rounded Slope Inset: How far (in mm) the top of the guard is inset.
volume_guard_slope_inset = 2.1;

// --- Spacing Dimensions ---
// Center-to-center distance from the antenna to the channel knob (in mm).
antenna_to_channel_dist = 17.7;
// Center-to-center distance from the channel knob to the volume knob (in mm).
channel_to_volume_dist = 16.8;

// --- Design Tweaks ---
// The thickness of the protective walls around the knobs (in mm).
guard_wall_thickness = 3.1;
// Extra material to add around the perimeter of the base plate (in mm).
plate_padding = 1.2;
// How much larger the holes should be than the knobs/antenna for a good fit (in mm).
tolerance = 0.5;
// A small value to ensure cutters fully pass through objects, preventing rendering glitches.
// You probably do not want to change this.
epsilon = 0.1;
// Set rendering quality. Higher numbers make smoother curves.
// You probably do not want to change this.
$fn = 100;

// --- Clip Notch Parameters (for mic clip) ---
// Width of the rear notch (X-axis) in mm.
clip_notch_width = 7.9;
// Height of the rear notch (Z-axis) in mm.
clip_notch_height = 1.8;
// Depth of the rear notch (Y-axis) in mm.
clip_notch_depth = 3.25;
// X-axis offset for the notch from the center of the antenna in mm.
clip_notch_x_offset = 0;

// --- Squid Notch Parameters (for finger grip) ---
// This notch makes it easier to remove/attach the shoulder mic. I
// don't know why we call them squids at Burning Man, but we do.

// Width of the side notch (Y-axis) in mm.
squid_notch_width = 13;
// Height of the side notch (Z-axis) from the bottom of the plate in mm.
squid_notch_height = 3;
// Depth of the side notch (X-axis) in mm.
squid_notch_depth = 5;
// Y-axis offset for the notch from the center of the plate in mm.
squid_notch_y_offset = 0;

// --- Channel Knob Bottom Cut Parameters ---
// Height of the cylindrical cut from the bottom of the plate (in mm).
channel_knob_bottom_cut_height = 1.8;
// Additional radius beyond the channel knob's radius for the cylindrical cut (in mm).
channel_knob_bottom_cut_padding = 1.1;

// --- Here Be Dragons ---

// Calculate positions based on distances
antenna_pos = [0, 0, 0];
channel_knob_pos = [antenna_to_channel_dist, 0, 0];
volume_knob_pos = [antenna_to_channel_dist + channel_to_volume_dist, 0, 0];

// -- Reusable Modules --

// Creates a 2D polygon of a partial ring.
module arc_2d(outer_r, inner_r, angle) {
    step = max(0.01, angle / ($fn * (angle/360)));
    points = concat(
        [for (i = [0:step:angle]) [outer_r * cos(i), outer_r * sin(i)]],
        [for (i = [angle:-step:0]) [inner_r * cos(i), inner_r * sin(i)]]
    );
    polygon(points);
}

// Creates the main plate body using a hull of the knob/antenna areas.
module plate_body() { hull() {
    translate(antenna_pos) circle(d=antenna_diameter + (guard_wall_thickness*2) + (plate_padding*2));
    translate(channel_knob_pos) circle(d=channel_knob_diameter + (guard_wall_thickness*2) + (plate_padding*2));
    translate(volume_knob_pos) circle(d=volume_knob_diameter + (guard_wall_thickness*2) + (plate_padding*2));
}}

// Creates a SOLID guard with a rounded slope using hull().
// The hole will be cut in the final assembly step.
module rounded_sloped_guard(
    height, coverage_angle,
    knob_diameter, slope_inset
) {
    // Prevent slope inset from creating an invalid shape
    slope_inset = min(slope_inset, guard_wall_thickness - epsilon);

    outer_r_base = knob_diameter/2 + guard_wall_thickness;
    inner_r_base = knob_diameter/2 + tolerance/2;

    outer_r_top = outer_r_base - slope_inset;
    inner_r_top = inner_r_base; // Inner top radius is NOT inset, to help hull()

    hull() {
        // Base of the guard
        linear_extrude(height = epsilon) {
            arc_2d(outer_r_base, inner_r_base, coverage_angle);
        }

        // Top of the guard, with only the outside inset and raised
        if (height > epsilon) {
            translate([0, 0, height - epsilon]) {
                linear_extrude(height = epsilon) {
                    arc_2d(outer_r_top, inner_r_top, coverage_angle);
                }
            }
        }
    }
}

// Creates a rectangular notch on the rear of the plate for the mic clip.
module clip_notch() {
    // The plate is a hull() of circles centered on the X-axis (y=0).
    // The rearmost point of the plate is determined by the circle with the largest radius.
    rearmost_y = -max(
        (antenna_diameter/2 + guard_wall_thickness + plate_padding),
        max(
            (channel_knob_diameter/2 + guard_wall_thickness + plate_padding),
            (volume_knob_diameter/2 + guard_wall_thickness + plate_padding)
        )
    );

    // Position the notch to cut from the rearmost point inwards.
    translate([
        clip_notch_x_offset - (clip_notch_width/2),
        rearmost_y - epsilon, // Start cut slightly outside the object
        -epsilon // Start cut slightly below the plate
    ]) {
        cube([
            clip_notch_width,
            clip_notch_depth + (2 * epsilon), // Ensure cut goes deep enough
            clip_notch_height + (2 * epsilon) // Ensure cut goes high enough
        ]);
    }
}

// Creates a rectangular notch on the side (-X) of the plate for finger grip.
module squid_notch() {
    // The plate is a hull() of circles translated along the X-axis.
    // The leftmost point is determined by the antenna circle at x=0.
    leftmost_x = -(antenna_diameter/2 + guard_wall_thickness + plate_padding);

    // Position the notch to cut from the leftmost point inwards.
    translate([
        leftmost_x - epsilon, // Start cut slightly outside the object
        -squid_notch_width / 2 + squid_notch_y_offset, // Center the notch on the Y-axis and apply offset
        -epsilon // Start cut slightly below the plate
    ]) {
        cube([
            squid_notch_depth + (2 * epsilon),
            squid_notch_width,
            squid_notch_height + (2 * epsilon)
        ]);
    }
}


// Creates a cylindrical cut on the bottom of the plate, centered on the channel knob.
module bottom_cut() {
    // This cutter's radius is the channel knob's radius plus a padding value.
    // It is defined at the origin and translated into position when called.
    cut_radius = (channel_knob_diameter / 2) + channel_knob_bottom_cut_padding;
    cut_height = channel_knob_bottom_cut_height;

    translate([0, 0, -epsilon]) { // Start slightly below the plate bottom
        cylinder(h = cut_height + (2 * epsilon), r = cut_radius);
    }
}

// --- Assemble the Final Model ---

difference() {
    // --- Positive Geometry ---
    // All solid objects are created here in a union.
    union() {
        // 1. Create the solid base plate
        linear_extrude(height = plate_thickness) plate_body();

        // 2. Create and position the Channel Knob Guard
        translate(channel_knob_pos) {
            translate([0,0,plate_thickness]) {
                rotate([0, 0, channel_guard_position_angle]) {
                    rotate([0, 0, -channel_guard_coverage_angle / 2]) {
                        rounded_sloped_guard(
                            height = channel_guard_height,
                            coverage_angle = channel_guard_coverage_angle,
                            knob_diameter = channel_knob_diameter,
                            slope_inset = channel_guard_slope_inset
                        );
                    }
                }
            }
        }

        // 3. Create and position the Volume Knob Guard
        translate(volume_knob_pos) {
            translate([0,0,plate_thickness]) {
                rotate([0, 0, volume_guard_position_angle]) {
                    rotate([0, 0, -volume_guard_coverage_angle / 2]) {
                        rounded_sloped_guard(
                            height = volume_guard_height,
                            coverage_angle = volume_guard_coverage_angle,
                            knob_diameter = volume_knob_diameter,
                            slope_inset = volume_guard_slope_inset
                        );
                    }
                }
            }
        }
    }

    // --- Negative Geometry ---
    // All subtractions happen here, on the final solid object.

    // A. Cut the main holes for antenna and knobs
    // Cutter height needs to be taller than the whole model.
    cutter_h = plate_thickness + max(channel_guard_height, volume_guard_height) + (2*epsilon);

    // Antenna Hole
    translate(antenna_pos) {
        translate([0,0,-epsilon]) cylinder(h = cutter_h, d = antenna_diameter+tolerance);
    }
    // Channel Knob Hole
    translate(channel_knob_pos) {
        translate([0,0,-epsilon]) cylinder(h = cutter_h, d = channel_knob_diameter+tolerance);
    }
    // Volume Knob Hole
    translate(volume_knob_pos) {
        translate([0,0,-epsilon]) cylinder(h = cutter_h, d = volume_knob_diameter+tolerance);
    }

    // B. Cut the clip notch from the rear
    clip_notch();

    // C. Cut the squid notch from the side
    squid_notch();

    // D. Cut the cylinder from the bottom
    translate(channel_knob_pos) bottom_cut();
}
