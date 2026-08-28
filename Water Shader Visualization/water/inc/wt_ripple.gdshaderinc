// ═══════════════════════════════════════════════════════════════════
//  wt_ripple.gdshaderinc — M1 상호작용 파문 (소비자 쪽)
//
//  캐릭터 발자국 / 보트 항적 / 물대포 착탄 / 낙석을 하나의 시스템으로 처리한다.
//  docs/water-shader-analysis.md 5.7 참조.
//
//  ★ 이 파일은 "높이맵 텍스처 1장" 이라는 인터페이스만 안다.
//    그 텍스처를 누가 만드는지는 상관하지 않는다:
//      레벨 1  global uniform 1점        (가장 쌈, 오브젝트 1~2개)
//      레벨 2  SubViewport 마스크         ← scripts/water_ripple_field.gd
//      레벨 3  파동방정식 ping-pong       (진짜로 퍼지고 반사됨)
//    프로젝트 규모에 따라 생산자만 갈아끼우면 되고 셰이더는 손대지 않는다.
//
//  인코딩: R = 위로 솟은 양, G = 아래로 꺼진 양. 검정(0,0) = 평평.
//    부호를 두 채널로 나눈 덕에 (a) 가산 블렌딩으로 파문이 겹쳐 더해지고,
//    (b) hint_default_black 이라 텍스처를 안 물려도 그냥 no-op 이 된다.
//    0.5 를 중립으로 쓰는 흔한 방식은 이 두 성질을 다 잃는다.
//
//  requires: wt_core.gdshaderinc
// ═══════════════════════════════════════════════════════════════════
#ifndef WT_RIPPLE_INC
#define WT_RIPPLE_INC

group_uniforms ripple;
uniform sampler2D ripple_tex : hint_default_black, filter_linear, repeat_disable;
uniform vec2  ripple_center = vec2(0.0);      // 필드 중심 (월드 XZ) — 스크립트가 매 프레임 갱신
uniform float ripple_field_size = 48.0;       // 필드 한 변 (m)
uniform float ripple_height      : hint_range(0.0, 2.0) = 0.30;
uniform float ripple_normal_gain : hint_range(0.0, 8.0) = 2.5;
uniform float ripple_foam        : hint_range(0.0, 3.0) = 1.0;
group_uniforms;

// 월드 XZ → 마스크 UV
vec2 wt_ripple_uv(vec2 world_xz) {
	return (world_xz - ripple_center) / max(ripple_field_size, 0.001) + 0.5;
}

// 부호 있는 파문 높이. 필드 밖은 0.
// 가장자리를 페이드하지 않으면 필드 경계가 직선으로 드러난다.
float wt_ripple_at(vec2 world_xz) {
	vec2 uv = wt_ripple_uv(world_xz);
	if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
		return 0.0;
	}
	// vertex() 에서도 불리므로 textureLod 로 명시 (정점 단계엔 미분이 없다)
	vec4 s = textureLod(ripple_tex, uv, 0.0);
	vec2 fade = smoothstep(vec2(0.0), vec2(0.05), uv)
			  * (1.0 - smoothstep(vec2(0.95), vec2(1.0), uv));
	return (s.r - s.g) * fade.x * fade.y;
}

#endif
