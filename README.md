# viz — 시각화 워크스루 웹 빌드

Godot 프로젝트를 챕터 단위로 뜯어 보는 워크스루 다섯 개와, 그것을 웹으로
내보내 GitHub Pages에 올리는 파이프라인.

배포처: <https://CoEf.github.io/viz/>

| slug | 프로젝트 | 내용 |
|---|---|---|
| `snow` | Snow Pipeline Visualization | 무대 → 눈발 → 쌓임 → 발자국 → 반짝임, 일곱 챕터 |
| `water` | Comunity Water Shaders Visualization | godotshaders.com에서 모은 물 셰이더 열아홉 개 비교 |
| `grass` | Grass Shaders Visualization | 지오메트리 · 바람 · 눌림 · 알파, 여섯 챕터 |
| `rooms` | Rooms Connector Visualization | 들로네 삼각분할과 최소 신장 트리로 방 잇기 |
| `ripple` | Water Shader Visualization | 형태 → 디테일 → 표면 → 부피 → 거품, 일곱 챕터 |

slug는 배포 주소(`…/viz/<slug>/`)이자 블로그 본문 `::godot{src="…"}`가 무는
값이다. 한 번 정하면 바꾸지 않는다 — 바꾸면 이미 나간 글의 임베드가 404가 된다.

## 빌드하지 않은 것을 커밋한다

이 저장소는 **소스만** 담는다. 웹 빌드는 커밋하지 않는다.

엔진 wasm이 39 MB인데, 챕터 한 줄을 고칠 때마다 그게 커밋되면 히스토리가
그만큼 영구히 무거워진다. 그래서 `push` 하면 Actions가 Godot을 받아
내보내고 Pages로 바로 올린다. 커밋되는 것은 프로젝트 소스(합계 8 MB 남짓)뿐이다.

곁가지로 얻는 것이 하나 더 있다. **"에디터에서는 되는데 내보내면 깨지는"
버그가 push마다 걸린다.** 실제로 셋을 이렇게 잡았다.

| 증상 | 원인 |
|---|---|
| 빌드에서만 챕터가 0개 | `.tscn`이 `.scn`으로 구워지고 폴더에는 `.tscn.remap`만 남는다 |
| 웹에서만 한글이 두부 | 원본 `.ttf`가 pck에 안 들어간다(`.import` + `fontdata`만). 시스템 폰트 폴백은 웹에 폰트가 없어 실패 |
| 웹에서만 물 셰이더 하나가 검게 | `fma()`는 Forward+ 전용, Compatibility(WebGL2)에서 컴파일 실패 |

셋 다 데스크톱에서는 멀쩡했다. 내보내야만 드러난다.

## 엔진은 한 벌만 둔다

다섯 빌드의 wasm은 바이트가 같다. 같은 엔진, 같은 익스포트 설정이라 프로젝트
데이터만 pck로 갈라지기 때문이다. 그래서 이렇게 조립한다.

```
viz/
  _engine/godot.wasm     37.7 MB   ← 다섯이 공유. 브라우저가 캐시한다
  _engine/godot.js
  snow/snow.pck           0.6 MB   ← 프로젝트별로는 이것만 다르다
  snow/index.html                  ← executable=../_engine/godot, mainPack=snow.pck
  water/water.pck         0.8 MB
  …                                 합계 41.8 MB
```

프로젝트마다 통째로 내보내면 200 MB가 된다. 방문자 입장에서도 두 번째
워크스루부터는 엔진이 캐시에 남아 pck 1 MB 안쪽만 받는다.

`build_web.py`는 조립 전에 다섯 wasm의 해시가 같은지 확인하고, 갈리면 멈춘다.
그 전제가 깨진 채로 조립하면 네 프로젝트가 엉뚱한 엔진으로 돌아간다.

## 로컬에서 빌드

CI와 같은 명령을 쓴다.

```bash
python tools/build_web.py --godot "<godot 실행파일>" --out _out/viz
```

한 프로젝트만 보려면 `--only snow`. 결과를 확인하려면 정적 서버로 띄운다 —
`file://`로는 wasm이 로드되지 않는다.

```bash
python -m http.server 8972 --directory _out
```

## 웹으로 갈 때 달라지는 것

- **렌더러**: Forward+ → Compatibility(WebGL2). Vulkan이 없어서 자동으로 내려간다.
  `depth_texture` · `screen_texture`는 그대로 동작하지만 SSAO는 조용히 무시된다.
- **스레드**: `thread_support=false`로 내보낸다. 그래야 `SharedArrayBuffer` 없이
  돌아가고, **COOP/COEP 헤더를 못 주는 GitHub Pages에서 그대로 뜬다.**
  켜면 헤더가 필요해지고 Pages에서는 방법이 없다.
- **시스템 폰트**: 웹에는 설치된 폰트가 하나도 없다. `SystemFont` 폴백은
  전부 빗나가므로 폰트를 반드시 번들해야 한다.

## 블로그에서 쓰기

블로그(`CoEf/CoEf.github.io`)가 `::godot` 디렉티브로 문다.

```markdown
::godot[눈 파이프라인 워크스루]{src="snow" poster="/images/viz/snow-cover.png"}
```

같은 `CoEf.github.io` 오리진이라 iframe 제약이 없다. 참조 위치는
블로그 쪽 `remark-godot.mjs`의 `vizBase` 한 곳에서만 정한다.
