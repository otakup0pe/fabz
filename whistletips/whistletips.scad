//
// Parametric Tailpipe Whistletip ("WHOOOOO")
// ==========================================
//
// Slip-over whistle tip for a vehicle tailpipe, secured with a single
// set screw. Generates an edge-tone "WHOOOOO" by forcing exhaust
// through a side window with a sharp downstream labium (the splitting
// edge that produces the whistle).
//
// Cross-section overview (axis along Z, exhaust flows in +Z direction):
//
//   pipe end                 throat shoulder    window     exit
//      |                          |                |        |
//      v                          v                v        v
//   |==========================|=======================|=======|
//   |                          |                       |       |
//   |  engagement bore (slips  |  resonator (throat)   | exit  |
//   |  over tailpipe OD)       |   bore -- smaller     |  lip  |
//   |                          |  -- window cut here   |       |
//   |==========================|=======================|=======|
//                                       \  /
//                                        \/  <- labium edge (sharp)
//
// The part slides onto the tailpipe up to the throat shoulder, where
// the bore steps down. Exhaust is forced into the smaller throat
// bore, then spills out through the side window across the sharp
// labium edge -- this is the edge-tone source. The exit lip adds
// back-pressure so more flow is diverted across the labium.
//
// MATERIAL NOTE: this is a 3D-printed novelty. Real tailpipe surface
// temperatures on a running engine routinely exceed 200 C; common
// printable plastics (PLA ~60 C, PETG ~70 C, ABS ~95-100 C, ASA
// ~100 C, PC ~135 C, PEEK ~250+ C) will at best deform and at worst
// drip onto your exhaust. Treat printed parts as cosplay/prop, or
// print a master and cast in metal if you want it to survive a drive.
//

//
// --- Configuration ---
//

// --- Tailpipe Fit ---
// Outer diameter of the tailpipe this part slips over (mm).
pipe_od = 50.0;
// Diametral clearance for slip fit (mm). Added to pipe_od for the
// engagement bore. Increase for a looser fit, decrease for tighter.
pipe_clearance = 0.4;
// How far the part engages onto the tailpipe (mm).
engagement_length = 30.0;

// --- Body ---
// Wall thickness around the body (mm).
wall_thickness = 3.0;
// Length of the resonator chamber past the engagement (mm). The
// window lives in this section. Larger = lower pitch.
chamber_length = 60.0;
// Internal diameter of the resonator/throat (mm). Smaller than the
// tailpipe ID creates back-pressure that feeds the whistle. Set equal
// to bore_engagement (= pipe_od + pipe_clearance) for no restriction.
throat_id = 26.0;
// Length of the exit lip past the chamber (mm). Set 0 to omit.
exit_lip_length = 8.0;
// Internal diameter of the final exit aperture (mm). Equal to
// throat_id for no further restriction; smaller for more back
// pressure. ~50% of throat_id is a loud-and-droning starting point.
exit_id = 14.0;

// --- Whistle Window ---
// Circumferential width of the window (degrees of arc).
window_arc = 50;
// Axial length of the window along the inner wall (mm).
window_length = 18.0;
// Axial offset of the window from the throat shoulder (mm).
// Constraint: window_offset + window_length <= chamber_length.
window_offset = 8.0;
// Depth of the labium bevel (mm). The downstream edge of the window
// is undercut by this much, forming a knife edge at the bore where
// the airflow splits. Constraint: 0 < labium_bevel_depth < window_length.
labium_bevel_depth = 2.5;
// Rotational position of the window center (degrees, 0 = +X axis).
window_angle = 90;

