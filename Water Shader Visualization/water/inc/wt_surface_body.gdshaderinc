// ═══════════════════════════════════════════════════════════════════════════
//  wt_surface_body.gdshaderinc — 수면 셰이더 본문 (uniform + vertex + fragment + light)
//
//  Realistic 과 Toon 은 서로 다른 셰이더가 아니다. 같은 레이어 스택인데
//  각 레이어를 어떤 "연산자"로 채웠느냐만 다르다.
//    Realistic = 연속 함수 (exp, pow, GGX, mix)
//    Toon      = 계단 함수 (aa_step, floor, 좁은 smoothstep)
//  그래서 이 파일 하나를 두 .gdshader 가 공유하고, #define STYLE_TOON 이
//  레이어별 연산자를 통째로 갈아끼운다. (docs/water-shader-analysis.md 4.2)
//
//  얇은 진입 파일에서 shader_type / render_mode / #define 을 정하고 이걸 include 할 것.
//    water_surface.gdshader  → Realistic
//    water_toon.gdshader     → Toon
// ═══════════════════════════════════════════════════════════════════════════
#ifndef WT_SURFACE_BODY_INC
#define WT_SURFACE_BODY_INC

#include "res://water/inc/wt_core.gdshaderinc"
#include "res://water/inc/wt_noise.gdshaderinc"
#include "res://water/inc/wt_waves.gdshaderinc"
#include "res://water/inc/wt_volume.gdshaderinc"
#ifdef RIPPLE
	#include "res://water/inc/wt_ripple.gdshaderinc"
#endif
#ifdef FLOW
	#include "res://water/inc/wt_flow.gdshaderinc"
#endif
#ifdef DOMAIN_POLAR
	#include "res://water/inc/wt_domain.gdshaderinc"
#endif
#ifdef WAVE_SHOAL
	#include "res://water/inc/wt_shoal.gdshaderinc"
#endif
#ifdef STYLE_TOON
	#include "res://water/inc/wt_light_toon.gdshaderinc"
#endif

// ───────────────────────────────────────── L1 Shape
group_uniforms shape;
uniform float wave_time_scale : hint_range(0.0, 3.0) = 1.0;
#ifdef STYLE_TOON
// 툰은 파를 적게·크게. 잔파를 살리면 밴딩 경계가 지저분해진다.
uniform float wave_amplitude  : hint_range(0.0, 2.0) = 0.9;
#else
uniform float wave_amplitude  : hint_range(0.0, 2.0) = 0.85;
#endif
// xy = 진행방향, z = steepness(합 <= 1), w = 파장(m)
uniform vec4 wave_a = vec4( 1.00,  0.30, 0.24, 34.0);
uniform vec4 wave_b = vec4( 0.60,  1.00, 0.21, 17.0);
uniform vec4 wave_c = vec4(-0.80,  0.50, 0.18,  7.3);
uniform vec4 wave_d = vec4( 0.20, -1.00, 0.14,  3.1);
group_uniforms;

// ───────────────────────────────────────── L2 Detail
group_uniforms detail;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec2  detail_scale = vec2(0.055, 0.023);  // 두 레이어 스케일. 정수배 금지(패턴 겹침)
uniform vec2  detail_dir   = vec2(1.0, 0.35);
uniform float detail_speed : hint_range(0.0, 0.5) = 0.06;
#ifdef STYLE_TOON
// 툰은 미세 굴곡이 방해가 된다. 거의 끈다. (docs 4.2)
uniform float detail_strength : hint_range(0.0, 4.0) = 0.25;
#else
uniform float detail_strength : hint_range(0.0, 4.0) = 1.1;
#endif
uniform float detail_lod   : hint_range(0.0, 6.0) = 1.0;   // 밉 강제 → 원거리 지글거림 억제
uniform float detail_fade_start = 45.0;
uniform float detail_fade_end   = 190.0;
group_uniforms;

// ───────────────────────────────────────── L3 Refraction
#ifdef REFRACTION
group_uniforms refraction;
uniform float refraction_strength  : hint_range(0.0, 3.0) = 0.6;
uniform float refraction_max_depth : hint_range(0.0, 8.0) = 2.5;
group_uniforms;
#endif

