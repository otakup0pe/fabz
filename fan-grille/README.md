# Shelf Grille w/ Fan Mount

Friction-fit shelf grille with fan mounting for the a network cabinet.
Press-fits into a routed cutout from below. Parametric OpenSCAD design.

## Fan

Noctua NF-A4x10 5V PWM (40mm x 40mm x 10mm). M3 mounting at 32mm spacing.

## Parameters

All dimensions parametric via OpenSCAD Customizer. Key params:
- `shelf_thickness` -- match your shelf (default 19mm / 3/4")
- `cutout_width`, `cutout_height` -- match your routed opening
- `fan_count` -- 1 or 2 fans per grille
- `friction_clearance` -- tune for your printer (start 0.2mm)
- `grille_pattern` -- "hex" honeycomb or "slots"

## Print

- Material: PETG
- Orientation: face-down (grille on bed)
- Supports: none needed
- Settings: 240C nozzle, 70-85C bed, 3-4 perimeters, 20-30% gyroid

## Assembly

1. Route cutout in shelf (match `cutout_width` x `cutout_height`)
2. Press grille up through cutout from below -- tabs grip shelf edge
3. Mount fans with M3x8 self-tapping screws (or heat-set inserts)
4. Route 4-pin PWM cables through cable channel
