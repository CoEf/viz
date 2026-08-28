# 01 - Grass with Screen-Space Displacement

| | |
|---|---|
| 원본 | https://godotshaders.com/shader/grass-with-screen-space-displacement/ |
| 저자 | Toadile |
| 라이선스 | MIT |
| 원본 엔진 | Godot 3.4 / 3.5 |
| 4.7 상태 | **컴파일 불가 → 전면 수정** |

## 핵심 아이디어

이 셰이더만 **상호작용 데이터를 전혀 받지 않는다.** 프래그먼트 단계에서 깊이 버퍼를
읽어, 잔디 카드 바로 앞에 불투명한 물체가 있으면 알베도 UV를 옆/아래로 밀어버린다.
정점을 건드리지 않고 텍스처 공간에서만 휘는 것이라, 밀어내는 물체가 1개든 100개든
비용이 같다. 대신 카드 폭이 2배여야 한다 - 밀려난 잎이 자기 쿼드 밖으로 나가면
잘리기 때문이다. (`assets/card_wide.tres` 가 그래서 2x1 이다.)

## 4.7 변환 내역

| 원본 (3.x) | 4.7 | 이유 |
|---|---|---|
| `WORLD_MATRIX` | `MODEL_MATRIX` | 이름 변경 |
| `INV_CAMERA_MATRIX` | `VIEW_MATRIX` | 이름 변경 |
| `CAMERA_MATRIX` | `INV_VIEW_MATRIX` | 이름 변경 |
| `hint_color`, `hint_albedo` | `source_color` | 4.0에서 힌트 체계 개편 |
| `TRANSMISSION = vec3(x)` | `BACKLIGHT = vec3(x)` | 4.0에서 TRANSMISSION 제거 |
| `NORMALMAP` | `NORMAL_MAP` | 이름 변경 |
| 파일 중간의 두 번째 `render_mode` | 맨 위 한 줄로 병합 | 4.x는 render_mode 선언을 1회만 허용 |
| `pow(x, 2)` | `pow(x, 2.0)` | int 리터럴 암시 변환 없음 |
| `1.0f` / `0.5f` | `1.0` / `0.5` | Godot 셰이딩 언어에 `f` 접미사 없음 |
| `discard; return;` | `discard;` | 원본 댓글에서도 지적된 잉여 `return` |
| (없음) | `uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;` | **4.7에서 DEPTH_TEXTURE 내장이 제거됨.** 이게 없으면 셰이더 전체가 컴파일 실패한다 |

마지막 항목이 이 셰이더에서 제일 중요하다. 4.7이 뱉는 에러는 친절한 편이다:
`DEPTH_TEXTURE has been removed in favor of using hint_depth_texture with a uniform.`

## 이 프로젝트에서 측정된 것

- **바람**: 1.5초 동안 화면의 **4%**만 변한다. 열 개 중 가장 약하다. 주된 흔들림 항이
  `sin(TIME * 0.01 * h_stiff + INSTANCE_ID)` 인데 `h_stiff ≈ 0.22` 라서 주기가 약 47분이다.
  실제로 움직이는 건 노이즈 스크롤뿐이므로, `wind_speed`를 올려야 살아난다
  (이 씬은 4.0을 쓴다. 원본 기본값은 1.0).
- **상호작용**: 밀어내는 공을 넣고 뺐을 때 화면의 **0.6%**가 바뀐다. 전부 공 주변의
  좁은 영역이다 - 스크린 공간 기법이므로 당연하고, 의도대로 동작한다.
- 원본 코드의 `(noise_tex.r - 0.5*2.0)` 은 연산자 우선순위 실수로 보인다
  (`- 1.0`이 되어 항상 음수). 결과가 달라지므로 **고치지 않고 그대로 뒀다.**

## 필요한 입력

- 알파가 있는 잎 알베도 (`card_albedo.png`), 노멀맵 (`card_normal.png`)
- 타일링 노이즈 (`wind_noise.png`)
- **폭이 2배인 카드 메시** (`card_wide.tres`)
- 씬에 불투명 물체가 있어야 밀림이 보인다 (Walker 공)
