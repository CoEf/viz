#!/usr/bin/env python3
"""블로그의 워크스루 목록(src/utils/walkthroughs.ts)을 다시 쓴다.

    python tools/gen_walkthroughs.py [--blog <경로>] [--check]

── 왜 생성하는가 ───────────────────────────────────────────────────
워크스루 하나를 내보내려면 예전에는 등록부 셋이 맞아야 했다: 이 저장소의
폴더, build_web.py의 PROJECTS, 그리고 블로그의 walkthroughs.ts. 셋이
어긋나도 양쪽 빌드는 멀쩡히 통과하고 카드만 404가 되므로 아무도 모른다.

이제 폴더가 유일한 진실이고 나머지 둘은 거기서 나온다. `--check`는 파일이
지금 폴더와 어긋나 있는지만 보고 다르면 1로 끝난다 — 사람이 목록을 대조하는
대신 CI가 대조하게 하려는 것이다.

블로그 저장소는 CI에서 이 폴더를 볼 수 없다(다른 저장소다). 그래서 이 명령은
로컬에서 돌리고 산출물을 커밋한다. 무엇이 새로 생겼는지는 그 커밋의 diff가
말해 준다.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

HEADER = '''/**
 * 워크스루 목록 — /walkthroughs/ 가 그리고, 본문 임베드가 slug로 문다.
 *
 * ⚠ **생성물이다. 손으로 고치지 마라.** 고쳐도 다음 생성 때 지워진다.
 *   viz 저장소에서 `python tools/gen_walkthroughs.py`가 다시 쓴다.
 *   제목·한 줄을 바꾸려면 그쪽 `tools/build_web.py`의 LABELS를 고친다.
 *
 * 실체는 이 저장소에 없다. Godot 프로젝트는 CoEf/viz가 갖고 있고, 그쪽
 * Actions가 빌드해 https://CoEf.github.io/viz/<slug>/ 로 올린다. 여기 있는
 * 것은 목록을 그리기 위한 메타데이터뿐이다.
 *
 * 예전에는 이 배열을 손으로 적었고, 그래서 viz 쪽 PROJECTS와 어긋나면
 * 카드가 조용히 404로 이어졌다. 지금은 둘 다 폴더에서 나오므로 어긋날 수 없다.
 *
 * 주소는 여기서 만들지 않는다 — astro.config의 remarkGodot에 넘기는
 * vizBase와 같은 값을 써야 본문 임베드와 목록이 같은 곳을 가리킨다.
 */

export interface Walkthrough {
  /** 배포 주소의 마지막 칸. viz의 PROJECTS 키와 같다. */
  slug: string;
  title: string;
  /** 카드 본문 한 줄. 무엇을 뜯어 보는지. */
  summary: string;
  /** 챕터 수 — 분량을 짐작하게 하는 유일한 단서라 카드에 찍는다. */
  chapters: number;
  /** public/images/viz/ 아래의 대표 화면. 워크스루를 실제로 찍은 것이다. */
  thumbnail: string;
}

export const WALKTHROUGHS: Walkthrough[] = [
'''


def _build_web():
    spec = importlib.util.spec_from_file_location(
        "build_web", Path(__file__).with_name("build_web.py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def last_touched(folder: str) -> int:
    """폴더가 마지막으로 커밋된 시각. 목록 순서(최신 먼저)를 정하는 값이다.

    아직 커밋 안 된 것은 '가장 최근'으로 본다. 파일 시각을 쓰면 Godot이
    .godot 캐시를 건드릴 때마다 순서가 흔들려서, 다시 생성할 때마다 내용은
    같은데 줄만 뒤바뀐 diff가 난다 — --check가 그때마다 헛되이 터진다.
    """
    result = subprocess.run(
        ["git", "log", "-1", "--format=%ct", "--", folder],
        cwd=ROOT, capture_output=True, text=True)
    stamp = (result.stdout or "").strip()
    if stamp:
        return int(stamp)
    return 1 << 62


def render(projects: dict, labels: dict) -> str:
    rows = []
    for slug, (folder, title, _note) in projects.items():
        chapters = len(list((ROOT / folder).glob("chapters/chapter_*.tscn")))
        rows.append({
            "slug": slug,
            "title": title,
            "summary": labels.get(slug, {}).get("summary", ""),
            "chapters": chapters,
            "thumbnail": f"/images/viz/{slug}.webp",
            "_sort": (-last_touched(folder), folder),
        })
    rows.sort(key=lambda r: r.pop("_sort"))

    body = ""
    for row in rows:
        body += "  {\n"
        for key, value in row.items():
            literal = json.dumps(value, ensure_ascii=False)
            if isinstance(value, str):
                literal = "'" + value.replace("\\", "\\\\").replace("'", "\'") + "'"
            body += f"    {key}: {literal},\n"
        body += "  },\n"
    return HEADER + body + "];\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--blog", default=str(ROOT.parent / "web" / "devlog-blog"))
    parser.add_argument("--check", action="store_true",
                        help="쓰지 않고, 폴더와 어긋나 있으면 1로 끝낸다")
    args = parser.parse_args()

    blog = Path(args.blog)
    if not (blog / "package.json").exists():
        raise SystemExit(f"[gen_walkthroughs] 블로그가 없다: {blog}")

    module = _build_web()
    text = render(module.PROJECTS, module.LABELS)
    target = blog / "src" / "utils" / "walkthroughs.ts"

    # 대표 화면이 없으면 카드가 빈 상자가 된다. 멈추지는 않는다 — 방금 만든
    # 프로젝트를 목록에서 빼는 것보다는 그림 없이 올라가는 편이 낫다.
    missing = [p.name for p in
               (blog / "public" / "images" / "viz" / f"{slug}.webp"
                for slug in module.PROJECTS)
               if not p.exists()]
    if missing:
        print(f"[gen_walkthroughs] 대표 화면 없음 {len(missing)}개: "
              f"{', '.join(missing)}", file=sys.stderr)

    if args.check:
        current = target.read_text(encoding="utf-8") if target.exists() else ""
        if current != text:
            print("[gen_walkthroughs] walkthroughs.ts가 폴더와 어긋나 있다. "
                  "--check 없이 다시 돌려라.", file=sys.stderr)
            raise SystemExit(1)
        print(f"[gen_walkthroughs] 일치 ({len(module.PROJECTS)}개)")
        return

    target.write_text(text, encoding="utf-8", newline="\n")
    print(f"[gen_walkthroughs] {target} ← {len(module.PROJECTS)}개")


if __name__ == "__main__":
    main()