// ───────────────────────────────────────── L4 Volume
group_uniforms volume;
#ifdef STYLE_TOON
// 툰: 수심을 3단으로 자른다. 연속 흡수 대신 계단.
// [주의] source_color uniform 은 적은 값을 sRGB 로 보고 리니어로 변환해서 넘긴다.
//   0.12 처럼 적으면 리니어에서 0.014 까지 떨어져 R 채널이 통째로 죽는다.
//   툰 팔레트는 숫자로 보이는 것보다 훨씬 밝게 잡아야 한다.
uniform vec3  toon_shallow : source_color = vec3(0.47, 0.85, 0.88);
uniform vec3  toon_mid     : source_color = vec3(0.35, 0.70, 0.90);
uniform vec3  toon_deep    : source_color = vec3(0.20, 0.46, 0.79);
uniform float toon_band0 : hint_range(0.05, 12.0) = 1.1;   // 얕음 → 중간 경계 (m)
uniform float toon_band1 : hint_range(0.05, 24.0) = 4.0;   // 중간 → 깊음 경계 (m)
uniform float toon_see_through : hint_range(0.0, 1.0) = 0.40;
// 등고선이 자로 그은 듯 곱게 나오는 걸 막는다
uniform float toon_band_warp : hint_range(0.0, 4.0) = 1.1;
uniform float toon_band_noise_scale : hint_range(0.002, 0.5) = 0.035;
uniform float alpha_k : hint_range(0.0, 12.0) = 4.5;
#else
// 실사: RGB 각각 다른 흡수계수(1/m). R 이 커야 깊을수록 청록이 된다.
uniform vec3  absorption = vec3(0.38, 0.065, 0.028);
uniform vec3  scatter_color : source_color = vec3(0.016, 0.145, 0.190);
uniform float scatter_k : hint_range(0.0, 2.0) = 0.13;
uniform float alpha_k   : hint_range(0.0, 12.0) = 1.6;
#endif
uniform float depth_clamp : hint_range(1.0, 60.0) = 26.0;
group_uniforms;

// ───────────────────────────────────────── L5 Surface (툰 전용 — 여기가 주인공)
#ifdef STYLE_TOON
group_uniforms surface;
uniform vec3  toon_crest_color : source_color = vec3(0.80, 0.95, 0.98);
uniform float toon_height_steps : hint_range(1.0, 8.0) = 2.0;
uniform float toon_height_mix   : hint_range(0.0, 1.0) = 0.16;
uniform float toon_height_range : hint_range(0.2, 4.0) = 1.1;
group_uniforms;
#endif

// ───────────────────────────────────────── L0 Domain (극좌표 - 원형 연못/온천)
#ifdef DOMAIN_POLAR
group_uniforms domain;
uniform vec2  polar_center = vec2(0.0);
uniform float polar_radius : hint_range(0.5, 60.0) = 8.0;
uniform float polar_zoom   : hint_range(0.1, 8.0) = 1.0;
uniform float polar_repeat : hint_range(0.1, 8.0) = 1.0;
/// 무늬가 중심에서 바깥으로 흘러나가는 속도. 음수면 빨려들어간다(소용돌이).
uniform float polar_flow   : hint_range(-2.0, 2.0) = 0.22;
/// 극좌표는 0~1 범위라 detail_scale 을 그대로 쓰면 무늬가 안 보인다. 여기서 키운다.
uniform float polar_tile   : hint_range(1.0, 200.0) = 46.0;
/// ★ 색을 1D 램프 텍스처로 뺀다 - 온천 색조를 텍스처 하나로 통째 튜닝할 수 있다.
///   숫자 uniform 을 여러 개 돌리는 것보다 압도적으로 빠르게 원하는 색이 나온다.
uniform sampler2D color_gradient : hint_default_white, repeat_disable;
uniform float gradient_mix : hint_range(0.0, 1.0) = 0.75;
uniform float vignette_size  : hint_range(0.0, 2.0) = 0.82;
uniform float vignette_blend : hint_range(0.01, 1.0) = 0.2;
/// 중심에서 퍼지는 동심 링 (물이 솟는 표현)
uniform float ring_count : hint_range(0.5, 20.0) = 4.0;
uniform float ring_speed : hint_range(0.0, 3.0) = 0.35;
uniform float ring_width : hint_range(0.01, 0.9) = 0.4;
uniform float ring_gain  : hint_range(0.0, 2.0) = 0.35;
group_uniforms;
#endif

