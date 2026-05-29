shader_type canvas_item;

uniform sampler2D cell_texture : repeat_enable;
uniform float cell_size = 16.0;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 fill_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);

void fragment() {
    vec2 node_size = vec2(1.0) / fwidth(UV);
    vec2 tiled_uv  = UV * node_size / cell_size;
    float cell     = texture(cell_texture, tiled_uv).r;

    COLOR = mix(fill_color, line_color, cell);
}