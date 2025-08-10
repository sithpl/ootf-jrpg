shader_type canvas_item;

uniform float flash_strength : hint_range(0, 1) = 0.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    if (flash_strength > 0.0) {
        // Invert and brighten the color
        tex.rgb = mix(tex.rgb, 1.0 - tex.rgb, flash_strength);
        tex.rgb = mix(tex.rgb, vec3(1.0), flash_strength * 0.5); // make it brighter
    }
    COLOR = tex;
}