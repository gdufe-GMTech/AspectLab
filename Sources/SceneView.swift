import SwiftUI

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// 几何示意图：以 designAspect 设计的画面，被放进任意宽高比的框里。
/// 框比设计稿宽时，横向被拉伸 —— 这正是 4:3 → 19.5:9 的效果。
struct SceneView: View {
    var designAspect: Double
    var showGrid: Bool = true

    private let headXs: [CGFloat] = [0.15, 0.30, 0.50, 0.70, 0.85]

    var body: some View {
        GeometryReader { geo in
            let w: CGFloat = geo.size.width
            let h: CGFloat = geo.size.height
            let virtualW: CGFloat = max(h * CGFloat(designAspect), 1)
            let sx: CGFloat = w / virtualW

            ZStack {
                LinearGradient(colors: [Theme.skyTop, Theme.skyBottom],
                               startPoint: .top,
                               endPoint: .bottom)

                // 远景树线
                ForEach(0..<11, id: \.self) { i in
                    let index = CGFloat(i)
                    let bump = CGFloat(i % 3)
                    Triangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: virtualW * 0.16 * sx,
                               height: h * (0.05 + 0.03 * bump))
                        .position(x: virtualW * (0.02 + 0.10 * index) * sx,
                                  y: h * 0.655)
                }

                // 地表
                LinearGradient(colors: [Theme.groundTop, Theme.groundBottom],
                               startPoint: .top,
                               endPoint: .bottom)
                    .frame(width: w, height: h * 0.345)
                    .position(x: w / 2, y: h * 0.828)

                // 地平线
                Rectangle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: w, height: 1)
                    .position(x: w / 2, y: h * 0.66)

                if showGrid {
                    ForEach(1..<10, id: \.self) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.055))
                            .frame(width: 1, height: h)
                            .position(x: virtualW * (CGFloat(i) / 10.0) * sx,
                                      y: h / 2)
                    }
                    ForEach(1..<4, id: \.self) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.055))
                            .frame(width: w, height: 1)
                            .position(x: w / 2, y: h * (CGFloat(i) / 4.0))
                    }
                }

                // 掩体方块
                ForEach(0..<2, id: \.self) { i in
                    let index = CGFloat(i)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.white.opacity(0.09))
                        .frame(width: virtualW * 0.09 * sx,
                               height: h * (0.09 + 0.03 * index))
                        .position(x: virtualW * (0.38 + 0.28 * index) * sx,
                                  y: h * 0.72)
                }

                // 头部靶标
                ForEach(0..<headXs.count, id: \.self) { i in
                    let diameter: CGFloat = h * 0.042
                    let cx: CGFloat = virtualW * headXs[i] * sx
                    let cy: CGFloat = h * 0.455

                    Ellipse()
                        .fill(Theme.warn.opacity(0.92))
                        .frame(width: diameter * sx, height: diameter)
                        .position(x: cx, y: cy)

                    Rectangle()
                        .fill(Theme.warn.opacity(0.35))
                        .frame(width: diameter * 1.6 * sx, height: 1)
                        .position(x: cx, y: cy + diameter * 0.85)
                }

                // 准星
                Rectangle()
                    .fill(Theme.accent.opacity(0.75))
                    .frame(width: 1, height: 14)
                    .position(x: w / 2, y: h / 2)
                Rectangle()
                    .fill(Theme.accent.opacity(0.75))
                    .frame(width: 14, height: 1)
                    .position(x: w / 2, y: h / 2)
            }
            .clipped()
        }
    }
}
