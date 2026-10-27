import SwiftUI

struct ForensicsView: View {
    @ObservedObject var model: LabModel
    @StateObject private var logger = DisplayLogger()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                currentCard
                actionCard
                verdictCard
                logCard
                criteriaCard
                Color.clear.frame(height: 6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .background(Theme.bg)
        .onAppear { logger.sampleNow() }
        .onDisappear { logger.stop() }
    }

    // MARK: - 当前状态

    private var currentCard: some View {
        CardView {
            CardTitle(text: "当前屏幕状态（只读）")
            KeyValueRow(key: "面板像素", value: model.display.pixelSizeLabel)
            HairLine()
            KeyValueRow(key: "逻辑分辨率", value: model.display.pointLabel)
            HairLine()
            KeyValueRow(key: "scale / nativeScale", value: model.display.scaleLabel)
            HairLine()
            KeyValueRow(key: "显示缩放", value: model.display.zoomLabel,
                        tint: model.display.isZoomed ? Theme.warn : Theme.text)
            HairLine()
            KeyValueRow(key: "采样条数", value: "\(logger.samples.count)")
        }
    }

    // MARK: - 操作

    private var actionCard: some View {
        CardView {
            CardTitle(text: "取证操作")

            HStack(spacing: 10) {
                actionButton(title: "记录基线", filled: true) {
                    logger.markBaseline()
                    model.showToast("已记录基线")
                }
                actionButton(title: "采样一次", filled: false) {
                    logger.sampleNow()
                    model.showToast("已采样")
                }
            }

            actionButton(title: logger.isWatching ? "停止自动监视" : "开始自动监视（每秒）",
                         filled: false) {
                logger.toggleWatch()
            }
            .padding(.top, 8)

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                Text("采样只在你回到本页时运行。流程：记录基线 → 切到那个工具去「应用」→ 切回来点「采样一次」。")
                    .font(.system(size: 11))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(Theme.dim)
            .padding(.top, 10)
        }
    }

    private func actionButton(title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(filled ? Theme.bg : Theme.text)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(filled ? Theme.accent : Theme.cardAlt)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 判定

    private var verdictCard: some View {
        CardView {
            CardTitle(text: "与基线对比")

            if let base = logger.baseline, let now = logger.latest {
                compareRow(label: "面板像素",
                           before: base.pixelLabel,
                           after: now.pixelLabel)
                HairLine()
                compareRow(label: "逻辑分辨率",
                           before: base.pointLabel,
                           after: now.pointLabel)
                HairLine()
                compareRow(label: "缩放",
                           before: base.scaleLabel,
                           after: now.scaleLabel)

                verdictBanner(base: base, now: now)
                    .padding(.top, 10)
            } else {
                Text("先点「记录基线」，再去操作那个工具，回来点「采样一次」。")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func compareRow(label: String, before: String, after: String) -> some View {
        let changed = before != after
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.dim)
                .frame(width: 74, alignment: .leading)
            Text(before)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.dim)
            Image(systemName: changed ? "arrow.right" : "equal")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(changed ? Theme.warn : Theme.dim)
            Text(after)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(changed ? Theme.warn : Theme.text)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }

    private func verdictBanner(base: DisplaySample, now: DisplaySample) -> some View {
        let pixelsChanged = base.pixelLabel != now.pixelLabel
        let pointsChanged = base.pointLabel != now.pointLabel

        let text: String
        let tint: Color
        if pixelsChanged {
            text = "面板像素变了：系统分辨率确实被改了。"
            tint = Theme.accent
        } else if pointsChanged {
            text = "只有逻辑分辨率变：属于显示缩放一类的布局变化，宽高比没变，拿不到拉伸。"
            tint = Theme.warn
        } else {
            text = "两项都没变：那个工具没有触及系统分辨率层。"
            tint = Theme.danger
        }

        return HStack(alignment: .top, spacing: 7) {
            Rectangle()
                .fill(tint)
                .frame(width: 3, height: 14)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(tint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 记录

    private var logCard: some View {
        CardView {
            CardTitle(text: "记录")
            if logger.samples.isEmpty {
                Text("暂无记录")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.dim)
            } else {
                ForEach(logger.samples.prefix(8)) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(item.timeLabel)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.dim)
                            .frame(width: 58, alignment: .leading)
                        Text(item.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.accent)
                            .frame(width: 34, alignment: .leading)
                        Text(item.pixelLabel)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.text)
                        Spacer(minLength: 4)
                        Text(item.pointLabel)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.dim)
                        Text(item.scaleLabel)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.dim)
                    }
                    .padding(.vertical, 4)
                }

                Button {
                    logger.clear()
                } label: {
                    Text("清空记录")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.dim)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.cardAlt)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - 判定标准

    private var criteriaCard: some View {
        CardView {
            CardTitle(text: "为什么看这两个数")
            VStack(alignment: .leading, spacing: 8) {
                bullet("nativeBounds 由显示驱动给出，是面板物理像素。它变了，才叫「系统分辨率被改了」。")
                bullet("bounds × scale 是给 App 用的逻辑分辨率。它变而 nativeBounds 不变，说明只是换了布局画布（显示缩放、兼容模式），宽高比不变。")
                bullet("两个都不变，就是系统层完全没动——那个工具做的事不在这一层。")
                bullet("本页只读：只调用 UIScreen 的四个属性，不写盘、不配对、不连接任何服务。")
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
