# 09 - Pixel Art Wind Sway

| | |
|---|---|
| 원본 | https://godotshaders.com/shader/pixel-art-wind-sway-meshinstance3d-godot-4-0/ |
| 저자 | Darfine |
| 라이선스 | CC0 |
| 원본 엔진 | Godot 4.0 |
| 4.7 상태 | **그대로 컴파일됨** |

## 핵심 아이디어

열 개 중 가장 싸다. 사인 두 개, 노이즈 없음, uniform 없음, 텍스처는 스프라이트 하나.

흥미로운 부분은 `NODE_POSITION_WORLD` 다. 이게 이웃한 잔디 뭉치들의 위상을 어긋나게
만드는 유일한 장치인데, **노드 단위 값**이다. MultiMesh에 올리면 들판 전체가
하나의 덩어리처럼 흔들린다 (02번이 정확히 그 상태다).

그래서 이 프로젝트의 09번 패치는 **MultiMesh가 아니라 개별 MeshInstance3D 300개**다.
`scripts/pixel_tuft_field.gd` 가 그 제약을 감추지 않고 드러내기 위해 존재한다.
이웃 패치들이 3~4천 장인데 여기가 300장인 이유가 그것이다.

## 4.7 변환 내역

수학은 그대로. `ALPHA_SCISSOR_THRESHOLD` 를 uniform으로 노출해 추가했다
(원본 댓글의 schuster 제안). 0으로 두면 원본 동작이고, 0.5면 픽셀 가장자리가
흐려지지 않고 단단하게 남는다.

## 이 프로젝트에서 측정된 것

- **바람**: 1.5초 동안 화면의 39%. **잎 하나당 움직임은 열 개 중 최고**이고,
  잎 개수는 열 개 중 최저다.
- 상호작용 없음.

## 필요한 입력

- 픽셀 아트 잔디 스프라이트 (`pixel_tuft.png`, 32x32) - `filter_nearest` 필수.
  임포트에서 밉맵 끄기, `detect_3d/compress_to=0` 로 VRAM 압축 방지.
- 밑동이 원점인 쿼드 (`card_pixel.tres`)
