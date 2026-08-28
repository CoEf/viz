// ═══════════════════════════════════════════════════════════════════════════
//  water_river.gdshader — 강 / 해류 프리셋
//  docs/water-shader-analysis.md 5.4
//
//  water_surface.gdshader 와 같은 본문. 차이는 FLOW 계열 #define 뿐이다.
//    FLOW        위치마다 방향이 다른 흐름 (flow map 크로스페이드)
//    FLOW_NOISE  저주파 노이즈로 방향을 휘게 → 텍스처 없이 사행(蛇行)
//    FLOW_MAP    직접 그린 flow map 을 쓸 때 켠다 (지형 경사에서 생성해도 됨)
//
//  RIPPLE 은 껐다 — 강은 정점당 텍스처 샘플이 이미 많다. 필요하면 켜면 된다.
// ═══════════════════════════════════════════════════════════════════════════

shader_type spatial;
render_mode cull_disabled, world_vertex_coords, diffuse_burley, specular_schlick_ggx;

#define WAVE_GERSTNER
#define REFRACTION
#define FRESNEL
#define FOAM_EDGE
#define FLOW
#define FLOW_NOISE
//#define FLOW_MAP
//#define STYLE_TOON

#include "res://water/inc/wt_surface_body.gdshaderinc"
