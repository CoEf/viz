#!/usr/bin/env python3
"""시각화 프로젝트들을 웹으로 내보내고, 배포할 수 있는 한 덩어리로 묶는다.

    python tools/build_web.py --godot <godot 실행파일> --out _out/viz

로컬에서 쓰는 명령과 CI가 쓰는 명령이 같다. 워크플로가 따로 조립 단계를
갖고 있으면, 로컬에서 되던 게 CI에서만 깨지는 자리가 하나 더 생긴다.

── 왜 엔진을 따로 빼는가 ────────────────────────────────────────────
프로젝트마다 통째로 내보내면 39 MB짜리 wasm이 프로젝트 수만큼 나온다.
그런데 모든 빌드의 wasm은 바이트가 같다 — 같은 엔진, 같은 익스포트 설정이라
프로젝트 데이터만 pck로 갈라지기 때문이다. 그래서 엔진은 `_engine/`에 한 벌만
두고, 프로젝트 폴더에는 pck와 셸만 남긴다. 41 MB로 끝나고, 방문자 입장에서도
두 번째 워크스루부터는 엔진이 브라우저 캐시에 남아 pck만 받는다.

셸의 GODOT_CONFIG에서 `executable`이 wasm·오디오 워크릿의 위치를,
`mainPack`이 pck의 위치를 정한다. 그 둘을 갈라 놓는 것이 이 조립의 전부다.

'해시가 같다'는 전제가 깨지면 잘못된 엔진으로 돌아가는 빌드가 조용히 나가므로,
아래에서 확인하고 다르면 멈춘다.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# ── 목록은 폴더가 정한다 ─────────────────────────────────────────────
# 예전에는 여기에 딕셔너리를 손으로 적었다. 그러면 등록부가 셋이 된다 —
# 폴더, 이 딕셔너리, 그리고 블로그의 walkthroughs.ts. 셋이 어긋나도 빌드는
# 멀쩡히 통과하고 카드만 404가 되므로 아무도 모른다. 그래서 폴더를 유일한
# 진실로 삼고 나머지를 여기서 만든다.
#
# CI는 체크아웃 위에서 돌기 때문에 "커밋된 것"과 "폴더에 있는 것"이 같다.
# 즉 `git add`가 곧 발행 제스처다 — 아직 안 내놓을 것은 커밋을 안 하면 되고,
# draft 플래그 같은 것을 따로 둘 필요가 없다.

# slug는 배포 주소가 된다(…/viz/<slug>/). 블로그 본문의 ::godot{src="…"}가
# 이 값을 그대로 쓰므로, 한 번 나간 뒤에는 바꾸지 않는다 — 바꾸면 이미 나간
# 글의 임베드가 조용히 404가 된다.
#
# 아래 다섯은 규칙이 생기기 전에 손으로 정한 것이라 규칙에 맞출 수 없다.
# ('Waterfall Visualization'은 규칙대로 해도 'waterfall'이라 여기 없다.)
LEGACY_SLUGS = {
    "Snow Pipeline Visualization": "snow",
    "Comunity Water Shaders Visualization": "water",
    "Water Shader Visualization": "ripple",
    "Grass Shaders Visualization": "grass",
    "Rooms Connector Visualization": "rooms",
}

# slug → 손으로 적는 산문. 폴더에서 유도할 수 없는 것은 이 셋뿐이다.
#
#   title    · 카드와 목차에 뜨는 이름
#   note     · /viz/ 목차 카드의 한 줄 (짧게, 화살표로 줄기만)
#   summary  · 블로그 워크스루 카드의 한 줄 (문장으로)
#
# note와 summary가 갈리는 이유는 읽는 자리가 다르기 때문이다 — /viz/ 목차는
# 이미 들어온 사람이 고르는 자리라 줄기만 보면 되고, 블로그 카드는 처음 보는
# 사람이 들어갈지 정하는 자리라 문장이 필요하다.
#
# **안 적어도 목록에서 빠지지 않는다** — 폴더 이름이 제목이 되고 나머지는 빈다.
# 빠지게 만들면 '적어야 할 것'이 생기고, 그 순간부터 다시 밀리기 시작한다.
LABELS = {
    "snow": {
        "title": "눈 파이프라인",
        "note": "무대 → 눈발 → 쌓임 → 발자국 → 반짝임까지 일곱 챕터",
        "summary": "무대에 눈을 내리고, 쌓고, 발자국을 남기고, 반짝이게 하기까지를 한 겹씩 켠다.",
    },
    "waterfall": {
        "title": "폭포",
        "note": "UV 스크롤 → 두 겹 곱 → 그라데이션 → 변위 → 파티클까지 여덟 챕터",
        "summary": "UV 스크롤 두 겹을 곱해 물줄기를 만들고, 변위와 웅덩이와 파티클을 얹는다.",
    },
    "water": {
        "title": "물 셰이더 열아홉 개",
        "note": "godotshaders.com에서 모은 물 셰이더를 한 무대에 올려 비교",
        "summary": "godotshaders.com에서 모은 물 셰이더를 한 무대에 올려, 파도·법선·깊이·굴절·거품을 축마다 비교한다.",
    },
    "ripple": {
        "title": "물결 시뮬레이션",
        "note": "형태 → 디테일 → 표면 → 부피 → 거품까지 일곱 챕터",
        "summary": "형태에서 시작해 디테일·표면·부피·거품 순으로 물 한 덩이를 쌓아 올린다.",
    },
    "grass": {
        "title": "잔디 셰이더 열 개",
        "note": "지오메트리 · 바람 · 눌림 · 알파까지 여섯 챕터",
        "summary": "블레이드 지오메트리부터 바람, 밟힘, 알파 처리까지 잔디밭을 이루는 결정들.",
    },
    "rooms": {
        "title": "방 잇기",
        "note": "들로네 삼각분할과 최소 신장 트리로 방을 연결",
        "summary": "흩뿌린 방을 들로네 삼각분할로 잇고 최소 신장 트리로 추려, 던전 한 층의 연결을 만든다.",
    },
}


def slugify(folder: str) -> str:
    """폴더 이름에서 배포 주소를 만든다. 'Fireball Visualization' → 'fireball'."""
    name = re.sub(r"\s+Visualization$", "", folder)
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def discover() -> dict:
    """워크스루 프로젝트를 찾아 slug → (폴더, 제목, 한 줄)로 만든다.

    셋을 다 갖춘 폴더만 센다: project.godot · addons/pipeline_viz · chapters.
    러너가 없거나 챕터가 없으면 내보내 봐야 빈 화면이라, 목록에 있으면 안 된다.
    """
    found: dict = {}
    origin: dict = {}
    for path in sorted(p for p in ROOT.iterdir() if p.is_dir()):
        if not (path / "project.godot").exists():
            continue
        if not (path / "addons" / "pipeline_viz").is_dir():
            continue
        if not any(path.glob("chapters/chapter_*.tscn")):
            continue
        slug = LEGACY_SLUGS.get(path.name) or slugify(path.name)
        # 두 폴더가 같은 주소로 가면 하나가 조용히 덮인다. 이름을 바꾸라고 멈춘다.
        if slug in found:
            raise SystemExit(
                f"[build_web] slug 충돌: '{slug}' ← {origin[slug]} · {path.name}"
            )
        label = LABELS.get(slug, {})
        title = label.get("title") or path.name
        note = label.get("note", "")
        found[slug] = (path.name, title, note)
        origin[slug] = path.name
    if not found:
        raise SystemExit("[build_web] 워크스루 프로젝트를 하나도 못 찾았다")
    return found


PROJECTS = discover()

PRESET = "Web"

# 엔진에서 프로젝트와 무관한 파일들. 이 이름으로 `_engine/`에 한 벌만 남는다.
ENGINE_FILES = {
    "index.js": "godot.js",
    "index.wasm": "godot.wasm",
    "index.audio.worklet.js": "godot.audio.worklet.js",
    "index.audio.position.worklet.js": "godot.audio.position.worklet.js",
}

# 프로젝트 아이콘·스플래시. 수십 KB라 각자 들고 가는 편이 단순하다.
PROJECT_FILES = ("index.png", "index.icon.png", "index.apple-touch-icon.png")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def export(godot: str, project: Path, out: Path) -> None:
    """프로젝트 하나를 웹으로 내보낸다.

    Godot은 출력 폴더를 만들어 주지 않는다 — 없으면 조용히 아무것도 안 쓰고
    성공한 것처럼 끝난다. 그래서 여기서 먼저 만든다.

    임포트 패스는 따로 돌리지 않는다. 4.7의 --export-release는 캐시가 없는
    체크아웃에서도 first_scan_filesystem과 reimport를 먼저 수행한다.
    """
    out.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [godot, "--headless", "--path", str(project),
         "--export-release", PRESET, str(out / "index.html")],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    # Godot은 셰이더 컴파일 실패 같은 것을 stdout에 흘리면서도 종료 코드를
    # 0으로 남기는 경우가 있다. 배포되는 물건이므로 로그도 같이 본다.
    log = (result.stdout or "") + (result.stderr or "")
    clean = re.sub(r"\x1b\[[0-9;]*m", "", log)
    bad = [line for line in clean.splitlines()
           if line.startswith("ERROR") or "SHADER ERROR" in line]
    if result.returncode != 0 or bad:
        sys.stderr.write(clean)
        raise SystemExit(
            f"[build_web] {project.name}: 내보내기 실패 "
            f"(exit={result.returncode}, 오류 {len(bad)}줄)"
        )
    if not (out / "index.wasm").exists():
        raise SystemExit(f"[build_web] {project.name}: wasm이 나오지 않았다")


def shell_html(source: Path, slug: str, pck_size: int, wasm_size: int) -> str:
    """익스포트된 셸을 공유 엔진을 가리키도록 고쳐 쓴다."""
    html = source.read_text(encoding="utf-8")

    html = html.replace('<script src="index.js"></script>',
                        '<script src="../_engine/godot.js"></script>')

    match = re.search(r"const GODOT_CONFIG = (\{.*?\});", html)
    if match is None:
        raise SystemExit(f"[build_web] {slug}: 셸에서 GODOT_CONFIG를 못 찾았다")

    config = json.loads(match.group(1))
    config["executable"] = "../_engine/godot"   # → godot.wasm, godot.audio.*.worklet.js
    config["mainPack"] = f"{slug}.pck"          # → 프로젝트 데이터만 여기서
    # 로딩 막대가 쓰는 값이다. 경로를 바꿨으니 키도 같이 바꿔야 맞는다.
    config["fileSizes"] = {f"{slug}.pck": pck_size, "../_engine/godot.wasm": wasm_size}

    return re.sub(r"const GODOT_CONFIG = \{.*?\};",
                  "const GODOT_CONFIG = " + json.dumps(config) + ";", html)


def landing(out: Path) -> None:
    """…/viz/ 로 곧장 들어온 사람을 위한 목차. 블로그는 각 슬러그를 직접 문다."""
    cards = "\n".join(
        f"""      <li>
        <a href="{slug}/">
          <strong>{title}</strong>
          <span>{note}</span>
        </a>
      </li>"""
        for slug, (_, title, note) in PROJECTS.items()
    )
    (out / "index.html").write_text(
        f"""<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>시각화 워크스루</title>
