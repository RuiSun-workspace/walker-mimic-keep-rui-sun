shader_type canvas_item;

uniform float burn_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec4 burn_color : source_color = vec4(1.0, 0.752941, 0.125490, 1.0);

void fragment() {
    COLOR.rgb = mix(COLOR.rgb, burn_color.rgb, burn_mix);
}