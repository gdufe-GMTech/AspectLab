import SwiftUI
import UIKit

struct MetricsView: View {
    @ObservedObject var model: LabModel

    private let distances: [Double] = [10, 20, 30, 50]

    private var plan: RenderPlan { model.appliedPlan }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                coreCard
                headCard
                systemCard
                exportCard
                footer
                Color.clear.frame(height: 6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .background(Theme.bg)
    }

    // MARK: - 核心读数

    private var coreCard: some View {
        CardView {
            CardTitle(text: "核心读数")
            KeyValueRow(key: "目标比例", value: String(format: "%.4f:1", plan.targetAspect))
            HairLine()
            KeyValueRow(key: "面板像素", value: plan.panelLabel)
            HairLine()
            KeyValueRow(key: "渲染像素", value: plan.renderLabel, tint: Theme.accent)
            HairLine()
            KeyValueRow(key: "铺满方式", value: plan.fit.title)
            HairLine()
            KeyValueRow(key: "横向倍率", value: String(format: "×%.3f", plan.distortion),
                        tint: plan.distortion > 1.001 ? Theme.warn : Theme.text)
            HairLine()
            KeyValueRow(key: "水平视野", value: String(format: "%.1f° → %.1f°", plan.hFOVPanel, plan.hFOVRender))
            HairLine()
            KeyValueRow(key: "视野变化", value: String(format: "%+.1f°", plan.hFOVDelta))
            HairLine()
            KeyValueRow(key: "垂直视野", value: String(format: "%.1f°（不变）", plan.vFOV))
            HairLine()
            KeyValueRow(key: "像素负担", value: String(format: "%.2f MP · %.0f%%", plan.renderMegapixels, plan.pixelRatio * 100))
        }
    }

    // MARK: - 头部像素

    private var headCard: some View {
        CardView {
            CardTitle(text: "头部像素宽度（头宽 0.22 m）")

            HStack(spacing: 0) {
                headerCell("距离", width: 56, align: .leading)
                headerCell("原生", width: 78, align: .trailing)
                headerCell("目标", width: 78, align: .trailing)
                headerCell("倍数", width: 62, align: .trailing)
            }
            .padding(.bottom, 6)

            ForEach(distances, id: \.self) { distance in
                let native = nativeHead(distance)
                let target = targetHead(distance)
                HStack(spacing: 0) {
                    Text(String(format: "%.0f m", distance))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.dim)
                        .frame(width: 56, alignment: .leading)
                    Text(String(format: "%.1f", native))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.text)
                        .frame(width: 78, alignment: .trailing)
                    Text(String(format: "%.1f", target))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.accent)
                        .frame(width: 78, alignment: .trailing)
                    Text(native > 0.01 ? String(format: "×%.2f", target / native) : "-")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.warn)
                        .frame(width: 62, alignment: .trailing)
                }
                .padding(.vertical, 4)
            }

            Text("倍数与距离无关，恒等于横向拉伸系数——这是几何上的必然，不是玄学。")
                .font(.system(size: 11))
                .foregroundColor(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
    }

    private func headerCell(_ text: String, width: CGFloat, align: Alignment) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundColor(Theme.dim)
            .frame(width: width, alignment: align)
    }

    private func nativeHead(_ distance: Double) -> Double {
        LabMath.nativeHeadPixels(panelWidth: Double(plan.panelWidth),
                                 hFOVPanel: plan.hFOVPanel,
                                 distance: distance)
    }

    private func targetHead(_ distance: Double) -> Double {
        LabMath.headPixels(renderWidth: Double(plan.renderWidth),
                           hFOV: plan.hFOVRender,
                           displayScaleX: plan.displayScaleX,
                           distance: distance)
    }

    // MARK: - 系统分辨率实情

    private var systemCard: some View {
        CardView {
            CardTitle(text: "系统分辨率：能做到哪一步")

            KeyValueRow(key: "UIScreen 可写模式", value: "不存在", tint: Theme.danger)
            HairLine()
            KeyValueRow(key: "显示缩放", value: model.display.zoomLabel,
                        tint: model.display.isZoomed ? Theme.warn : Theme.text)
            HairLine()
            KeyValueRow(key: "缩放后比例", value: model.display.aspectLabel)
            HairLine()
            KeyValueRow(key: "wm size 对等接口", value: "无", tint: Theme.danger)

            VStack(alignment: .leading, spacing: 8) {
                bullet("UIScreen 只暴露 availableModes / currentMode，没有 setMode。分辨率是只读属性。", strong: false)
                bullet("能改系统分辨率的工具都靠越狱态权限（CoreTrust 绕过或内核漏洞）；iOS 27 / t8160 没有公开链。", strong: false)
                bullet("官方唯一旋钮是「显示缩放」：换逻辑分辨率，宽高比固定，所以拿不到 4:3 拉伸。", strong: false)
                bullet("结论：4:3 真实拉伸在本机不可达。本页数字是「假如可达，会是多少」。", strong: true)
            }
            .padding(.top, 10)
        }
    }

    private func bullet(_ text: String, strong: Bool) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Rectangle()
                .fill(strong ? Theme.warn : Theme.dim.opacity(0.6))
                .frame(width: 3, height: strong ? 13 : 11)
                .padding(.top, strong ? 2 : 3)
            Text(text)
                .font(.system(size: 11.5, weight: strong ? .semibold : .regular))
                .foregroundColor(strong ? Theme.warn : Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 导出

    private var exportCard: some View {
        CardView {
            CardTitle(text: "导出读数")
            Button {
                UIPasteboard.general.string = model.exportText()
                model.showToast("读数已复制到剪贴板")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12, weight: .semibold))
                    Text("复制完整读数")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Theme.bg)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.accent)
                )
            }
            .buttonStyle(.plain)

            Text("包含设备、面板、渲染分辨率、视野与头部像素对照，便于跨设备核对。")
                .font(.system(size: 11))
                .foregroundColor(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
    }

    private var footer: some View {
        VStack(spacing: 3) {
            Text("AspectLab 1.1.0")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.dim)
            Text("只读计算 · 不改系统 · 不改其它 App")
                .font(.system(size: 10))
                .foregroundColor(Theme.dim.opacity(0.7))
        }
        .padding(.top, 4)
    }
}
