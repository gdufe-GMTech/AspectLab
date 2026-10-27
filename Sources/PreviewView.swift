import SwiftUI

struct PreviewView: View {
    @ObservedObject var model: LabModel

    private var plan: RenderPlan { model.appliedPlan }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                headerCard
                canvasCard
                compareCard
                fovCard
                noteCard
                Color.clear.frame(height: 6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .background(Theme.bg)
    }

    // MARK: - 头部

    private var headerCard: some View {
        CardView {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.title(for: model.applied))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.text)
                    Text("\(plan.renderLabel) → \(plan.panelLabel)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.dim)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(String(format: "×%.3f", plan.distortion))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(plan.distortion > 1.001 ? Theme.warn : Theme.accent)
                    Text("横向倍率")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.dim)
                }
            }
        }
    }

    // MARK: - 主画布

    private var canvasCard: some View {
        CardView(padding: 10) {
            GeometryReader { geo in
                let size = fitted(geo.size, aspect: CGFloat(plan.panelAspect))
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black)
                    sceneLayer(size: size)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(height: 232)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 12) {
                legendDot(color: Theme.accent, text: "准星")
                legendDot(color: Theme.warn, text: "头部靶标（比例示意）")
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    private func sceneLayer(size: CGSize) -> some View {
        let isStretch = plan.fill == .stretch
        let width: CGFloat = isStretch ? size.width : min(size.width, size.height * CGFloat(plan.targetAspect))
        return SceneView(designAspect: plan.targetAspect)
            .frame(width: width, height: size.height)
            .overlay(
                Rectangle()
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
    }

    private func fitted(_ available: CGSize, aspect: CGFloat) -> CGSize {
        guard available.width > 1, available.height > 1, aspect > 0.1 else {
            return CGSize(width: 1, height: 1)
        }
        var w = available.width
        var h = w / aspect
        if h > available.height {
            h = available.height
            w = h * aspect
        }
        return CGSize(width: max(w, 1), height: max(h, 1))
    }

    private func legendDot(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.system(size: 10.5))
                .foregroundColor(Theme.dim)
        }
    }

    // MARK: - 取景对照

    private var compareCard: some View {
        CardView {
            CardTitle(text: "取景对照")
            HStack(spacing: 10) {
                thumbnail(title: "原生", aspect: plan.panelAspect, stretched: false, badge: "1.000×")
                thumbnail(title: plan.fill == .stretch ? "拉伸" : "黑边",
                          aspect: plan.targetAspect,
                          stretched: plan.fill == .stretch,
                          badge: String(format: "%.3f×", plan.distortion))
            }
        }
    }

    private func thumbnail(title: String, aspect: Double, stretched: Bool, badge: String) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let size = fitted(geo.size, aspect: CGFloat(plan.panelAspect))
                ZStack {
                    Color.black
                    SceneView(designAspect: stretched ? plan.targetAspect : aspect, showGrid: false)
                        .frame(width: stretched ? size.width : min(size.width, size.height * CGFloat(aspect)),
                               height: size.height)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.text)
                Text(badge)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.dim)
            }
        }
    }

    // MARK: - 视野

    private var fovCard: some View {
        CardView {
            CardTitle(text: "视野损失")
            HStack(spacing: 12) {
                GeometryReader { geo in
                    let size = fitted(geo.size, aspect: CGFloat(plan.panelAspect))
                    ZStack {
                        Color.black
                        SceneView(designAspect: plan.panelAspect, showGrid: false)
                            .frame(width: size.width, height: size.height)
                        Rectangle()
                            .strokeBorder(Theme.accent, style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                            .frame(width: size.width * CGFloat(plan.fovKeepRatio), height: size.height)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .frame(width: 150, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(String(format: "%.1f° → %.1f°", plan.hFOVPanel, plan.hFOVRender))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.text)
                    Text("水平视野")
                        .font(.system(size: 10.5))
                        .foregroundColor(Theme.dim)
                    Text(String(format: "保留 %.0f%% 横向视野", plan.fovKeepRatio * 100))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.warn)
                    Text("虚线内为 4:3 能看到的范围")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.dim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - 说明

    private var noteCard: some View {
        CardView {
            CardTitle(text: "怎么读这张图")
            VStack(alignment: .leading, spacing: 8) {
                bullet("画面的畸变就是真实拉伸的畸变：圆变椭圆，横向 ×\(String(format: "%.2f", plan.distortion))。")
                bullet("靶标直径代表头宽。拉伸后宽度 ×\(String(format: "%.2f", plan.distortion))，但纵向不变，所以目标更容易被横向扫到，代价是两侧三角区被切掉。")
                bullet("这不能改变命中箱、判定逻辑或后坐力，只是让你看到的画面更宽。")
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Circle()
                .fill(Theme.accent.opacity(0.7))
                .frame(width: 4, height: 4)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 11.5))
                .foregroundColor(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
