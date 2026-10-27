"""生成 AspectLab 的 App 图标（无外部素材，纯几何绘制）。

输出到 Resources/Icons/：
  AppIcon60x60@2x.png  120
  AppIcon60x60@3x.png  180
  AppIcon76x76@2x.png  152
  AppIcon1024.png      1024
"""

import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Resources", "Icons")

BG_TOP = (14, 22, 30)
BG_BOT = (7, 11, 15)
LINE = (34, 46, 58)
DIM = (58, 78, 96)
ACCENT = (51, 214, 166)
ACCENT_DARK = (16, 92, 74)


def rounded(draw, box, radius, outline=None, fill=None, width=1):
    draw.rounded_rectangle(box, radius=radius, outline=outline, fill=fill, width=width)


def build(size=1024):
    img = Image.new("RGB", (size, size), BG_BOT)
    draw = ImageDraw.Draw(img)

    # 竖向渐变背景
    for y in range(size):
        t = y / max(size - 1, 1)
        color = (
            int(BG_TOP[0] + (BG_BOT[0] - BG_TOP[0]) * t),
            int(BG_TOP[1] + (BG_BOT[1] - BG_TOP[1]) * t),
            int(BG_TOP[2] + (BG_BOT[2] - BG_TOP[2]) * t),
        )
        draw.line([(0, y), (size, y)], fill=color)

    cx, cy = size // 2, size // 2

    # 16:9 外框（暗）
    w16 = int(size * 0.66)
    h16 = int(w16 * 9 / 16)
    rounded(draw,
            [cx - w16 // 2, cy - h16 // 2, cx + w16 // 2, cy + h16 // 2],
            radius=int(size * 0.045),
            outline=DIM,
            width=int(size * 0.012))

    # 4:3 内框（亮，实心）
    w43 = int(size * 0.42)
    h43 = int(w43 * 3 / 4)
    rounded(draw,
            [cx - w43 // 2, cy - h43 // 2, cx + w43 // 2, cy + h43 // 2],
            radius=int(size * 0.035),
            fill=ACCENT)

    # 4:3 框内的小网格，暗示“换算”
    grid = ACCENT_DARK
    for i in range(1, 4):
        x = cx - w43 // 2 + w43 * i // 4
        draw.line([(x, cy - h43 // 2 + 8), (x, cy + h43 // 2 - 8)],
                  fill=grid, width=max(1, int(size * 0.004)))
    for i in range(1, 3):
        y = cy - h43 // 2 + h43 * i // 3
        draw.line([(cx - w43 // 2 + 8, y), (cx + w43 // 2 - 8, y)],
                  fill=grid, width=max(1, int(size * 0.004)))

    # 四角裁切标记，暗示“取景框”
    m = int(size * 0.075)
    tick = int(size * 0.045)
    lw = max(1, int(size * 0.006))
    corners = [
        ((m, m), (m + tick, m), (m, m + tick)),
        ((size - m, m), (size - m - tick, m), (size - m, m + tick)),
        ((m, size - m), (m + tick, size - m), (m, size - m - tick)),
        ((size - m, size - m), (size - m - tick, size - m), (size - m, size - m - tick)),
    ]
    for corner in corners:
        origin, p2, p3 = corner
        draw.line([origin, p2], fill=LINE, width=lw)
        draw.line([origin, p3], fill=LINE, width=lw)

    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    base = build(1024)
    targets = [
        ("AppIcon1024.png", 1024),
        ("AppIcon60x60@2x.png", 120),
        ("AppIcon60x60@3x.png", 180),
        ("AppIcon76x76@2x.png", 152),
    ]
    for name, px in targets:
        img = base.resize((px, px), Image.LANCZOS)
        path = os.path.join(OUT, name)
        img.save(path, "PNG")
        print(f"{name:24s} {px}x{px}  {os.path.getsize(path)} bytes")


if __name__ == "__main__":
    main()
