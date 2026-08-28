// ═══════════════════════════════════════════════════════════════════════════
//  water_jet.gdshader — 물줄기 / 분수 프리셋
//  docs/water-shader-analysis.md 5.6
//
//  water_curtain.gdshader 와 완전히 같은 본문을 쓴다. 차이는 #define JET 뿐 —
//  굵기 감쇠 + 끝단 dissolve + 나선 하이라이트가 켜진다.
//
//  ⚠ 셰이더 하나로 물대포가 완성되지는 않는다. 4개 파트의 합이다:
//     ① 물줄기(이 셰이더)  ② 끝단 분산(dissolve, 이 셰이더)
//     ③ 스프레이(GPUParticles3D)  ④ 착탄 파문(WaterRippleField)
//    ④ 를 빼면 아무리 잘 만들어도 "흰 리본"으로 보인다.
// ═══════════════════════════════════════════════════════════════════════════

shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_never, diffuse_burley, specular_schlick_ggx;

#define JET
#define SOFT_EDGE
//#define STYLE_TOON

#include "res://water/inc/wt_curtain_body.gdshaderinc"
