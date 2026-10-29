shader_type spatial;
render_mode unshaded;

uniform sampler2D source_color_texture
    : source_color, filter_nearest, repeat_disable;

uniform sampler2D raw_texture
    : filter_nearest, repeat_disable;

uniform bool use_source_color = true;

void fragment() {
    if (use_source_color) {
        ALBEDO = texture(source_color_texture, UV).rgb;
    } else {
        ALBEDO = texture(raw_texture, UV).rgb;
    }
}