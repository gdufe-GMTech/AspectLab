"""粗粒度 Swift 静态自查：括号配对 + 常见笔误。

不做类型检查（需要 Swift 编译器），只用来抓括号、字符串、明显的 API 误用。
"""

import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Sources")

PAIRS = {"(": ")", "[": "]", "{": "}"}
CLOSERS = {v: k for k, v in PAIRS.items()}

# (正则, 说明)
SUSPECTS = [
    (r"CGFloat\(\s*Double\(", "CGFloat(Double(...)) 多余包装"),
    (r"\.frame\(width: [^,]*Double\(", "frame(width:) 里出现 Double()"),
    (r"Text\(\"[^\"]*\"\)\s*\.font\(\.system\(size: \d+\)\)\s*\.font\(", "重复 .font"),
    (r";;\s*$", "多余分号"),
]


def strip_code(line, state):
    """去掉字符串与注释，state 跨行跟踪块注释。"""
    out = []
    i = 0
    in_str = state.get("str", False)
    while i < len(line):
        ch = line[i]
        nxt = line[i + 1] if i + 1 < len(line) else ""
        if state.get("block", False):
            if ch == "*" and nxt == "/":
                state["block"] = False
                i += 2
                continue
            i += 1
            continue
        if in_str:
            if ch == "\\":
                i += 2
                continue
            if ch == '"':
                in_str = False
            i += 1
            continue
        if ch == "/" and nxt == "/":
            break
        if ch == "/" and nxt == "*":
            state["block"] = True
            i += 2
            continue
        if ch == '"':
            in_str = True
            i += 1
            continue
        out.append(ch)
        i += 1
    state["str"] = in_str
    return "".join(out)


def check_file(path):
    problems = []
    stack = []
    state = {}
    with open(path, "r", encoding="utf-8") as fh:
        for lineno, raw in enumerate(fh, 1):
            code = strip_code(raw.rstrip("\n"), state)
            for ch in code:
                if ch in PAIRS:
                    stack.append((ch, lineno))
                elif ch in CLOSERS:
                    if not stack:
                        problems.append((lineno, f"多余的 {ch}"))
                    else:
                        open_ch, open_line = stack.pop()
                        if PAIRS[open_ch] != ch:
                            problems.append(
                                (lineno, f"{ch} 与第 {open_line} 行的 {open_ch} 不匹配"))
            for pattern, note in SUSPECTS:
                if re.search(pattern, code):
                    problems.append((lineno, note))
    for ch, lineno in stack:
        problems.append((lineno, f"未闭合的 {ch}"))
    return problems


def main():
    files = sorted(
        os.path.join(ROOT, name)
        for name in os.listdir(ROOT)
        if name.endswith(".swift")
    )
    total = 0
    for path in files:
        problems = check_file(path)
        name = os.path.basename(path)
        if problems:
            total += len(problems)
            print(f"[FAIL] {name}")
            for lineno, note in problems:
                print(f"       {lineno}: {note}")
        else:
            with open(path, "r", encoding="utf-8") as fh:
                n = sum(1 for _ in fh)
            print(f"[ OK ] {name}  ({n} 行)")
    print()
    print(f"文件 {len(files)} 个，问题 {total} 个")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