// ───────────────────────────────────────── L6 Foam
group_uniforms foam;
uniform sampler2D foam_noise : filter_linear_mipmap, repeat_enable;
uniform vec3  foam_color : source_color = vec3(0.93, 0.965, 0.98);
uniform float foam_noise_scale : hint_range(0.02, 2.0) = 0.42;
uniform float foam_warp        : hint_range(0.0, 4.0) = 0.5;
uniform float foam_edge_distance : hint_range(0.05, 6.0) = 1.6;   // 시선 두께 — 물체 교차 링
uniform float foam_shore_depth   : hint_range(0.05, 6.0) = 0.8;   // 수직 수심 — 물가 파도 띠
uniform float foam_crest_start : hint_range(0.0, 1.0) = 0.35;
uniform float foam_crest_end   : hint_range(0.0, 1.5) = 0.72;
uniform float foam_crest_gain  : hint_range(0.0, 3.0) = 1.25;
group_uniforms;

// ───────────────────────────────────────── 학습용 디버그 뷰
// 원본에는 없다. 레이어별 중간값을 색으로 꺼내 보려고 시각화 이식본에만 추가했다.
//   1 법선(L1+L2)  2 수심(L4)  3 폼 마스크(L6)  4 Fresnel(L7)  5 파고(L1)
group_uniforms debug;
uniform int debug_view : hint_range(0, 5) = 0;
uniform float debug_depth_scale : hint_range(0.5, 20.0) = 8.0;
group_uniforms;

// ---------------------------------------- M2 Stylize (픽셀아트)
#ifdef STYLE_PIXELATE
group_uniforms pixelate;
/// 월드 1미터를 몇 칸으로 자를지. 높을수록 촘촘하다.
uniform float pixel_density : hint_range(0.2, 30.0) = 3.0;
/// 최종 색을 몇 단계로 양자화할지. 팔레트 제한 효과.
uniform float palette_steps : hint_range(2.0, 32.0) = 7.0;
group_uniforms;
#endif

// ───────────────────────────────────────── M2 Stylize (툰 외곽선)
#ifdef STYLE_OUTLINE
#ifndef STYLE_TOON
	#error STYLE_OUTLINE 은 STYLE_TOON 을 전제로 한다 (밴드 경계를 공유하므로)
#endif
group_uniforms outline;
uniform vec3  toon_outline_color : source_color = vec3(0.04, 0.14, 0.30);
uniform float toon_outline_px    : hint_range(0.0, 6.0) = 1.4;
group_uniforms;
#endif

// ───────────────────────────────────────── L7 Light
group_uniforms light;
uniform vec3  fresnel_color : source_color = vec3(0.52, 0.70, 0.86);
uniform float fresnel_f0 : hint_range(0.0, 0.2) = 0.02;
#ifdef STYLE_TOON
uniform float toon_fresnel_edge : hint_range(0.0, 1.0) = 0.42;
#else
uniform float water_roughness : hint_range(0.0, 1.0) = 0.04;
#endif
group_uniforms;

// ───────────────────────────────────────── 화면 / 깊이
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture  : hint_depth_texture,  filter_nearest;

varying vec3  v_world;
varying float v_height;
varying float v_jacobian;
varying float v_ripple;
varying float v_shoal;


