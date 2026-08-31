# viz — 시각화 워크스루 웹 빌드

Godot 프로젝트를 챕터 단위로 뜯어 보는 워크스루들과, 그것을 웹으로 내보내
GitHub Pages에 올리는 파이프라인.

배포처: <https://CoEf.github.io/viz/>

## 목록은 폴더가 정한다

여기에 표를 두지 않는다. 예전에는 `build_web.py`의 `PROJECTS`와 이 표와
블로그의 `walkthroughs.ts` 셋을 손으로 맞췄는데, 어긋나도 양쪽 빌드는 멀쩡히
통과하고 카드만 404가 되므로 아무도 몰랐다.

지금은 `discover()`가 폴더를 훑는다. 셋을 다 갖춘 폴더가 곧 워크스루다.

```
<프로젝트>/project.godot
<프로젝트>/addons/pipeline_viz/
<프로젝트>/chapters/chapter_*.tscn
```

CI는 체크아웃 위에서 도니까 "커밋된 것"과 "폴더에 있는 것"이 같다. **`git add`가
곧 발행 제스처다** — 아직 안 내놓을 것은 커밋하지 않으면 되고, draft 플래그 같은
것을 따로 둘 필요가 없다.

### slug

배포 주소(`…/viz/<slug>/`)이자 블로그 본문 `::godot{src="…"}`가 무는 값이다.
폴더 이름에서 `Visualization`을 떼고 소문자·하이픈으로 만든다.

```
Fireball Visualization              → fireball
Marching Squares Terrain Visualization → marching-squares-terrain
```

**한 번 나가면 바꾸지 않는다** — 바꾸면 이미 나간 글의 임베드가 404가 된다.
그래서 규칙이 생기기 전에 손으로 정한 다섯은 `LEGACY_SLUGS`에 못 박혀 있다
(`snow` · `water` · `ripple` · `grass` · `rooms`). 두 폴더가 같은 slug로 가면
빌드가 멈춘다.

### 손으로 적는 것

`build_web.py`의 `LABELS`뿐이다 — 제목, `/viz/` 목차의 한 줄, 블로그 카드의 한 줄.
폴더에서 유도할 수 없는 산문이라 남긴다.

**안 적어도 목록에서 빠지지 않는다.** 폴더 이름이 제목이 되고 나머지는 빈다.
빠지게 만들면 '적어야 할 것'이 생기고, 그 순간부터 다시 밀리기 시작한다.

## 대표 화면과 블로그 목록

둘 다 폴더에서 나온다. 로컬에서 돌리고 산출물을 커밋한다 — 블로그 CI는 다른
저장소라 이 폴더를 볼 수 없다.

```bash
python tools/shoot_covers.py --godot <godot>   # public/images/viz/<slug>.webp
python tools/gen_walkthroughs.py               # src/utils/walkthroughs.ts
python tools/gen_walkthroughs.py --check       # 어긋나 있으면 1로 끝난다
```

`shoot_covers.py`는 새 하네스를 만들지 않고 러너의 `-- --autotour`를 쓴다.
그림을 만드는 코드가 하나뿐이라, 러너 UI가 바뀌면 썸네일도 저절로 따라간다.
고르는 자리는 **가운데 챕터의 마지막 스텝**이다 — 첫 챕터는 무대만 있어 아무것도
안 쌓였고, 마지막은 결과만 남아 과정이 안 보인다. 손으로 골랐던 기존 여섯 장이
전부 그 자리였다.

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

모든 빌드의 wasm은 바이트가 같다. 같은 엔진, 같은 익스포트 설정이라 프로젝트
데이터만 pck로 갈라지기 때문이다. 그래서 이렇게 조립한다.

```
viz/
  _engine/godot.wasm     37.7 MB   ← 전부가 공유. 브라우저가 캐시한다
  _engine/godot.js
  snow/snow.pck           0.6 MB   ← 프로젝트별로는 이것만 다르다
  snow/index.html                  ← executable=../_engine/godot, mainPack=snow.pck
  water/water.pck         0.8 MB
  …                                 엔진 37.7 + pck 101.1 = 138.8 MB (스무 개 기준)
```

프로젝트마다 통째로 내보내면 엔진만 스무 벌이라 850 MB를 넘는다. 방문자
입장에서도 두 번째 워크스루부터는 엔진이 캐시에 남아 pck만 받는다.

**pck 크기는 고르지 않다.** 열여덟 개는 5 MB 아래고 대부분 1~3 MB인데,
`jiggle`이 30.9 MB, `drawable-painter`가 44.5 MB다. 둘 다 원본 메시와 텍스처를
그대로 들고 있어서 그렇다 — 첫 로딩이 다른 것들과 체감이 다르다.

`drawable-painter`가 로컬에서 재면 26.5 MB로 나오는데 CI에서는 44.5 MB다.
차이는 glb에서 뽑혀 나오는 텍스처 18 MB다 — 저장소에는 없고(gitignore),
깨끗한 체크아웃에서 Godot이 첫 임포트에 만들어 pck에 넣는다.

### 캐시는 배포까지만 간다

GitHub Pages는 `Cache-Control: max-age=600`에 `ETag`를 붙여 보낸다. 10분이
지나면 브라우저가 재검증하는데, **Pages는 배포할 때마다 모든 파일에 배포
시각을 새로 찍는다.** 내용이 그대로여도 ETag가 갈리므로, 배포 직후 돌아온
방문자는 엔진 10.2 MB(gzip)를 한 번 다시 받는다.

빌드 쪽에서 파일 mtime을 내용에서 뽑아 고정해 봤지만 소용없었다 — Pages가
아티팩트의 mtime을 아예 무시하고 자기 시각으로 덮는다. 엔진 파일의
Last-Modified가 초 단위까지 전부 같은 것으로 확인했다.

정리하면 이렇다. 배포와 배포 사이에는 재검증이 304(본문 0바이트)로 끝나고,
배포하면 한 번 다시 받는다. 그래도 엔진을 프로젝트 수만큼 두는 것보다는 낫다 —
그쪽은 프로젝트를 옮길 때마다 매번 10.2 MB다.

`build_web.py`는 조립 전에 모든 wasm의 해시가 같은지 확인하고, 갈리면 멈춘다.
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
