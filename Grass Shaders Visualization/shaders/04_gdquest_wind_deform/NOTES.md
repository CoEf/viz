# 04 - Stylized grass with wind and deformation

| | |
|---|---|
| 원본 | https://godotshaders.com/shader/stylized-grass-with-wind-and-deformation/ |
| 저자 | GDQuest |
| 라이선스 | MIT |
| 원본 엔진 | Godot 3.2 |
| 4.7 상태 | **컴파일 불가 → 수정** |

## 핵심 아이디어

젤다 BotW 식 잔디. 타일링 노이즈를 바람 방향으로 스크롤해 휘게 하고, 캐릭터 위치
하나가 커브 텍스처를 통해 잎을 밀어낸다.

핵심은 두 변위를 모두 **정점 공간(vertex space)으로 변환한 뒤** 적용한다는 점이다.
`inverse(MODEL_MATRIX)`를 곱하는 그 줄이 없으면, 무작위로 회전된 잎들이 각자 다른
방향으로 휘어서 바람이 아니라 노이즈처럼 보인다.

원본 제약을 그대로 유지했다: **밀어내는 대상은 1개뿐이다.** 여러 개를 지원하려면
위치들을 작은 텍스처에 인코딩해야 한다 (원본 설명에도 그렇게 적혀 있다).

## 4.7 변환 내역

| 원본 (3.2) | 4.7 | 이유 |
|---|---|---|
| `hint_black_albedo` | `source_color, hint_default_black` | 4.x에 해당 힌트 없음 |
| `hint_black` | `hint_default_black` | 이름 변경 |
| `WORLD_MATRIX` (4곳) | `MODEL_MATRIX` | 이름 변경 |
| 커브 텍스처 힌트 | **`repeat_disable` 추가** | 아래 참고 |

`hint_black_albedo` 는 원본 댓글의 "Not working for 4.2" 가 가리키는 바로 그 줄이다.

`repeat_disable` 는 코드만 봐서는 절대 알 수 없는 함정이다. Godot 4는 커브 텍스처를
기본 repeat로 임포트하기 때문에, `falloff`가 0 밑으로 가는 순간 UV가 wrap 되어
**반경 밖의 먼 잔디가 캐릭터에 반응한다.** 원본 댓글의 Benight가 몇 시간을 태우고
찾아낸 내용이다.

## 이 프로젝트에서 측정된 것

- **바람**: 1.5초 동안 화면의 34%.
- **밀림**: 공을 넣고 뺐을 때 화면의 9%. 넓고 부드러운 원형인데, falloff가 반경만
  보고 커브를 샘플링하기 때문이다. 원본 주석도 "노이즈로 원형을 깨는 건 독자 과제"
  라고 적어뒀다.
- 원본의 `normalize(bump_wind);` 는 반환값을 버리는 무의미한 줄이다(정규화가 안 된다).
  지우면 결과가 같고 `bump_wind = normalize(bump_wind)` 로 고치면 룩이 달라지므로,
  **원본 그대로 뒀다.**

## 필요한 입력

- 색 램프 (`color_ramp_04.png`) - `vec2(1.0 - UV.y, 0)` 로 샘플링하므로 **오른쪽 끝이 잎 끝 색**
- 이음매 없는 바람 노이즈 (`wind_noise.png`)
- 밀림 falloff 커브 (`falloff_curve_04.png`) - **반드시 repeat_disable**
- `character_position` 은 일반 uniform이라 머티리얼에 쓴다
  (`GrassPlot.player_material_uniform` 이 매 프레임 갱신).