#ifdef STYLE_OUTLINE
// docs #18(cartoon-3d-water) 의 기법을 "수심 밴드"에 적용한 것.
// 양자화된 값을 이웃에서 다시 구해 다르면 외곽선 → 포스트프로세스 없이 등고선이 생긴다.
//
// 내장변수(INV_PROJECTION_MATRIX 등)는 커스텀 함수 안에서 쓸 수 없으므로 인자로 받는다.
// 반면 uniform 은 전역이라 함수 안에서 그대로 접근된다.
// (전처리기 매크로로도 되지만, Godot 4.7 은 인자가 둘 이상인 멀티라인 매크로를
//  파싱하지 못하고 이어진 줄을 전역 스코프로 흘려보낸다 — 함수가 안전하다.)
float wt_band_at(vec2 suv, float surface_y, mat4 inv_proj, mat4 inv_view) {
	float raw_d = texture(depth_texture, suv).x;
	vec3  w     = wt_world_from_screen(suv, raw_d, inv_proj, inv_view);
	float dd    = max(surface_y - w.y, 0.0);
	// 색 밴딩과 정확히 같은 경계를 쓴다. 따로 구분된 steps 를 두면
	// 외곽선이 색이 바뀌는 지점과 어긋나 띄서 선과 면이 따로 논다.
	return step(toon_band0, dd) + step(toon_band1, dd);   // 0 / 1 / 2
}
#endif

// ═══════════════════════════════════════════════════════════════════════════
void vertex() {
	// world_vertex_coords 덕분에 VERTEX 는 이미 월드 좌표다.
	// → 물 메시를 여러 장 깔아도 파형이 이어진다 (L0 의 기본값).
	vec2  pos = VERTEX.xz;
	float t   = TIME * wave_time_scale;

	vec3 dPdx   = vec3(1.0, 0.0, 0.0);
	vec3 dPdz   = vec3(0.0, 0.0, 1.0);
	vec3 offset = vec3(0.0);

#ifdef WAVE_GERSTNER
	// amplitude 는 steepness 에 곱해야 변위와 미분이 같이 스케일된다.
	// offset 만 곱하면 법선이 어긋나 빛이 파형과 따로 논다.
	float amp = wave_amplitude;
	float spd = 1.0;
	v_shoal = 0.0;
#ifdef WAVE_SHOAL
	// 해변 쇄파: 파고가 먼저 부풀고(shoaling), 느려지고, 물가에서 부서지며 죽는다.
	// 물가에서 파고를 0 으로 죽이는 게 핵심 - 안 그러면 마루가 해변 위로 올라타
	// 모래 위에 고립된 폼 덩어리를 만든다 (4단계에서 남긴 한계).
	v_shoal = wt_shoal_factor(pos);
	amp *= wt_shoal_amp(v_shoal);
	spd  = wt_shoal_speed(v_shoal);
#endif
	offset += wt_gerstner_ex(vec4(wave_a.xy, wave_a.z * amp, wave_a.w), pos, t, spd, dPdx, dPdz);
	offset += wt_gerstner_ex(vec4(wave_b.xy, wave_b.z * amp, wave_b.w), pos, t, spd, dPdx, dPdz);
  #ifndef WAVE_FEW
	offset += wt_gerstner_ex(vec4(wave_c.xy, wave_c.z * amp, wave_c.w), pos, t, spd, dPdx, dPdz);
	offset += wt_gerstner_ex(vec4(wave_d.xy, wave_d.z * amp, wave_d.w), pos, t, spd, dPdx, dPdz);
  #endif
#endif

	VERTEX += offset;

	v_ripple = 0.0;
#ifdef RIPPLE
	// M1 상호작용 파문. Gerstner 위에 더해진다.
	// pos 는 변위 전 좌표를 쓴다 — Gerstner 가 수평으로도 밀기 때문에
	// 변위 후 좌표로 참조하면 파문이 파도를 따라 떨린다.
	v_ripple = wt_ripple_at(pos);
	VERTEX.y += v_ripple * ripple_height;

	// 높이장의 기울기를 법선에 반영 — 이게 있어야 반짝임이 파문을 따라간다.
	// 변위만 더하고 법선을 내버려두면 물이 움직이긴 하는데 빛이 안 따라온다.
	float re = ripple_field_size * 0.006;
	float gx = (wt_ripple_at(pos + vec2(re, 0.0)) - wt_ripple_at(pos - vec2(re, 0.0))) / (2.0 * re);
	float gz = (wt_ripple_at(pos + vec2(0.0, re)) - wt_ripple_at(pos - vec2(0.0, re))) / (2.0 * re);
	dPdx.y += gx * ripple_height * ripple_normal_gain;
	dPdz.y += gz * ripple_height * ripple_normal_gain;
#endif

	// 해석적 법선 — 유한차분(텍스처 3회 재샘플)이 필요 없다.
	TANGENT  = normalize(dPdx);   // +U = 월드 +X
	BINORMAL = normalize(dPdz);   // +V = 월드 +Z
	NORMAL   = normalize(cross(dPdz, dPdx));

	v_world    = VERTEX;
	v_height   = offset.y;
	v_jacobian = wt_jacobian(dPdx, dPdz);
}

