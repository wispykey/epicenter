shader_type canvas_item;

// --- Uniforms --- //
uniform float opacity: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float circle_width: hint_range(0.0, 1.0, 0.05) = 0.15;
uniform float wait_time: hint_range(0.0, 5.0, 0.1) = 0.5;
uniform float speed: hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float alpha_boost: hint_range(1.0, 5.0, 0.1) = 2.0;
uniform float r: hint_range(0.0, 0.4, 0.01) = 0.4;
uniform float ring_width: hint_range(0.01, 0.05, 0.01) = 0.04;

// --- Functions --- //
void fragment() {
    float dist = distance(UV, vec2(0.5));

    // Start with transparent base
    COLOR.a = 0.0;

    // --- Ring 1 ---
    COLOR.a += step(r, dist) * (1.0 - step(r + ring_width, dist)) * opacity; // inner red


    // Optional fade near edges
    COLOR.a *= 1.0 - smoothstep(0.7, 0.8, dist);
}
