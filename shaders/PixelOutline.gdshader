shader_type canvas_item;

// Toggle outline on/off
uniform bool outline_enabled = true;

// Outline colour
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Thickness in pixels (good values: 1..4)
uniform int thickness : hint_range(1, 4) = 1;

void fragment() {
    vec4 src = texture(TEXTURE, UV);

    // If outline is disabled -> draw sprite normally
    if (!outline_enabled) {
        COLOR = src;
    } else {
        // If this pixel is opaque -> draw sprite normally
        if (src.a > 0.0) {
            COLOR = src;
        } else {
            // This pixel is transparent -> check neighbours for outline
            float neighbour_alpha = 0.0;
            vec2 texel = TEXTURE_PIXEL_SIZE; // size of one texel in UV space

            // Fast path for thickness == 1: sample 8 neighbours
            if (thickness <= 1) {
                neighbour_alpha = max(neighbour_alpha, texture(TEXTURE, UV + vec2( texel.x,  0.0)).a);
                neighbour_alpha = max(neighbour_alpha, texture(TEXTURE, UV + vec2(-texel.x,  0.0)).a);
                neighbour_alpha = max(neighbour_alpha, texture(TEXTURE, UV + vec2( 0.0,  texel.y)).a);
                neighbour_alpha = max(neighbour_alpha, texture(TEXTURE, UV + vec2( 0.0, -texel.y)).a);
            } else {
                // General case: check a square of neighbours from -thickness..thickness
                for (int ox = -thickness; ox <= thickness; ox++) {
                    for (int oy = -thickness; oy <= thickness; oy++) {
                        if (ox == 0 && oy == 0) continue;
                        vec2 off = vec2(float(ox) * texel.x, float(oy) * texel.y);
                        neighbour_alpha = max(neighbour_alpha, texture(TEXTURE, UV + off).a);
                    }
                }
            }

            // If any neighbour is opaque, draw the outline colour; otherwise transparent
            if (neighbour_alpha > 0.0) {
                COLOR = outline_color;
            } else {
                COLOR = vec4(0.0);
            }
        }
    }
}