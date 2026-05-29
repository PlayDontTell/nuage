shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 2.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 size = blur_amount / vec2(textureSize(TEXTURE, 0));
    vec4 color = vec4(0.0);

    // 9-tap Gaussian blur
    color += texture(TEXTURE, UV + vec2(-size.x,  size.y));
    color += texture(TEXTURE, UV + vec2(0.0,      size.y));
    color += texture(TEXTURE, UV + vec2( size.x,  size.y));
    color += texture(TEXTURE, UV + vec2(-size.x,  0.0  ));
    color += texture(TEXTURE, UV + vec2(0.0,      0.0  ));
    color += texture(TEXTURE, UV + vec2( size.x,  0.0  ));
    color += texture(TEXTURE, UV + vec2(-size.x, -size.y));
    color += texture(TEXTURE, UV + vec2(0.0,     -size.y));
    color += texture(TEXTURE, UV + vec2( size.x, -size.y));

    COLOR = color / 9.0;
}