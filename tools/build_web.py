#!/usr/bin/env python3
"""다섯 개 시각화 프로젝트를 웹으로 내보내고, 배포할 수 있는 한 덩어리로 묶는다.

    python tools/build_web.py --godot <godot 실행파일> --out _out/viz

로컬에서 쓰는 명령과 CI가 쓰는 명령이 같다. 워크플로가 따로 조립 단계를
갖고 있으면, 로컬에서 되던 게 CI에서만 깨지는 자리가 하나 더 생긴다.

── 왜 엔진을 따로 빼는가 ────────────────────────────────────────────
프로젝트마다 통째로 내보내면 39 MB짜리 wasm이 다섯 벌 나와 200 MB가 된다.
그런데 다섯 빌드의 wasm은 바이트가 같다 — 같은 엔진, 같은 익스포트 설정이라
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
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# slug → (프로젝트 폴더, 제목, 한 줄 설명)
# slug는 배포 주소가 된다(…/viz/<slug>/). 블로그 본문의 ::godot{src="…"}가
# 이 값을 그대로 쓰므로, 한 번 정한 뒤에는 바꾸지 않는다 — 바꾸면 이미 나간
# 글의 임베드가 조용히 404가 된다.
PROJECTS = {
    "snow": (
        "Snow Pipeline Visualization",
        "눈 파이프라인",
        "무대 → 눈발 → 쌓임 → 발자국 → 반짝임까지 일곱 챕터",
    ),
    "water": (
        "Comunity Water Shaders Visualization",
        "물 셰이더 열아홉 개",
        "godotshaders.com에서 모은 물 셰이더를 한 무대에 올려 비교",
    ),
    "grass": (
        "Grass Shaders Visualization",
        "잔디 셰이더 열 개",
        "지오메트리 · 바람 · 눌림 · 알파까지 여섯 챕터",
    ),
    "rooms": (
        "Rooms Connector Visualization",
        "방 잇기",
        "들로네 삼각분할과 최소 신장 트리로 방을 연결",
    ),
    "ripple": (
        "Water Shader Visualization",
        "물결 시뮬레이션",
        "형태 → 디테일 → 표면 → 부피 → 거품까지 일곱 챕터",
    ),
}

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


# 내용이 같은 파일에 늘 같은 시각을 박기 위한 기준점. 2015-01-01 UTC에서
# 10년 폭 안으로 떨어뜨린다 — 전부 과거라 미래 날짜로 헷갈릴 일이 없다.
MTIME_EPOCH = 1420070400
MTIME_SPAN = 10 * 365 * 24 * 3600


def pin_mtimes(out: Path) -> None:
    """파일의 수정 시각을 내용에서 결정적으로 뽑아 박는다.

    GitHub Pages는 ETag를 `"<hex mtime>-<hex size>"`로 만든다(nginx 기본값).
    빌드는 매번 파일을 새로 쓰므로 내용이 같아도 mtime이 달라지고, 그러면
    배포할 때마다 방문자 캐시의 39 MB 엔진이 통째로 무효가 된다. 실제로
    챕터 한 줄만 고쳐 배포한 뒤 옛 ETag로 조건부 요청을 넣으면 304가 아니라
    200에 10.2 MB가 그대로 돌아왔다.

    그래서 시각을 시계가 아니라 내용에서 뽑는다. 엔진은 엔진이 바뀔 때만,
    pck는 그 프로젝트가 바뀔 때만 ETag가 움직인다 — 한 프로젝트만 고쳐
    배포해도 나머지 넷과 엔진은 방문자 캐시에 그대로 남는다.
    """
    for path in sorted(out.rglob("*")):
        if not path.is_file():
            continue
        stamp = MTIME_EPOCH + int(sha256(path)[:8], 16) % MTIME_SPAN
        os.utime(path, (stamp, stamp))


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

    pin_mtimes(out)

    shutil.rmtree(staging, ignore_errors=True)

    total = sum(p.stat().st_size for p in out.rglob("*") if p.is_file())
    print(f"[build_web] 완료 → {out}")
    print(f"[build_web] 엔진 {wasm_size / 2**20:.1f} MB + 프로젝트 {len(slugs)}개"
          f" = 합계 {total / 2**20:.1f} MB")


if __name__ == "__main__":
    main()
