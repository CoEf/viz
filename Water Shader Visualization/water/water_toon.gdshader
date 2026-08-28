// ═══════════════════════════════════════════════════════════════════════════
//  water_toon.gdshader — Toon 프리셋
//
//  water_surface.gdshader 와 **완전히 같은 본문**을 쓴다. 다른 건 이 파일의
//  #define 목록뿐이다. Realistic 과 Toon 은 다른 셰이더가 아니라
//  같은 레이어 스택을 다른 연산자로 채운 것이라는 게 이 구조의 요지.
//  (docs/water-shader-analysis.md 4.2 레이어별 Toon 치환표)
//
//  STYLE_TOON 이 켜지면 본문에서 이렇게 바뀐다:
//    L2 Detail    노멀맵 강도 1.1 → 0.25   (미세 굴곡이 밴딩을 방해)
//    L3 Refraction 꺼짐                     (툰 물은 왜곡하지 않는다)
//    L4 Volume    exp() 연속 흡수 → 수심 3단 밴딩
//    L5 Surface   (신규) 파고를 계단으로 잘라 마루를 밝힘 — 툰의 주인공
//    L6 Foam      smoothstep → aa_step 흰 단색
//    L7 Fresnel   연속 → 하드 림
//    L7 Light     PBR → 커스텀 light() 셀 램프 + 덩어리 하이라이트
//    M2           수심 밴드 외곽선 (포스트프로세스 없이)
//
//  ambient_light_disabled: 툰은 빛을 100% 통제해야 한다. 앰비언트가 섞이면
//  밴드 경계가 물러진다. 그늘 밝기는 toon_shadow_color 가 대신 책임진다.
// ═══════════════════════════════════════════════════════════════════════════

shader_type spatial;
render_mode cull_disabled, world_vertex_coords, ambient_light_disabled;

// ═══ 모듈 스위치 ═══
#define WAVE_GERSTNER
//#define WAVE_FEW        // 켜면 Gerstner 2파만 사용 (더 단순한 파형)
//#define REFRACTION      // 툰은 끈다 (docs 4.2)
#define FRESNEL
#define FOAM_EDGE
#define FOAM_CREST
#define RIPPLE          // 파문 필드가 없으면 기본 검은 텍스처 → 무해한 no-op
#define STYLE_TOON
#define STYLE_OUTLINE

#include "res://water/inc/wt_surface_body.gdshaderinc"
