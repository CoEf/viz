#!/usr/bin/env python3
"""워크스루 목록 카드에 쓸 대표 화면을 뽑는다.

    python tools/shoot_covers.py --godot <godot 실행파일> [--only SLUG ...]

목록은 build_web.py의 discover()가 정한다. 여기서 다시 훑지 않는다 —
두 곳이 각자 폴더를 세면 언젠가 한쪽만 새 프로젝트를 본다.

── 왜 새 캡처 하네스를 만들지 않는가 ────────────────────────────────
pipeline_viz 러너가 이미 `-- --autotour <폴더>`로 모든 챕터·스텝을 찍고
종료한다. 그림을 만드는 코드가 하나뿐이라, 러너의 UI가 바뀌면 썸네일도
저절로 따라 바뀐다. 별도 하네스를 두면 그때부터 둘을 맞춰야 한다.

프로토타입 쪽 `_capture/`를 쓰지 않는 것도 같은 이유다. 그쪽은 입력 계획을
재생해 8초 클립을 뽑는 물건이라, 씬을 직접 instantiate한다 — 워크스루는
러너가 챕터를 넣어 주는 구조라 그 방식으로는 빈 화면이 나온다.
"""

from __future__ import annotations

import argparse
import importlib.util
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent

# 러너를 띄울 창 크기. 1600x900은 러너의 stretch 기준 해상도라, 이 값에서만
# 2D에 배율이 안 걸린다(walkthrough.gd의 _sync_viewport_density 참고).
SHOT_SIZE = (1600, 900)

# 카드 규격. walkthroughs/index.astro의 .thumb-frame이 760/327을 쓴다.
CARD_SIZE = (760, 327)


def _load_projects() -> dict:
    """build_web.py를 모듈로 읽어 PROJECTS를 가져온다."""
    spec = importlib.util.spec_from_file_location(
        "build_web", Path(__file__).with_name("build_web.py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.PROJECTS


def autotour(godot: str, project: Path, out: Path) -> None:
    """러너를 띄워 챕터·스텝을 전부 찍게 한다."""
    out.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [godot, "--path", str(project),
         "--resolution", "%dx%d" % SHOT_SIZE, "--position", "40,40",
         "--", "--autotour", str(out)],
        capture_output=True, text=True, encoding="utf-8", errors="replace",
        timeout=600,
    )
    if result.returncode != 0:
        sys.stderr.write((result.stdout or "") + (result.stderr or ""))
        raise SystemExit(f"[shoot_covers] {project.name}: 투어 실패")


def pick(shots: Path) -> Path:
    """가운데 챕터의 마지막 스텝을 고른다.

    첫 챕터는 무대만 세운 상태라 아무것도 안 쌓여 있고, 마지막 챕터는 결과만
    남아 무엇을 켜서 그렇게 됐는지가 안 보인다. 가운데 챕터의 마지막 스텝이
    그 챕터가 쌓아 올린 것을 다 보여주면서 아직 과정처럼 읽힌다.

    기존 여섯 장이 손으로 고른 자리도 이것이었다 — snow는 챕터 7개 중
    chapter_3_step_3이고, 이 규칙이 그대로 재현한다.
    """
    by_chapter: dict[int, list[Path]] = {}
    for path in shots.glob("chapter_*_step_*.png"):
        chapter = int(path.stem.split("_")[1])
        by_chapter.setdefault(chapter, []).append(path)
    if not by_chapter:
        raise SystemExit(f"[shoot_covers] {shots}: 찍힌 그림이 없다")
    chapters = sorted(by_chapter)
    target = chapters[len(chapters) // 2]
    return max(by_chapter[target], key=lambda p: int(p.stem.split("_")[3]))


def to_card(source: Path, target: Path) -> None:
    """카드 규격으로 줄여 webp로 쓴다.

    **비율을 안 지키고 눌러 담는다.** 1600x900을 760 폭에 균일하게 줄이면
    427이 되고, 327로 자르면 스텝 카드의 제목이나 아래 챕터 바 중 하나가
    잘린다. 기존 여섯 장이 눌러 담는 쪽으로 만들어져 있어서, 새로 넣는
    열넷만 비율이 다르면 목록에서 그 줄만 튄다.
    """
    image = Image.open(source).convert("RGB").resize(CARD_SIZE, Image.LANCZOS)
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target, "WEBP", quality=82, method=6)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, help="Godot 실행파일 경로")
    parser.add_argument("--blog", default=str(ROOT.parent / "web" / "devlog-blog"),
                        help="블로그 저장소 경로")
    parser.add_argument("--only", nargs="*", metavar="SLUG")
    parser.add_argument("--keep", action="store_true",
                        help="투어 원본 png를 지우지 않는다(다른 컷을 고르고 싶을 때)")
    args = parser.parse_args()

    projects = _load_projects()
    slugs = args.only or list(projects)
    unknown = [s for s in slugs if s not in projects]
    if unknown:
        raise SystemExit(f"[shoot_covers] 모르는 slug: {', '.join(unknown)}")

    dest = Path(args.blog) / "public" / "images" / "viz"
    if not (Path(args.blog) / "package.json").exists():
        raise SystemExit(f"[shoot_covers] 블로그가 없다: {args.blog}")

    for slug in slugs:
        folder = projects[slug][0]
        shots = Path(tempfile.mkdtemp(prefix=f"tour_{slug}_"))
        try:
            print(f"[shoot_covers] {slug} ← {folder}", flush=True)
            autotour(args.godot, ROOT / folder, shots)
            source = pick(shots)
            to_card(source, dest / f"{slug}.webp")
            print(f"  {source.name} → {slug}.webp", flush=True)
        finally:
            if args.keep:
                print(f"  원본: {shots}")
            else:
                shutil.rmtree(shots, ignore_errors=True)


if __name__ == "__main__":
    main()
