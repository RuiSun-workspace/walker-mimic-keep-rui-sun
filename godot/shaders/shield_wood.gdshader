shader_type spatial;


/* Texture inputs */

uniform sampler2D wood_albedo_texture
    : source_color, filter_linear_mipmap, repeat_enable;

uniform sampler2D wood_roughness_texture
    : filter_linear_mipmap, repeat_enable;

uniform sampler2D wood_normal_texture
    : hint_normal, filter_linear_mipmap, repeat_enable;

uniform sampler2D scorch_mask_texture
    : filter_linear_mipmap, repeat_disable;


/* Surface controls */

group_uniforms Surface;

uniform vec4 wood_tint
    : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float texture_scale
    : hint_range(0.25, 4.0, 0.05) = 1.0;

uniform float roughness_scale
    : hint_range(0.0, 1.0, 0.01) = 0.85;

uniform float normal_strength
    : hint_range(0.0, 1.0, 0.01) = 1.0;


/* Damage controls */

group_uniforms Damage;

uniform float scorch_amount
    : hint_range(0.0, 1.0, 0.01) = 0.0;

uniform vec4 scorch_color
    : source_color = vec4(0.08, 0.025, 0.01, 1.0);

uniform float char_roughness
    : hint_range(0.0, 1.0, 0.01) = 0.95;

group_uniforms;


/* Material calculation */

void fragment() {
    // The wood textures repeat according to texture_scale.
    vec2 wood_uv = UV * texture_scale;

    vec3 wood_color = texture(wood_albedo_texture, wood_uv).rgb;
    float wood_roughness =
        texture(wood_roughness_texture, wood_uv).r;
    vec3 wood_normal =
        texture(wood_normal_texture, wood_uv).rgb;

    // The scorch mask uses the shield's original 0..1 UV layout.
    float mask_value = texture(scorch_mask_texture, UV).r;
    float scorch_mix = clamp(mask_value * scorch_amount, 0.0, 1.0);

    vec3 tinted_wood = wood_color * wood_tint.rgb;
    float scaled_roughness =
        clamp(wood_roughness * roughness_scale, 0.0, 1.0);

    ALBEDO = mix(tinted_wood, scorch_color.rgb, scorch_mix);
    ROUGHNESS = mix(scaled_roughness, char_roughness, scorch_mix);
    NORMAL_MAP = wood_normal;
    NORMAL_MAP_DEPTH = normal_strength;
}
