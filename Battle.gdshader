shader_type canvas_item;

uniform float radius        : hint_range(0.0, 1.5) = 0.0;
uniform float edge_falloff  : hint_range(0.0, 0.1) = 0.02;

void fragment() {
    // UV coords [0,1] across the screen
    vec2 uv = SCREEN_UV;
    // Distance from center
    float d = distance(uv, vec2(0.5));

    // 0 inside circle, 1 outside, with soft edge
    float mask = smoothstep(radius, radius - edge_falloff, d);

    // Black with the mask controlling opacity
    COLOR = vec4(0.0, 0.0, 0.0, mask);
}