// ═══════════════════════════════════════════════════════════════════════════
void fragment() {
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;   // 수면 아래에서 올려다볼 때
	}

	// ── 거리 LOD ────────────────────────────────────────────────
	// 물은 고주파 노멀 때문에 수평선 근처가 지글지글 끓는다.
	float cam_dist    = length(VERTEX);   // fragment 의 VERTEX 는 뷰 공간 → 원점이 카메라
	float detail_fade = 1.0 - smoothstep(detail_fade_start, detail_fade_end, cam_dist);

	// ── L2 Detail normal ────────────────────────────────────────
	vec2  dir = normalize(detail_dir);
	float dt  = TIME * detail_speed;

	// [L0] 샘플링 도메인. 여기만 바꾸면 같은 표면 렌더링으로 다른 물이 된다.
	vec2  dom = v_world.xz;
	float polar_r = 0.0;
#ifdef DOMAIN_POLAR
	polar_r = length(v_world.xz - polar_center) / max(polar_radius, 0.001);
	vec2 pol = wt_polar(v_world.xz, polar_center, polar_radius, polar_zoom, polar_repeat);
	pol.x -= TIME * polar_flow;   // 중심에서 바깥으로 흘러나감
	dom = pol * polar_tile;
#endif
#ifdef STYLE_PIXELATE
	// 샘플링 좌표 자체를 격자에 스냅한다. 화면이 아니라 '월드' 격자라서
	// 카메라가 움직여도 물 표면의 도트가 헤엄치지 않는다 - 이게 핵심이다.
	dom = wt_snap(dom, pixel_density);
#endif

	vec3 n0;
	vec3 n1;
	vec2 flow = vec2(0.0);
#ifdef FLOW
	// [흐름] 스크롤과 흐름은 다르다. 스크롤은 텍스처를 한 방향으로 미는 것이고,
	// 흐름은 위치마다 방향이 다르다 - 강물이 바위를 타고 도는 건 스크롤로는 안 된다.
	flow = wt_flow_vector(v_world.xz);
	float ft = TIME * flow_speed;
	n0 = wt_flow_sample(normal_map, dom * detail_scale.x, flow, ft,        flow_warp);
	n1 = wt_flow_sample(normal_map, dom * detail_scale.y, flow, ft * 0.83, flow_warp);
#else
	n0 = textureLod(normal_map, dom * detail_scale.x + dir    * dt,        detail_lod).xyz;
	n1 = textureLod(normal_map, dom * detail_scale.y - dir.yx * dt * 0.83, detail_lod).xyz;
