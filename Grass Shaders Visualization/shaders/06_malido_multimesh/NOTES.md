# 06 - Stylized Multimesh Grass Shader

| | |
|---|---|
| 원본 | https://godotshaders.com/shader/stylized-multimesh-grass-shader/ |
| 저자 | Malido |
| 라이선스 | CC0 |
| 원본 엔진 | Godot 4.x |
| 4.7 상태 | **리터럴 1건 수정** |

## 핵심 아이디어

열 개 중 가장 "실전용"이다. 툰 디퓨즈 + Schlick GGX 스페큘러, 노멀 강제 상향,
잎 밑동에 구워 넣은 가짜 AO, 그리고 **3차원 플레이어 밀림**.

밀림이 3D라는 게 핵심이다. `player_height` 항이 세로 방향으로 밀림을 감쇠시켜서,
플레이어가 잔디 위를 **점프해서 지나가면 잔디가 눕지 않는다.** 나머지 상호작용
셰이더들은 전부 XZ 거리만 본다.

## 4.7 변환 내역

`vec3(1 , -0.3 ,1)` → `vec3(1.0, -0.3, 1.0)`.
Godot 4 셰이딩 언어는 int → float 암시 변환을 하지 않아서 컴파일 에러가 난다.

## 이 프로젝트에서 측정된 것

- **바람**: 1.5초 동안 화면의 41%.
- **밀림**: 공을 넣고 뺐을 때 화면의 **16%** - 열 개 중 가장 크다.
- 원본 경고 그대로: **`wind_direction` 이 (0,0,0)이 되면 잔디가 통째로 사라진다.**
  영벡터의 `normalize()`가 NaN이기 때문이다. 인스펙터에서 실수로 초기화하기 쉬우니 주의.

## 필요한 입력

- Perlin FBM 이음매 없는 노이즈 (`wind_noise.png`)
- 밑동이 원점에 있는 잎 메시 (`blade_mesh.res`)
- `player_position` 은 **`instance uniform`** 이다. 머티리얼이 아니라 노드에
  `set_instance_shader_parameter()` 로 넣어야 한다
  (`GrassPlot.player_instance_uniform` 이 처리). 덕분에 머티리얼 하나를 여러 패치가
  공유하면서 각자 다른 대상에 반응할 수 있다.
