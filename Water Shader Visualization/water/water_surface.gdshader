// ═══════════════════════════════════════════════════════════════════════════
//  water_surface.gdshader — Realistic 프리셋
//
//  본문은 wt_surface_body.gdshaderinc 가 갖고 있다. 이 파일은 "어느 모듈을 켤지"만
//  정한다. Toon 변형(water_toon.gdshader)은 똑같은 본문을 include 하고
//  #define STYLE_TOON 하나만 더 켠다.
//
//  레이어 스택 (docs/water-shader-analysis.md 2장)
//    L0 Domain      world XZ  (render_mode world_vertex_coords)
//    L1 Shape       Gerstner 4파 + 해석적 법선
//    L2 Detail      노멀맵 2장 스크롤 + 거리 LOD 페이드
//    L3 Refraction  스크린 텍스처 오프셋 (거리 보정 + 앞물체 폴백)
//    L4 Volume      RGB 분리 Beer-Lambert 흡수 + 산란
//    L6 Foam        엣지(교차) + 크레스트(야코비안)
//    L7 Light       Fresnel + PBR
//
//  알려진 한계: 파고는 수심과 무관하게 일정하다. 경사가 완만한 해변에서는
//  큰 파도의 마루가 물가 위로 올라타 모래 위에 고립된 폼 덩어리를 만든다.
//  올바른 해법은 수심맵으로 steepness/속도를 변조하는 것 —
//  docs/water-shader-analysis.md 5.2 "해변 쇄파" 참조.
// ═══════════════════════════════════════════════════════════════════════════

shader_type spatial;
render_mode cull_disabled, world_vertex_coords, diffuse_burley, specular_schlick_ggx;

// ═══ 모듈 스위치 (컴파일 타임 분기 — 끈 기능은 명령어가 아예 안 들어간다) ═══
#define WAVE_GERSTNER
#define REFRACTION
#define FRESNEL
#define FOAM_EDGE
#define FOAM_CREST
#define WAVE_SHOAL      // 수심맵이 없으면 어디서나 깊은 물 -> no-op
#define RIPPLE          // 파문 필드가 없으면 기본 검은 텍스처 → 무해한 no-op

#include "res://water/inc/wt_surface_body.gdshaderinc"