// --- Set Screw ---
// Set screw clearance hole diameter (mm).
// M4 ~4.2, M5 ~5.2, M6 ~6.4, 1/4" tap drill ~5.1.
// For a self-tapping screw, use the screw's minor diameter.
set_screw_diameter = 5.2;
// Outer diameter of the boss around the set screw (mm).
set_screw_boss_diameter = 12.0;
// How far the boss protrudes past the outer body wall (mm).
set_screw_boss_height = 2.5;
// Axial position of the set screw center from the open (engagement)
// end (mm). Constraint: keep within engagement section,
// 0 < set_screw_position < engagement_length.
set_screw_position = 12.0;
// Rotational position of the set screw (degrees, 0 = +X axis).
set_screw_angle = 270;

// --- Misc ---
// Cutter overshoot to avoid coincident faces.
epsilon = 0.05;
// Render quality. Higher = smoother curves, slower preview.
$fn = 120;

// --- Derived ---
bore_engagement = pipe_od + pipe_clearance;
outer_diameter = pipe_od + pipe_clearance + 2 * wall_thickness;
total_length = engagement_length + chamber_length + exit_lip_length;
window_z0 = engagement_length + window_offset;
window_z1 = window_z0 + window_length;

//
// --- Modules ---
//

// Outer body cylinder.
module body_outer() {
    cylinder(h = total_length, d = outer_diameter);
}

// Stepped internal bore: engagement -> throat -> exit lip.
module bore_cutter() {
    // Engagement bore (slips over the tailpipe).
    translate([0, 0, -epsilon])
        cylinder(h = engagement_length + epsilon, d = bore_engagement);

    // Resonator/throat bore (where the window lives).
    translate([0, 0, engagement_length - epsilon])
        cylinder(h = chamber_length + 2 * epsilon, d = throat_id);

    // Exit lip bore.
    if (exit_lip_length > 0) {
        translate([0, 0, engagement_length + chamber_length - epsilon])
            cylinder(h = exit_lip_length + 2 * epsilon, d = exit_id);
    }
}

// Side window cut through the wall, with the downstream face beveled
// to form a sharp labium at the bore. The 2D polygon is a quadrilateral
// in (radial, axial) space; rotate_extrude sweeps it through window_arc.
//
// Polygon corners (r = radius from axis, z = axial):
//   A = (r_inner, z_upstream)        -- inner upstream
//   B = (r_outer, z_upstream)        -- outer upstream
//   C = (r_outer, z_outer_downstream) -- outer downstream (bevel start)
//   D = (r_inner, z_inner_downstream) -- inner downstream (labium edge)
//
// The C->D edge is the labium bevel face. The labium itself is the
// sharp circumferential edge at D where the bevel meets the bore.
module window_cutter() {
    r_in = throat_id / 2 - epsilon;
    r_out = outer_diameter / 2 + epsilon;
    z_outer_down = window_z1 - labium_bevel_depth;

    rotate([0, 0, window_angle - window_arc / 2]) {
        rotate_extrude(angle = window_arc) {
            polygon(points = [
                [r_in,  window_z0],
                [r_out, window_z0],
                [r_out, z_outer_down],
                [r_in,  window_z1]
            ]);
        }
    }
}

// Solid boss around the set screw, oriented radially. The cylinder
// runs from the central axis outward to (wall + boss_height); the
// portion inside the body is absorbed into the body, leaving a bump
// outside and extra wall thickness around the screw hole inside.
module set_screw_boss() {
    translate([0, 0, set_screw_position])
        rotate([0, 0, set_screw_angle])
            rotate([0, 90, 0])
                cylinder(h = outer_diameter / 2 + set_screw_boss_height,
                         d = set_screw_boss_diameter);
}

// Clearance hole through the boss and wall for the set screw.
module set_screw_hole() {
    translate([0, 0, set_screw_position])
        rotate([0, 0, set_screw_angle])
            rotate([0, 90, 0])
                translate([0, 0, -epsilon])
                    cylinder(h = outer_diameter / 2 + set_screw_boss_height + 2 * epsilon,
                             d = set_screw_diameter);
}

//
// --- Assemble the Final Model ---
//

difference() {
    union() {
        body_outer();
        set_screw_boss();
    }

    bore_cutter();
    window_cutter();
    set_screw_hole();
}