<style>
  :root {{ color-scheme: dark; }}
  body {{ margin: 0; padding: 48px 24px; background: #101318; color: #e8ebf2;
         font: 16px/1.6 system-ui, "Segoe UI", sans-serif; }}
  main {{ max-width: 640px; margin: 0 auto; }}
  h1 {{ font-size: 20px; margin: 0 0 6px; }}
  p.lead {{ margin: 0 0 28px; color: #9aa3b2; font-size: 14px; }}
  ul {{ list-style: none; margin: 0; padding: 0; display: grid; gap: 10px; }}
  a {{ display: block; padding: 14px 16px; border: 1px solid #262d38;
       border-radius: 10px; background: #1b1f27; color: inherit;
       text-decoration: none; }}
  a:hover {{ border-color: #6cb0f5; }}
  strong {{ display: block; font-size: 15px; }}
  span {{ display: block; margin-top: 3px; color: #9aa3b2; font-size: 13px; }}
</style>
</head>
<body>
  <main>
    <h1>시각화 워크스루</h1>
    <p class="lead">Godot 프로젝트를 챕터 단위로 뜯어 보는 웹 빌드입니다.
      각 워크스루는 처음 열 때 엔진 약 10 MB를 받고, 그 뒤로는 캐시를 씁니다.</p>
    <ul>
{cards}
    </ul>
  </main>
</body>
</html>
""",
        encoding="utf-8",
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, help="Godot 실행파일 경로")
    parser.add_argument("--out", default="_out/viz", help="출력 폴더")
    parser.add_argument("--only", nargs="*", metavar="SLUG",
                        help="일부만 빌드한다(공유 엔진 검사는 건너뛴다)")
    args = parser.parse_args()

    slugs = args.only or list(PROJECTS)
    unknown = [s for s in slugs if s not in PROJECTS]
    if unknown:
        raise SystemExit(f"[build_web] 모르는 slug: {', '.join(unknown)}")

    out = Path(args.out).resolve()
    staging = out.parent / (out.name + ".staging")
    for path in (out, staging):
        shutil.rmtree(path, ignore_errors=True)

    for slug in slugs:
        folder = PROJECTS[slug][0]
        print(f"[build_web] {slug} ← {folder}", flush=True)
        export(args.godot, ROOT / folder, staging / slug)

    # 공유의 전제를 확인한다. 다르면 프로젝트마다 다른 엔진이 필요하다는 뜻이고,
    # 그대로 조립하면 한 벌만 남아 나머지가 엉뚱한 엔진으로 돌아간다.
    hashes = {slug: sha256(staging / slug / "index.wasm") for slug in slugs}
    if len(set(hashes.values())) != 1:
        for slug, digest in hashes.items():
            print(f"  {slug}: {digest}", file=sys.stderr)
        raise SystemExit("[build_web] wasm 해시가 갈렸다 — 엔진을 공유할 수 없다")
    print(f"[build_web] wasm 해시 일치: {next(iter(hashes.values()))[:16]}…")

    engine = out / "_engine"
    engine.mkdir(parents=True)
    first = staging / slugs[0]
    for source_name, target_name in ENGINE_FILES.items():
        source = first / source_name
        if source.exists():  # 오디오 워크릿은 설정에 따라 안 나올 수 있다
            shutil.copy2(source, engine / target_name)
    wasm_size = (engine / "godot.wasm").stat().st_size

    for slug in slugs:
        source, target = staging / slug, out / slug
        target.mkdir(parents=True)
        shutil.copy2(source / "index.pck", target / f"{slug}.pck")
        for name in PROJECT_FILES:
            if (source / name).exists():
                shutil.copy2(source / name, target / name)
        pck_size = (target / f"{slug}.pck").stat().st_size
        (target / "index.html").write_text(
            shell_html(source / "index.html", slug, pck_size, wasm_size),
            encoding="utf-8",
        )

    landing(out)

    # 엔진 폴더 이름이 밑줄로 시작한다. Jekyll은 그런 폴더를 자기 것으로 보고
    # 발행에서 빼므로, 켜져 있으면 39 MB짜리 wasm이 통째로 404가 된다.
    # Actions로 배포할 때는 Jekyll이 돌지 않지만, 브랜치 배포로 바꾸는 순간
    # 조용히 깨지는 자리라 못을 박아 둔다.
    (out / ".nojekyll").touch()

    shutil.rmtree(staging, ignore_errors=True)

    total = sum(p.stat().st_size for p in out.rglob("*") if p.is_file())
    print(f"[build_web] 완료 → {out}")
    print(f"[build_web] 엔진 {wasm_size / 2**20:.1f} MB + 프로젝트 {len(slugs)}개"
          f" = 합계 {total / 2**20:.1f} MB")


if __name__ == "__main__":
    main()
