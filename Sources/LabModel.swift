import Foundation
import Combine
import CoreGraphics

struct LabConfig: Equatable {
    var presetID: String
    var customW: Int
    var customH: Int
    var basis: SizeBasis
    var vFOV: Double
    var fill: FillMode

    static let standard = LabConfig(presetID: "native",
                                    customW: 1600,
                                    customH: 1200,
                                    basis: .height,
                                    vFOV: 60,
                                    fill: .stretch)
}

final class LabModel: ObservableObject {
    @Published var display: DisplayInfo = .placeholder
    @Published var presetID: String = "native" { didSet { persist() } }
    @Published var customW: Int = 1600 { didSet { persist() } }
    @Published var customH: Int = 1200 { didSet { persist() } }
    @Published var basis: SizeBasis = .height { didSet { persist() } }
    @Published var vFOV: Double = 60 { didSet { persist() } }
    @Published var fill: FillMode = .stretch { didSet { persist() } }
    @Published private(set) var applied: LabConfig = LabConfig.standard
    @Published var toast: String? = nil
    @Published var didDetect = false

    private let store = UserDefaults.standard
    private var toastToken = 0

    init() {
        store.register(defaults: [
            "presetID": "native",
            "customW": 1600,
            "customH": 1200,
            "basis": SizeBasis.height.rawValue,
            "vFOV": 60.0,
            "fill": FillMode.stretch.rawValue
        ])
        load()
    }

    // MARK: - 持久化

    private func load() {
        presetID = store.string(forKey: "presetID") ?? "native"
        customW = store.integer(forKey: "customW")
        customH = store.integer(forKey: "customH")
        basis = SizeBasis(rawValue: store.string(forKey: "basis") ?? "height") ?? .height
        vFOV = store.double(forKey: "vFOV")
        fill = FillMode(rawValue: store.string(forKey: "fill") ?? "stretch") ?? .stretch

        if customW < 64 { customW = 1600 }
        if customH < 64 { customH = 1200 }
        if vFOV < 20 || vFOV > 120 { vFOV = 60 }

        applied = draftConfig
    }

    private func persist() {
        store.set(presetID, forKey: "presetID")
        store.set(customW, forKey: "customW")
        store.set(customH, forKey: "customH")
        store.set(basis.rawValue, forKey: "basis")
        store.set(vFOV, forKey: "vFOV")
        store.set(fill.rawValue, forKey: "fill")
    }

    // MARK: - 设备

    func refreshDisplay() {
        guard let info = DisplayProbe.detect() else { return }
        display = info
        didDetect = true
    }

    // MARK: - 当前草稿 / 已应用

    var draftConfig: LabConfig {
        LabConfig(presetID: presetID,
                  customW: customW,
                  customH: customH,
                  basis: basis,
                  vFOV: vFOV,
                  fill: fill)
    }

    var hasChanges: Bool { applied != draftConfig }

    var draftPlan: RenderPlan { plan(for: draftConfig) }
    var appliedPlan: RenderPlan { plan(for: applied) }

    func plan(for config: LabConfig) -> RenderPlan {
        LabMath.makePlan(panelLandscape: display.landscape,
                         targetAspect: aspect(for: config),
                         basis: config.basis,
                         vFOV: config.vFOV,
                         fill: config.fill)
    }

    func aspect(for config: LabConfig) -> Double {
        if config.presetID == "custom" {
            let w = Double(max(1, config.customW))
            let h = Double(max(1, config.customH))
            return max(w, h) / min(w, h)
        }
        if let preset = presetList.first(where: { $0.id == config.presetID }),
           let ratio = preset.ratio {
            return ratio
        }
        return display.aspect
    }

    func title(for config: LabConfig) -> String {
        if config.presetID == "custom" {
            return "\(config.customW):\(config.customH)"
        }
        if let preset = presetList.first(where: { $0.id == config.presetID }) {
            return preset.title
        }
        return "原生"
    }

    var draftTitle: String { title(for: draftConfig) }

    /// 自定义比例是否与面板比例一致
    var customIsNativeAspect: Bool {
        guard presetID == "custom" else { return true }
        return abs(aspect(for: draftConfig) - display.aspect) < 0.002
    }

    // MARK: - 操作

    func apply() {
        applied = draftConfig
        persist()
        let plan = appliedPlan
        showToast("已应用到本 App 预览：\(plan.renderLabel)")
    }

    func reset() {
        presetID = LabConfig.standard.presetID
        customW = LabConfig.standard.customW
        customH = LabConfig.standard.customH
        basis = LabConfig.standard.basis
        vFOV = LabConfig.standard.vFOV
        fill = LabConfig.standard.fill
        showToast("已恢复默认")
    }

    func bump(_ delta: Int, width: Bool) {
        if width {
            customW = min(8192, max(64, customW + delta))
        } else {
            customH = min(8192, max(64, customH + delta))
        }
    }

    func showToast(_ message: String) {
        toastToken += 1
        let token = toastToken
        toast = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            guard let self = self else { return }
            if self.toastToken == token {
                self.toast = nil
            }
        }
    }

    // MARK: - 导出文本

    func exportText() -> String {
        let config = applied
        let plan = appliedPlan
        let panelW = Double(plan.panelWidth)
        let nativeAt20 = LabMath.nativeHeadPixels(panelWidth: panelW,
                                                  hFOVPanel: plan.hFOVPanel,
                                                  distance: 20)
        let targetAt20 = LabMath.headPixels(renderWidth: Double(plan.renderWidth),
                                            hFOV: plan.hFOVRender,
                                            displayScaleX: plan.displayScaleX,
                                            distance: 20)

        var lines: [String] = []
        lines.append("AspectLab 读数")
        lines.append("设备：\(display.modelName)  \(display.machineID)")
        lines.append(String(format: "面板：%@  (%.3f:1)  %@", plan.panelLabel, plan.panelAspect, display.pointLabel))
        lines.append("显示缩放：\(display.zoomLabel)")
        lines.append("")
        lines.append("目标比例：\(title(for: config))  \(String(format: "%.4f:1", plan.targetAspect))")
        lines.append("渲染分辨率：\(plan.renderLabel)  (\(String(format: "%.2f", plan.renderMegapixels)) MP)")
        lines.append("铺满方式：\(plan.fill.title) → \(plan.fit.title)")
        lines.append(String(format: "横向倍率：×%.3f", plan.distortion))
        lines.append(String(format: "水平视野：%.1f° → %.1f°  (%.1f°)", plan.hFOVPanel, plan.hFOVRender, plan.hFOVDelta))
        lines.append(String(format: "垂直视野：%.1f°（不变）", plan.vFOV))
        lines.append(String(format: "头部像素 20m：%.1f → %.1f px", nativeAt20, targetAt20))
        lines.append(String(format: "像素负担：%.0f%%", plan.pixelRatio * 100))
        lines.append("")
        lines.append("参考（Android 才有此能力）：")
        lines.append("adb shell wm size \(plan.renderLabel)")
        lines.append("")
        lines.append("iOS 侧：UIScreen 仅暴露 availableModes/currentMode，无 setMode；")
        lines.append("本机未越狱，系统分辨率不可写。以上为换算，不可直接应用。")

        return lines.joined(separator: "\n")
    }
}
