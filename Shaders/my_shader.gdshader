shader_type canvas_item;

// --- Uniforms --- //
uniform float circle_width: hint_range(0.0, 1.0, 0.05) = 0.15;
uniform float wait_time: hint_range(0.0, 5.0, 0.1) = 0.5;
uniform float speed: hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float alpha_boost: hint_range(1.0, 5.0, 0.1) = 2.0;

// --- Functions --- //
void fragment() {
    float dist = distance(UV, vec2(0.5));

    // Start with transparent base
    COLOR.a = 0.0;

    // --- Ring 1 ---
    COLOR.a += step(0.18, dist) * (1.0 - step(0.22, dist)); // inner red
    // --- Ring 2 ---
    COLOR.a += step(0.28, dist) * (1.0 - step(0.32, dist)); // white
    // --- Ring 3 ---
    COLOR.a += step(0.38, dist) * (1.0 - step(0.42, dist)); // blue
    // --- Ring 4 ---
    COLOR.a += step(0.48, dist) * (1.0 - step(0.52, dist)); // black
    // --- Ring 5 ---
    COLOR.a += step(0.58, dist) * (1.0 - step(0.62, dist)); // gold

    // Optional fade near edges
    COLOR.a *= 1.0 - smoothstep(0.7, 0.8, dist);
}
