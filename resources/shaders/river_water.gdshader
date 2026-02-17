shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_schlick_ggx;

uniform vec4 water_color : source_color = vec4(0.1, 0.3, 0.5, 0.75);
uniform vec4 foam_color : source_color = vec4(0.8, 0.9, 1.0, 0.5);
uniform float flow_speed : hint_range(0.0, 5.0) = 0.5;
uniform float flow_direction_degrees : hint_range(0.0, 360.0) = 180.0;
uniform float wave_scale : hint_range(0.1, 10.0) = 2.0;
uniform float wave_height : hint_range(0.0, 1.0) = 0.1;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.05;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.3;

void vertex() {
	float time = TIME * flow_speed;
	float wave = sin(VERTEX.x * wave_scale + time * 2.0) * cos(VERTEX.z * wave_scale * 0.7 + time) * wave_height;
	VERTEX.y += wave;
}

void fragment() {
	float dir_rad = flow_direction_degrees * 3.14159265 / 180.0;
	vec2 flow_dir = vec2(cos(dir_rad), sin(dir_rad));
	vec2 uv_offset = flow_dir * TIME * flow_speed;

	vec2 uv1 = UV * wave_scale + uv_offset;
	vec2 uv2 = UV * wave_scale * 1.3 + uv_offset * 0.7;

	float pattern1 = sin(uv1.x * 6.28) * sin(uv1.y * 6.28) * 0.5 + 0.5;
	float pattern2 = sin(uv2.x * 6.28 + 1.0) * sin(uv2.y * 6.28 + 1.0) * 0.5 + 0.5;
	float combined = mix(pattern1, pattern2, 0.5);

	vec4 final_color = mix(water_color, foam_color, combined * 0.15);
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
	ROUGHNESS = roughness_val;
	METALLIC = metallic_val;
	NORMAL_MAP_DEPTH = 0.5;
}