#endif
	NORMAL_MAP       = mix(n0, n1, 0.5);
	NORMAL_MAP_DEPTH = detail_strength * detail_fade;

	// NORMAL_MAP 은 fragment() 가 끝난 뒤에 적용되므로, 굴절/Fresnel 에 쓸
	// 교란된 법선은 직접 만들어야 한다. (뷰 공간)
	vec3 nm = NORMAL_MAP * 2.0 - 1.0;
	vec3 pert_n = normalize(
		  TANGENT  * nm.x * NORMAL_MAP_DEPTH
		+ BINORMAL * nm.y * NORMAL_MAP_DEPTH
		+ NORMAL   * nm.z);

	// ── 깊이: 두 종류를 분리해서 구한다 ─────────────────────────
	//   시선 두께  → 폼 (눈에 보이는 교차선)
	//   수직 수심  → 색/흡수 (물리적으로 맞는 값)
	float raw       = texture(depth_texture, SCREEN_UV).x;
	float scene_d   = wt_linear_depth(SCREEN_UV, raw, INV_PROJECTION_MATRIX);
	float water_d   = -VERTEX.z;
	float thickness = max(scene_d - water_d, 0.0);

	vec3  scene_w  = wt_world_from_screen(SCREEN_UV, raw, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	float vertical = max(v_world.y - scene_w.y, 0.0);

	// ── L3 Refraction ───────────────────────────────────────────
	vec2 ruv = SCREEN_UV;
#ifdef REFRACTION
	// / water_d 로 나누는 게 핵심. 안 나누면 멀리 있는 물이 미친듯이 일렁인다.
	vec2 test_uv = SCREEN_UV
		+ pert_n.xy * refraction_strength
		* min(thickness, refraction_max_depth) / max(water_d, 1.0);

	float rraw     = texture(depth_texture, test_uv).x;
	float rscene_d = wt_linear_depth(test_uv, rraw, INV_PROJECTION_MATRIX);

	// 오프셋된 지점이 물보다 앞이면 물 앞의 물체를 빨아들인다 → 원래 UV 로 폴백.
	// 이 방어가 없으면 물가에 선 캐릭터가 물속에 비쳐 보이는 버그가 난다.
	if (rscene_d >= water_d && wt_in_screen(test_uv)) {
		ruv      = test_uv;
		vertical = max(v_world.y - wt_world_from_screen(
			test_uv, rraw, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX).y, 0.0);
	}
#endif
	vec3 behind = texture(screen_texture, ruv).rgb;

	// ── L4 Volume ───────────────────────────────────────────────
	float d = min(vertical, depth_clamp);
	vec3  col;
#ifdef STYLE_TOON
	// 계단: 수심 3단. fwidth 로 밴드 경계를 정확히 1픽셀 폭으로 만든다.
	// ★ 밴딩은 "잔잔할 때의 수심"으로 계산한다.
	//   v_world.y 에는 파고(±1.4m)가 섞여 있는데 이건 밴드 폭(1.1m)과 맞먹는다.
	//   그대로 쓰면 밴드 경계가 파도를 따라 요동쳤서, 지도 등고선이 아니라
	//   정체불명의 얼룩 덩어리가 된다. 파고 성분을 빼면 경계가 해저에 고정된다.
	//   파고는 아래 L5 에서 따로 밴딩한다 — 두 밴딩을 섞지 않는 게 요점.
	// 해저 경사가 균일하면 등수심선은 완벽한 직선이 된다 — 물이 아니라 줄자로 보인다.
	// 경계 자체를 저주파 노이즈로 밀어 유기적인 윤곩으로 만든다.
	// (모든 이웃 샘플에 동일한 값이 더해지므로 외곽선 검출은 그대로 유효하다)
	float band_warp = (wt_value_noise(v_world.xz * toon_band_noise_scale
					 + vec2(TIME * 0.02, 0.0)) - 0.5) * toon_band_warp;
	float still_y = v_world.y - v_height + band_warp;
	float d_still = min(max(still_y - scene_w.y, 0.0), depth_clamp);
	float aa = fwidth(d_still) * 0.6;
	col = wt_volume_banded(toon_shallow, toon_mid, toon_deep, d_still, toon_band0, toon_band1, aa);
	// 가장 얕은 밴드에서만 바닥이 살짝 비치게. 완전 불투명하면 물이 판때기로 보인다.
	float shallow_mask = 1.0 - wt_aa_step(toon_band0, d_still);
	col = mix(col, mix(col, behind, toon_see_through), shallow_mask);
#else
	// 연속: RGB 분리 Beer-Lambert 흡수 + 산란
	col = wt_volume_color(behind, absorption, scatter_color, scatter_k, d);
#endif

	// ── L5 Surface ──────────────────────────────────────────────
#ifdef STYLE_TOON
	// 툰에서는 여기가 주인공. 파고를 계단으로 잘라 마루를 밝힌다.
	float hn = clamp(wt_remap(v_height, -toon_height_range, toon_height_range, 0.0, 1.0), 0.0, 1.0);
	col = mix(col, toon_crest_color, wt_posterize(hn, toon_height_steps) * toon_height_mix);
#endif

	// ── L6 Foam ─────────────────────────────────────────────────
	float foam = 0.0;
	// 절차적 노이즈로 UV 를 흔들어 "스크롤하는 텍스처" 티를 지운다
	vec2 fuv = wt_warp(dom, 0.06, foam_warp, TIME * 0.06) * foam_noise_scale
			 + dir * TIME * detail_speed * 1.7;
	float fn;
#ifdef FLOW
	// 노멀과 같은 flow 로 폼도 워프해야 물결과 거품이 같은 물살을 탄다.
	fn = wt_flow_sample_r(foam_noise,
			wt_warp(dom, 0.06, foam_warp, TIME * 0.06) * foam_noise_scale,
			flow, TIME * flow_speed * 1.3, flow_warp * 2.0);
#else
	fn = texture(foam_noise, fuv).r;
#endif

#ifdef DOMAIN_POLAR
	// 색을 1D 램프로 통과시킨다 (#8 hotspring 의 핵심 패턴).
	// 램프 인덱스는 "위치마다 변하는 값"이어야 한다. NORMAL_MAP.z 는 거의 항상
	// 1 에 붙어 있어서 램프의 한쪽 끝만 뽑아 쓰게 된다 - 물이 통짜 흰색이 된다.
	// 극좌표에서 샘플한 노이즈(fn)가 코스틱처럼 번져서 인덱스로 딱 맞다.
	float vign = wt_vignette(polar_r, vignette_size, vignette_blend);
	vec3  ramp = texture(color_gradient, vec2(clamp(fn, 0.0, 1.0), 0.5)).rgb;
	col = mix(col, ramp, gradient_mix * vign);
	// 중심에서 퍼지는 동심 링 - 물이 솟아오르는 표현
	col += wt_rings(polar_r, ring_count, ring_speed, TIME, ring_width) * ring_gain * vign;
#endif

  #ifdef FOAM_EDGE
	// ★ 두 깊이를 둘 다 쓴다 (docs 2장 L4).
	//   시선 두께: 기둥·바위 주변에 딱 붙는 얇은 링. 얕은 각도에서는 급히 커져
	//              물가 띠를 못 만든다 (시선이 얕은 물을 길게 통과하므로).
	//   수직 수심: 해변 경사를 따라 넓게 퍼지는 파도 띠. 각도와 무관.
	float shore_ray  = 1.0 - clamp(thickness / foam_edge_distance, 0.0, 1.0);
	float shore_vert = 1.0 - clamp(vertical  / foam_shore_depth,   0.0, 1.0);
	float shore = max(shore_ray, shore_vert);

	// Roystan 식: 얕을수록 cutoff 가 낮아져 노이즈가 더 많이 살아남는다.
	// 하한을 0 이 아니라 0.22 로 둔다. 0 이면 물가가 통짜 흰색으로 뭉개진다.
	// 상한은 1.0 + wt_edge 반폭(0.11) 보다 커야 한다. 1.05 로 두면
	// 깊은 물(shore=0)에서도 smoothstep(0.94,1.16,fn) 이 노이즈 고점에서
	// ~0.2 를 토해서 수면 전체에 흰 반점이 깔린다.
	float cutoff = mix(1.25, 0.22, shore);
	foam = max(foam, wt_edge(cutoff, fn));
  #endif

  #ifdef FOAM_CREST
	// 야코비안이 작아질수록 파형이 접히는 중 = 파도가 부서지는 지점
	float crest = 1.0 - smoothstep(foam_crest_start, foam_crest_end, v_jacobian);
	foam = max(foam, wt_edge(0.55, crest * fn * foam_crest_gain));
  #endif

  #ifdef RIPPLE
	// 파문 마루에 흰 테두리. 동일한 폼 노이즈를 섞어 동그란 링 티를 지운다.
	foam = max(foam, wt_edge(0.55, abs(v_ripple) * ripple_foam * (fn * 0.6 + 0.7)));
  #endif

  #ifdef WAVE_SHOAL
	// 부서지는 구간에서 거품이 폭증한다
	foam = max(foam, wt_edge(0.5,
			smoothstep(shoal_break - 0.25, 1.0, v_shoal) * shoal_foam * fn));
  #endif

  #ifdef FLOW
	// 급류 거품은 "빠르고 + 얕은" 곳에서 난다.
	// 유속만 보면 강 전체가 하얘진다 - 균일한 흐름에서는 length(flow) 가
	// 어디서나 같기 때문이다. 수심을 곱해야 바위 주변·여울목만 하얘진다.
	float rapid = length(flow) * (1.0 - clamp(vertical / flow_foam_depth, 0.0, 1.0));
	foam = max(foam, wt_edge(0.62, rapid * flow_foam * fn));
  #endif

	foam = clamp(foam, 0.0, 1.0);
	col  = mix(col, foam_color, foam);

	// ── L7 Fresnel ──────────────────────────────────────────────
	float fres = 0.0;   // [학습용] 디버그 뷰에서 쓰려고 #ifdef 밖으로 꺼냈다
#ifdef FRESNEL
	fres = wt_fresnel(pert_n, VIEW, fresnel_f0);
  #ifdef STYLE_TOON
	fres = wt_aa_step(toon_fresnel_edge, fres);   // 하드 림
  #endif
	col = mix(col, fresnel_color, fres * (1.0 - foam));
#endif

	// ── M2 Outline ──────────────────────────────────────────────
	float ol = 0.0;
#ifdef STYLE_OUTLINE
	vec2  opx = toon_outline_px / VIEWPORT_SIZE;
	float b0  = wt_band_at(SCREEN_UV, still_y, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	ol = max(ol, abs(wt_band_at(SCREEN_UV + vec2(opx.x, 0.0), still_y, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX) - b0));
	ol = max(ol, abs(wt_band_at(SCREEN_UV - vec2(opx.x, 0.0), still_y, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX) - b0));
	ol = max(ol, abs(wt_band_at(SCREEN_UV + vec2(0.0, opx.y), still_y, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX) - b0));
	ol = max(ol, abs(wt_band_at(SCREEN_UV - vec2(0.0, opx.y), still_y, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX) - b0));
	ol  = clamp(ol, 0.0, 1.0) * (1.0 - foam);
	col = mix(col, toon_outline_color, ol);
#endif

#ifdef STYLE_PIXELATE
	col = floor(col * palette_steps) / palette_steps;   // 팔레트 제한
#endif

	ALBEDO = col;
	ALPHA  = clamp(max(max(wt_depth_alpha(vertical, alpha_k), foam), ol), 0.0, 1.0);
#ifdef STYLE_TOON
	// ROUGHNESS 1 / SPECULAR 0 으로 환경 IBL 반사를 죽인다.
	// 하이라이트는 아래 light() 가 SPECULAR_LIGHT 에 직접 얹으므로 영향받지 않는다.
	ROUGHNESS = 1.0;
	SPECULAR  = 0.0;
#else
	ROUGHNESS = mix(water_roughness, 0.85, foam);
	SPECULAR  = 0.5;
#endif
	METALLIC = 0.0;

	// [학습용] 레이어별 중간값 보기 — 원본에는 없는 분기다.
	// Godot는 fragment()에서 return을 막으므로 조기 반환 대신 끝에서 덮어쓴다.
	if (debug_view > 0) {
		vec3 dbg = vec3(0.0);
		if (debug_view == 1) {
			// 법선의 y는 거의 항상 1이라 그대로 그리면 온통 연녹색이다.
			// 기울기(xz)를 3배 과장해야 파도 경사가 눈에 보인다.
			dbg = normalize(vec3(pert_n.x * 3.0, pert_n.y, pert_n.z * 3.0)) * 0.5 + 0.5;
		} else if (debug_view == 2) {
			dbg = vec3(clamp(vertical / debug_depth_scale, 0.0, 1.0));
		} else if (debug_view == 3) {
			dbg = vec3(foam);
		} else if (debug_view == 4) {
			dbg = vec3(fres);
		} else if (debug_view == 5) {
			dbg = vec3(clamp(v_height * 0.5 + 0.5, 0.0, 1.0));
		}
		ALBEDO    = vec3(0.0);
		EMISSION  = dbg;
		ALPHA     = 1.0;
		ROUGHNESS = 1.0;
		SPECULAR  = 0.0;
		METALLIC  = 0.0;
	}
}

#endif
