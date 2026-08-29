// godot_waterfall의 displacement_n_uvscroll.gdshader 이식본.
// 원본 계산은 그대로 두고, 중간값을 눈으로 확인하는 debug_view만 덧붙였다.
//
// 구조
//   vertex()   : 변위 텍스처를 스크롤하며 읽어 법선 방향으로 정점을 밀어냄
//   fragment() : 베이스 색 + (스크롤 물결 2장을 곱한 오버레이) → ALBEDO / NORMAL_MAP
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

// --- 버텍스 디스플레이스먼트 ---
uniform vec2 uv_dis_scale = vec2(1.0, 1.0);
uniform vec2 dis_scroll;
uniform sampler2D displacement_tut : repeat_enable;
uniform float displace_parameter;

// --- 베이스 색 ---
uniform sampler2D base_color_texture : source_color;

// --- 물결 레이어 1 ---
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 scroll;
uniform sampler2D water_texture;

// --- 물결 레이어 2 ---
uniform vec2 uv_scale2 = vec2(1.0, 1.0);
uniform vec2 scroll2;
uniform sampler2D water_texture2;

uniform float overlay_alpha : hint_range(0, 1) = 1;
uniform float normal_depth : hint_range(0, 1) = 0;

// 0 정상 · 1 물결1 · 2 물결2 · 3 곱한 오버레이 · 4 베이스 · 5 변위 텍스처
uniform int debug_view = 0;

// UV를 중심(0.5, 0.5) 기준으로 확대/축소 (원본 VisualShader의 UVFunc "Scaling")
vec2 scale_uv(vec2 uv, vec2 scale) {
	vec2 pivot = vec2(0.5);
	return (uv - pivot) * scale + pivot;
}

void vertex() {
	vec2 dis_uv = scale_uv(UV, uv_dis_scale) + TIME * dis_scroll;
	vec3 displacement = texture(displacement_tut, dis_uv).rgb;

	VERTEX += (NORMAL + displacement) * displace_parameter;
}

void fragment() {
	vec4 base = texture(base_color_texture, UV);

	vec2 uv1 = scale_uv(UV, uv_scale) + TIME * scroll;
	vec2 uv2 = scale_uv(UV, uv_scale2) + TIME * scroll2;
	vec4 layer1 = texture(water_texture, uv1);
	vec4 layer2 = texture(water_texture2, uv2);

	// 두 물결을 곱해 겹치는 부분만 남기고, 세기를 overlay_alpha로 조절
	vec4 overlay = layer1 * layer2 * overlay_alpha;

	ALBEDO = (base + overlay).rgb;
	METALLIC = 0.0;
	ROUGHNESS = 0.5;
	NORMAL_MAP = overlay.rgb;
	NORMAL_MAP_DEPTH = normal_depth;

	// 디버그: 중간값을 EMISSION으로 내보내 조명 영향을 걷어낸다.
	// fragment()는 return이 금지라 끝에서 덮어쓴다.
	if (debug_view != 0) {
		vec3 raw;
		if (debug_view == 1) {
			raw = layer1.rgb;
		} else if (debug_view == 2) {
			raw = layer2.rgb;
		} else if (debug_view == 3) {
			raw = (layer1 * layer2).rgb;
		} else if (debug_view == 4) {
			raw = base.rgb;
		} else {
			vec2 dis_uv = scale_uv(UV, uv_dis_scale) + TIME * dis_scroll;
			raw = texture(displacement_tut, dis_uv).rgb;
		}
		ALBEDO = vec3(0.0);
		EMISSION = raw;
		NORMAL_MAP_DEPTH = 0.0;
		// 하늘 반사가 데이터 위에 덧씌워지면 색이 씻겨 보인다. 반사도 끈다.
		SPECULAR = 0.0;
		ROUGHNESS = 1.0;
	}
}
