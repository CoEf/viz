// ═══════════════════════════════════════════════════════════════════════════
//  water_curtain.gdshader — 폭포 / 커튼 프리셋
//  docs/water-shader-analysis.md 5.3
//
//  본문은 wt_curtain_body.gdshaderinc. 이 파일은 어느 모듈을 켤지만 정한다.
//  세로로 분할된 QuadMesh/PlaneMesh 에 붙여 쓴다 (sway 가 정점을 흔들므로).
// ═══════════════════════════════════════════════════════════════════════════

shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_never, diffuse_burley, specular_schlick_ggx;

#define SOFT_EDGE       // 바닥/바위와 만나는 곳을 부드럽게
//#define STYLE_TOON

#include "res://water/inc/wt_curtain_body.gdshaderinc"
