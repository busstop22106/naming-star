#!/usr/bin/env python3
"""한자 DB의 빈 뜻을 대법원 인명용 한자표 훈으로 채운다.

데이터 출처: 대법원 전자가족관계등록시스템 webhanja 데이터
(공공 고시인 인명용 한자표의 음·훈. krcourt 저장소의 json/ 캐시 사용)
  1. sparse clone으로 json/만 받는다:
     git clone --depth 1 --filter=blob:none --sparse \
       https://github.com/delvier/KoreaSCourtCode.git krcourt
     cd krcourt && git sparse-checkout set json
  2. python3 tool/fill_hanja_meanings.py <json_dir> <dart_file>

규칙:
- 이미 뜻이 있는 항목은 절대 건드리지 않는다 (curated 110개 포함).
- 뜻이 비어 있는 항목만 채운다. 1순위 `in`(인명 훈), 2순위 `dic`(사전 훈).
- `in`/`dic` 형식이 "음 : 훈(음) ..."이 아니거나, 훈 파싱에 찌꺼기가
  남으면 그 기록은 건너뛴다 (잘못된 뜻을 넣느니 비워두는 게 낫다).
- 한 글자에 같은 음의 훈이 여러 개면 첫 번째를 쓴다 (대법원 표의 첫 훈).
"""
import glob
import json
import re
import sys
from pathlib import Path

SEG_RE = re.compile(r"(\S+?)\(([^)]+)\)")


def is_cjk(cp: int) -> bool:
    return (
        0x3400 <= cp <= 0x4DBF
        or 0x4E00 <= cp <= 0x9FFF
        or 0xF900 <= cp <= 0xFAFF
        or 0x20000 <= cp <= 0x2A6DF
        or 0x2A700 <= cp <= 0x2EBEF
    )


def parse_meanings(field: str | None) -> dict[str, str] | None:
    """'가 : 더할(가) 아름다울(가)' -> {'가': '더할'} (첫 훈만)."""
    s = (field or "").strip()
    if not s or ":" not in s:
        return None
    _, mpart = s.split(":", 1)
    mpart = mpart.strip()
    segs = SEG_RE.findall(mpart)
    if not segs or SEG_RE.sub("", mpart).strip():
        return None
    out: dict[str, str] = {}
    for text, paren in segs:
        for rd in paren.split("/"):
            out.setdefault(rd.strip(), text)
    return out


def build_lookup(json_dir: str) -> dict[tuple[str, str], str]:
    lookup: dict[tuple[str, str], str] = {}
    for path in glob.glob(f"{json_dir}/*.json"):
        try:
            data = json.load(open(path, encoding="utf-8"))
        except Exception:
            continue
        for rec in data:
            try:
                cp = int(rec["cd"], 16)
            except (KeyError, ValueError):
                continue
            if not is_cjk(cp):
                continue
            ch = chr(cp)
            # 1순위: 인명 훈 (isin==1 기록만)
            if rec.get("isin") == 1:
                meanings = parse_meanings(rec.get("in"))
                if meanings:
                    for rd, text in meanings.items():
                        lookup.setdefault((ch, rd), text)
            # 2순위: 사전 훈 (인명 훈에 없을 때만)
            meanings = parse_meanings(rec.get("dic"))
            if meanings:
                for rd, text in meanings.items():
                    lookup.setdefault((ch, rd), text)
    return lookup


ENTRY_RE = re.compile(
    r"HanjaFullEntry\(syllable: '([^']*)', char: '(.)', strokes: \d+, "
    r"element: '([^']*)', meaning: '([^']*)'"
)


def main() -> None:
    json_dir, dart_path = sys.argv[1], sys.argv[2]
    lookup = build_lookup(json_dir)
    print(f"lookup pairs: {len(lookup)}")

    lines = Path(dart_path).read_text(encoding="utf-8").splitlines(keepends=True)
    filled = skipped = 0
    unsafe = []
    for i, line in enumerate(lines):
        m = ENTRY_RE.search(line)
        if not m:
            continue
        syllable, char, _, meaning = m.groups()
        if meaning:
            continue
        text = lookup.get((char, syllable))
        if not text:
            skipped += 1
            continue
        if "'" in text or "\\" in text or "\n" in text:
            unsafe.append((syllable, char, text))
            skipped += 1
            continue
        lines[i] = line.replace("meaning: ''", f"meaning: '{text}'", 1)
        filled += 1
    Path(dart_path).write_text("".join(lines), encoding="utf-8")
    print(f"filled: {filled}, still empty: {skipped}")
    if unsafe:
        print(f"unsafe meanings skipped: {unsafe}")


if __name__ == "__main__":
    main()
