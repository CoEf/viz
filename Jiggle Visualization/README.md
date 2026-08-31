# Jiggle Visualization

[Jiggle 프로젝트](C:\Users\Public\Code\_Collection\Jiggle)(Godot 4.7 흔들림 물리 학습 교보재)를
챕터 단위로 분해하는 인터랙티브 워크스루. `pipeline_viz` 애드온으로 만들었다.

## 실행

```
Godot_v4.7 --path "C:\Users\Public\Code\Visualization\Jiggle Visualization"
```

검증(전 스텝 스크린샷):

```
Godot_v4.7 --path . --resolution 1600x900 -- --autotour <출력 폴더>
```

## 챕터 구성

| # | 챕터 | 월드 | 핵심 |
|---|---|---|---|
| 0 | 완성본 구경하기 | Rig4World | 실제 캐릭터 + 시스템 지도 |
| 1 | 스프링-댐퍼 | SpringWorld | a = k(target−x) − cv, ζ, 적분, 중력 |
| 2 | 본 하나 흔들기 | BoneWorld | 파티클→본 회전, 구면 투영, 각도 제한, 비등방, 스쿼시 |
| 3 | 본 사슬 | ChainWorld | Verlet, 거리 제약, 각도 제한, 충돌 3단계, 본 재구성 |
| 4 | 천 | ClothWorld | 구조·전단·굽힘, 법선 바람, 매 프레임 메쉬 굽기 |
| 5 | 본 없이 셰이더로 | ShaderWorld | COLOR.a 가중치, 유니폼/시간 구동, 마커 |
| 6 | 실전 배선 | Rig4World | 모디파이어 37개, JiggleChainSettings, JiggleCollider3D, 실측 |

## 폴더

```
addons/pipeline_viz/    애드온 (sync.ps1 로 설치 — 직접 고치면 DRIFT 로 잡힌다)
chapters/               챕터 스크립트 + 씬 (chapter_N_*.tscn 파일명 순 정렬)
  jiggle_chapter.gd     프로젝트 챕터 베이스 (버튼·옵션·그래프 패널 헬퍼)
  worlds/               챕터별 월드. jiggle_stage.gd 가 공통 무대(바닥·카메라·자극·서브스텝)
jiggle/                 ★ 원본 그대로 이식한 솔버 (수정 금지에 준함 — 원본과 diff 가능해야 한다)
common/                 원본 이식: proc_skin · stimulus · jiggle_debug_draw · jiggle_plot
demos/                  원본 이식: 리그 빌더(jiggle_body · hair_rig · cloth_mannequin)
  09_real_character/rig4_scene.gd   이식 + 개작(무대·HUD 제거). 캐릭터 씬의 루트 스크립트
assets/adachi_rigged4/  실제 캐릭터(glb, 본 183개) + 모디파이어 39개가 든 씬 + 설정 .tres
```

원본 프로젝트는 손대지 않았다. `jiggle/`·`common/`·`demos/`·`assets/` 는 res:// 경로를
원본과 같게 유지해서 `adachi_rigged4_jiggle.tscn` 의 참조가 그대로 풀린다.

## 힌트 장치

- **코드 칸 용어 툴팁** — 코드에 뜨는 엔진 이름(Quaternion · add_bone ·
  set_bone_pose_rotation · rotated · add_surface_from_arrays …)은 마우스를 올리면
  설명이 뜬다. 사전은 `addons/pipeline_viz/ui/glossary.gd` — 고치면 반드시
  `sync.ps1 -Promote` 로 마스터에 올릴 것(전 프로젝트 공유).
- **슬로우모션 토글 (0.15×)** — 전 챕터 패널에 있다. 원본 문서의 조언 그대로,
  오버슈트가 한 동작씩 보인다. `Engine.time_scale` 을 만지므로 챕터 전환 시
  `JiggleChapter.reset_globals()` 가 1.0으로 되돌린다.
- **기즈모 색 범례 캡션** — 챕터 1~5 패널 하단. 스텝 본문이 색을 다 못 실을 때의 보조선.

## 이 프로젝트에서 배운 함정

- **자극 위상 kick 은 회전 자극에는 쓰지 말 것.** `stimulus.step(0.5)` 로 위상을 당기면
  한 프레임짜리 순간이동이 되어 사슬이 수평으로 튄다(TWIST 는 주기가 짧아 그냥 둬도 된다).
- **설정 .tres 는 챕터에서 복제해 쓴다** (`Rig4World._localize_settings`). 리소스는 로더가
  캐시하므로 슬라이더로 고친 값이 챕터를 나가도 남는다 — resource_local_to_scene 함정의
  리소스판.
- **SkeletonModifier3D 기반 월드는 수동 프리워밍이 안 된다.** 모디파이어는 스켈레톤이
  프레임을 처리할 때만 돈다. 캡처 대책은 자극 위상 당기기(+임펄스)뿐이다.
