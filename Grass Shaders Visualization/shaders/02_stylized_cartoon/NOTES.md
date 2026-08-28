# 02 - Stylized Cartoon Grass

| | |
|---|---|
| 원본 | https://godotshaders.com/shader/stylized-cartoon-grass/ |
| 저자 | dip |
| 라이선스 | MIT |
| 원본 엔진 | Godot 4.x |
| 4.7 상태 | **그대로 컴파일됨** |

## 핵심 아이디어

조명이 전혀 없다(`unshaded`). 잎의 색은 위에서 내려다본 **월드 공간 컬러맵 두 장**
(잔디용, 지면용)에서 뽑아 세로 그라디언트 마스크로 섞는데, 이걸 전부 **정점 셰이더**
에서 한다. 픽셀당이 아니라 정점당 비용이라 열 개 중 가장 싸다. 잎 텍스처는 실루엣(알파)
과 외곽선(red 채널)만 제공한다.

## 4.7 변환 내역

수학은 한 줄도 건드리지 않았다. `variants` 배열에 `filter_linear_mipmap, repeat_disable`
힌트만 추가했다.

## 이 프로젝트에서 측정된 것

두 가지 모두 원본 그대로의 특성이고, 알고 쓰면 문제가 없다.

1. **모든 잎이 같은 위상으로 흔들린다.** 흔들림이 `NODE_POSITION_WORLD` 기반인데,
   이건 노드 단위 값이다. MultiMesh 하나에 3천 개를 넣으면 3천 개가 전부 같은 값을 읽는다.
   1.5초 동안 화면의 42%가 변할 만큼 크게 움직이지만, 움직임이 **한 덩어리로** 움직인다.
   → 09번 셰이더가 똑같은 제약을 갖고 있고, 그쪽은 아예 개별 MeshInstance3D로 뿌려서 해결한다.
2. **알파 시저 0.8 + 밉맵이면 25m 밖에서 패치가 통째로 사라진다.**
   잎 실루엣이 텍스처 폭의 6~15%뿐이라, 상위 밉에서 알파가 그 비율로 평균화되어
   0.8 밑으로 떨어지고 전부 discard된다. 이 프로젝트에서 제일 오래 헤맨 문제이고,
   밉맵만 끄고 같은 앵글로 다시 찍어서 원인을 확정했다 (42m에서 완전 소멸 → 정상).
   그래서 `blade_detail_*.png.import` 는 `mipmaps/generate=false` 로 배포한다.
   03번은 같은 잎을 쓰면서도 디더 방식이라 이 함정에 안 걸린다.
   실전 대안: 디더, alpha-to-coverage, 커버리지 보정 밉, 거리별 LOD 메시.

## 필요한 입력

- 월드 컬러맵 2장 (`grass_color_02.png`, `terrain_color_02.png`)
- 세로 그라디언트 마스크 (`gradient_mask_02.png`) - UV.y=0(잎 끝)이 흰색이어야 한다
- 잎 변형 4장 (`blade_detail_0..3.png`) - **red = 몸통, 0 = 외곽선, alpha = 실루엣**
- `variant_index` 는 `instance uniform` 이라 **노드 단위**다. 변형 4종을 쓰려면
  MultiMeshInstance3D 4개가 필요하다 (`GrassPlot.variant_count = 4` 가 이걸 한다).
