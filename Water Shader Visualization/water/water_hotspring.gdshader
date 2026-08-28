// ═══════════════════════════════════════════════════════════════════════════
//  water_hotspring.gdshader — 온천 / 원형 연못 프리셋
//  docs/water-shader-analysis.md 5.5
//
//  water_surface.gdshader 와 같은 본문. 차이는 L0(좌표계)를 극좌표로 바꾼 것뿐이다.
//  L0 만 갈아끼웠는데 물이 중심에서 솟아 퍼지는 완전히 다른 물이 된다 —
//  "레이어 하나만 바꾸면 다른 상황이 된다" 는 이 문서 2장 주장의 가장 선명한 예다.
//
//  온천다움은 셰이더 파라미터 쪽:
//    · 유백색   absorption 크게 + scatter_color 밝게 → 50cm 만 되어도 바닥이 안 보임
//    · 색조     color_gradient 램프 텍스처 하나로 통째 튜닝
//    · 솟는 물  중심에서 퍼지는 동심 링
//    · 증기     셰이더가 아니라 GPUParticles3D (씬 쪽)
// ═══════════════════════════════════════════════════════════════════════════

shader_type spatial;
render_mode cull_disabled, world_vertex_coords, diffuse_burley, specular_schlick_ggx;

#define WAVE_GERSTNER
#define DOMAIN_POLAR
#define REFRACTION
#define FRESNEL
#define FOAM_EDGE
#define RIPPLE
//#define STYLE_TOON

#include "res://water/inc/wt_surface_body.gdshaderinc"
