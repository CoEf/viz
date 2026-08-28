// ═══════════════════════════════════════════════════════════════════════════
//  water_pixel.gdshader — 픽셀아트 물 프리셋
//  docs/water-shader-analysis.md 4.4 (픽셀아트 스타일)
//
//  툰 경로 위에 M2(픽셀화)를 얹은 것. 역시 같은 본문이다.
//    · 샘플링 좌표를 월드 격자에 스냅 → 노멀·폼이 통째로 계단이 된다
//    · 최종 색을 팔레트 단계로 양자화
//
//  ⚠ 셰이더가 할 수 있는 건 여기까지다. "화면 전체가 도트"인 룩은
//    프로젝트 레벨에서 저해상도 SubViewport 에 렌더하고 정수배 확대해야 나온다.
//    (Project Settings > Display > Window > Stretch, 또는 SubViewport + nearest)
//    셰이더만으로 화면 픽셀 격자에 맞추려 하면 카메라가 움직일 때 도트가 헤엄친다.
// ═══════════════════════════════════════════════════════════════════════════

shader_type spatial;
render_mode cull_disabled, world_vertex_coords, ambient_light_disabled;

#define WAVE_GERSTNER
#define FRESNEL
#define FOAM_EDGE
#define FOAM_CREST
#define RIPPLE
#define STYLE_TOON
#define STYLE_PIXELATE

#include "res://water/inc/wt_surface_body.gdshaderinc"
