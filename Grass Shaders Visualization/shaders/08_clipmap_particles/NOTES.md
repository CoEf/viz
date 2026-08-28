# 08 - Wandering Clipmap - Foliage Particle Process

| | |
|---|---|
| 원본 | https://godotshaders.com/shader/wandering-clipmap-foliage-particle-process/ |
| 저자 | ZestfulFibre (devmar 기법 기반) |
| 라이선스 | CC0 |
| 원본 엔진 | Godot 4.1 |
| 4.7 상태 | **render_mode 위치 수정** |

## 핵심 아이디어

**이건 그리는 셰이더가 아니다.** `shader_type particles` 인 파티클 **프로세스** 셰이더로,
잎을 어디에 놓을지만 결정한다. GPUParticles3D의 `process_material` 에 ShaderMaterial로
붙이고, draw pass에 잔디 메시를 넣고, 그리기는 07번 셰이더가 한다.

devmar의 "wandering clipmap" 기법: 파티클을 `INDEX` 기반 고정 그리드로 깔고,
그리드 원점을 `mod()`로 이미터 위치에 스냅한다. 이미터가 카메라를 따라다녀도
그리드가 셀 단위로만 미끄러지므로 **잎들은 제자리에 붙어 있는 것처럼 보인다.**
높이는 하이트맵, 밀도는 마스크, 방향은 지형 노멀에서 나온다. **잎당 CPU 작업이 0이다.**

밀도 테스트에서 탈락한 잎은 죽이지 않고 `y = -10000` 으로 보낸다. 파티클 개수를
일정하게 유지하기 위해서다.

## 4.7 변환 내역

`render_mode disable_velocity, disable_force;` 가 원본에서는 uniform 블록 **뒤에**
선언되어 있다. Godot 4의 파서는 `shader_type` 바로 다음 위치에서만 `render_mode`를
받으므로 그대로는 파싱에 실패한다. 맨 위로 옮겼다.

## 이 프로젝트에서 추가한 것

- `mat_clipmap_draw.tres` - 07번 셰이더의 **별도 인스턴스**. 07번 패치가 매 프레임
  자기 `fadeout_envelope` 를 갱신하기 때문에, `.tres` 를 공유하면 이 패치의 페이드가
  옆 패치의 카메라 거리를 따라가버린다.
- 지면은 07번과 같은 `heightmap_terrain.gd` 로 만든다.

## 주의사항

- **`amount` 와 `instance_rows`² 가 일치해야 한다.** 여기서는 72² = 5184.
  안 맞으면 마지막 줄이 빠지거나 겹친다.
- `explosiveness = 1.0`, `lifetime = 600` - 모든 파티클을 한 프레임에 방출한다.
  이건 "파티클로 만든 정적 들판"이지 이미터가 아니다.
- `visibility_aabb` 를 직접 지정해야 한다. 안 그러면 카메라가 중심을 벗어나는 순간
  통째로 컬링된다.
- `foliage_map` 의 방향에 주의: 코드가 `if (density * density_adjust > r.x) 숨김` 이라
  **값이 높은 곳이 맨땅**이다. `gen_assets.gd` 도 그 방향으로 생성한다.

## 이 프로젝트에서 측정된 것

- 5184개 배치에 CPU 작업 0.
- **바람**: 1.5초 동안 화면의 27% (07번 셰이더가 그린 결과).
- 배치 자체는 절대 변하지 않는다. `INDEX`에서 결정론적으로 나오기 때문이다.
