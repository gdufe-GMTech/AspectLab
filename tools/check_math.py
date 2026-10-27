"""把 LabMath 的公式在 Python 里复算一遍，验证自洽性并输出对照表。

用途：
  1. 确认 Swift 侧公式没有笔误（两边用同一组表达）；
  2. 生成「4:3 到底能得到什么」的具体数字。

用法：
  .venv/Scripts/python.exe tools/check_math.py
"""

import math

# 常见面板（短边 × 长边；脚本内部统一换算成横屏的长 × 短）
PANELS = [
    ("iPhone 16/17 Pro", 1206, 2622),
    ("iPhone 15 Pro", 1179, 2556),
    ("iPhone 14/13", 1170, 2532),
    ("iPad mini (4:3)", 1488, 2266),
]

HEAD_RADIUS = 0.11  # m
V_FOV = 60.0        # deg


def render_size(pw, ph, aspect, basis="height"):
    if basis == "height":
        h = ph
        w = round(ph * aspect)
    elif basis == "width":
        w = pw
        h = round(pw / aspect)
    else:
        area = pw * ph
        h = round(math.sqrt(area / aspect))
        w = round(h * aspect)
    if w > pw:
        w = pw
        h = round(pw / aspect)
    if h > ph:
        h = ph
        w = round(ph * aspect)
    return max(w, 2), max(h, 2)


def plan(pw, ph, aspect, v_fov=V_FOV, basis="height"):
    panel_aspect = pw / ph
    rw, rh = render_size(pw, ph, aspect, basis)
    render_aspect = rw / rh
    tan_v = math.tan(math.radians(v_fov) / 2)
    h_panel = 2 * math.degrees(math.atan(tan_v * panel_aspect))
    h_render = 2 * math.degrees(math.atan(tan_v * render_aspect))
    sx = pw / rw
    sy = ph / rh
    return {
        "panel_aspect": panel_aspect,
        "render": (rw, rh),
        "render_aspect": render_aspect,
        "h_panel": h_panel,
        "h_render": h_render,
        "sx": sx,
        "sy": sy,
        "distortion": sx / sy,
        "fov_keep": min(1.0, render_aspect / panel_aspect),
        "pixel_ratio": (rw * rh) / (pw * ph),
    }


def head_px(width, h_fov, scale, distance):
    return width * (HEAD_RADIUS / distance) / math.tan(math.radians(h_fov) / 2) * scale


def main():
    for name, short, long in PANELS:
        pw, ph = long, short  # 横屏：长边为宽
        print(f"=== {name}  面板 {pw}×{ph} ===")
        for label, aspect in [("4:3", 4 / 3), ("16:9", 16 / 9), ("16:10", 1.6), ("21:9", 21 / 9)]:
            p = plan(pw, ph, aspect)
            rw, rh = p["render"]
            native_head = head_px(pw, p["h_panel"], 1.0, 20)
            target_head = head_px(rw, p["h_render"], p["sx"], 20)
            print(
                f"  {label:5s} -> {rw}×{rh}"
                f"  拉伸 ×{p['distortion']:.3f}"
                f"  hFOV {p['h_panel']:.1f}°->{p['h_render']:.1f}°"
                f"  保留 {p['fov_keep'] * 100:.0f}%"
                f"  头部20m {native_head:.1f}->{target_head:.1f}px"
                f"  ({target_head / native_head:.2f}×)"
            )
        print()

    # 自洽性断言（横屏 2622×1206）
    pw, ph = 2622, 1206
    p = plan(pw, ph, 4 / 3)
    rw, rh = p["render"]
    native_head = head_px(pw, p["h_panel"], 1.0, 20)
    target_head = head_px(rw, p["h_render"], p["sx"], 20)

    assert abs(p["distortion"] - 1 / p["fov_keep"]) < 1e-9, "拉伸系数与视野保留应互为倒数"
    assert abs(p["pixel_ratio"] - p["fov_keep"]) < 1e-9, "像素负担应等于视野保留比例"
    assert abs(target_head / native_head - p["distortion"]) < 1e-9, "头部放大倍数应等于拉伸系数"

    # 距离无关性
    for d in (5, 10, 20, 50, 100):
        n = head_px(pw, p["h_panel"], 1.0, d)
        t = head_px(rw, p["h_render"], p["sx"], d)
        assert abs(t / n - p["distortion"]) < 1e-9, f"距离 {d} m 处倍数不为常数"

    print("自洽性断言全部通过：")
    print("  - 拉伸系数 = 1 / 视野保留比例")
    print("  - 像素负担 = 视野保留比例")
    print("  - 头部像素放大倍数 = 拉伸系数（与距离无关）")


if __name__ == "__main__":
    main()
