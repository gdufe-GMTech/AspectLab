import SwiftUI

struct SetupView: View {
    @ObservedObject var model: LabModel

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                banner
                deviceCard
                presetCard
                if model.presetID == "custom" {
                    customCard
                }
                basisCard
                fovCard
                summaryCard
                applyBar
                Color.clear.frame(height: 6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .background(Theme.bg)
    }

    // MARK: - 顶栏声明

    private var banner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.warn)
                .padding(.top, 1)

            Text("iOS 不允许第三方 App 改写系统分辨率，「应用」只作用于本 App 内的模拟视图。这里做的是把改动量化清楚。")
                .font(.system(size: 11.5))
                .foregroundColor(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.warn.opacity(0.09))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.warn.opacity(0.28), lineWidth: 1)
        )
    }

    // MARK: - 设备

    private var deviceCard: some View {
        CardView {
            CardTitle(text: "设备面板")
            KeyValueRow(key: "机型", value: model.display.modelName)
            HairLine()
            KeyValueRow(key: "标识符", value: model.display.machineID)
            HairLine()
            KeyValueRow(key: "物理像素（横屏）", value: model.appliedPlan.panelLabel)
            HairLine()
            KeyValueRow(key: "面板比例", value: model.display.aspectLabel)
            HairLine()
            KeyValueRow(key: "逻辑分辨率", value: model.display.pointLabel)
            HairLine()
            KeyValueRow(key: "显示缩放",
                        value: model.display.zoomLabel,
                        tint: model.display.isZoomed ? Theme.warn : Theme.text)
        }
    }

    // MARK: - 比例预设

    private var presetCard: some View {
        CardView {
            CardTitle(text: "目标比例")

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(presetList) { preset in
                    presetChip(preset)
                }
            }

            Text("横向拉伸只改变物体宽度，命中箱与判定逻辑不受影响；4:3 的代价是两侧视野被切掉。")
                .font(.system(size: 11))
                .foregroundColor(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
    }

    private func presetChip(_ preset: AspectPreset) -> some View {
        let selected = model.presetID == preset.id
        return Button {
            model.presetID = preset.id
        } label: {
            VStack(spacing: 2) {
                Text(preset.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(selected ? Theme.bg : Theme.text)
                Text(ratioLabel(preset))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(selected ? Theme.bg.opacity(0.7) : Theme.dim)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(selected ? Theme.accent : Theme.cardAlt)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(selected ? Theme.accent : Theme.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func ratioLabel(_ preset: AspectPreset) -> String {
        if preset.id == "custom" {
            return String(format: "%.3f", model.aspect(for: model.draftConfig))
        }
        if let ratio = preset.ratio {
            return String(format: "%.3f", ratio)
        }
        return String(format: "%.3f", model.display.aspect)
    }

    // MARK: - 自定义

    private var customCard: some View {
        CardView {
            CardTitle(text: "自定义分辨率（横屏，宽 × 高）")
            stepperRow(label: "宽", value: model.customW, isWidth: true)
            HairLine()
            stepperRow(label: "高", value: model.customH, isWidth: false)

            if !model.customIsNativeAspect {
                Text(String(format: "该比例宽 %.3f，比面板 %.3f %@",
                            model.aspect(for: model.draftConfig),
                            model.display.aspect,
                            model.aspect(for: model.draftConfig) < model.display.aspect ? "更窄，需要横向拉伸" : "更宽，需要纵向压缩或裁切"))
                    .font(.system(size: 11))
                    .foregroundColor(Theme.warn.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }
        }
    }

    private func stepperRow(label: String, value: Int, isWidth: Bool) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.dim)
                .frame(width: 20, alignment: .leading)

            Text("\(value)")
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.text)
                .frame(minWidth: 66, alignment: .leading)

            Spacer(minLength: 6)

            stepButton("-10", delta: -10, isWidth: isWidth)
            stepButton("-1", delta: -1, isWidth: isWidth)
            stepButton("+1", delta: 1, isWidth: isWidth)
            stepButton("+10", delta: 10, isWidth: isWidth)
        }
        .padding(.vertical, 4)
    }

    private func stepButton(_ title: String, delta: Int, isWidth: Bool) -> some View {
        Button {
            model.bump(delta, width: isWidth)
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.text)
                .frame(width: 42, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.cardAlt)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 基准

    private var basisCard: some View {
        CardView {
            CardTitle(text: "渲染分辨率基准")
            Picker("基准", selection: $model.basis) {
                ForEach(SizeBasis.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Text("换算出游戏应当渲染的像素数。4:3 想铺满 19.5:9 面板，横向不够宽，只能压低渲染宽高比再拉伸。")
                .font(.system(size: 11))
                .foregroundColor(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
    }

    // MARK: - 垂直视野

    private var fovCard: some View {
        CardView {
            HStack {
                CardTitle(text: "游戏垂直视野")
                Spacer()
                Text(String(format: "%.0f°", model.vFOV))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.accent)
                    .padding(.bottom, 10)
            }
            Slider(value: $model.vFOV, in: 40...90, step: 1)
                .accentColor(Theme.accent)
            Text("多数手机 FPS 采用 Hor+ 视角：垂直视野固定，水平视野随宽高比变化。不确定就保持 60°。")
                .font(.system(size: 11))
                .foregroundColor(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 结果摘要

    private var summaryCard: some View {
        let plan = model.draftPlan
        return CardView {
            CardTitle(text: "换算结果（草稿）")
            KeyValueRow(key: "目标比例", value: String(format: "%.3f:1", plan.targetAspect))
            HairLine()
            KeyValueRow(key: "渲染分辨率", value: plan.renderLabel, tint: Theme.accent)
            HairLine()
            KeyValueRow(key: "铺满方式", value: plan.fit.title)
            HairLine()
            KeyValueRow(key: "横向倍率", value: String(format: "×%.3f", plan.distortion),
                        tint: plan.distortion > 1.001 ? Theme.warn : Theme.text)
            HairLine()
            KeyValueRow(key: "水平视野", value: String(format: "%.1f° → %.1f°", plan.hFOVPanel, plan.hFOVRender))
        }
    }

    // MARK: - 应用

    private var applyBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: model.hasChanges ? "circle.dashed" : "checkmark.circle")
                    .font(.system(size: 12))
                Text(model.hasChanges ? "有未应用的改动" : "当前配置已应用")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(model.hasChanges ? Theme.warn : Theme.accent)

            HStack(spacing: 10) {
                Button {
                    model.reset()
                } label: {
                    Text("重置")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.cardAlt)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    model.apply()
                } label: {
                    Text("应用")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.bg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(model.hasChanges ? Theme.accent : Theme.accent.opacity(0.5))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
    }
}
