import Foundation
import CoreGraphics

// MARK: - 铺满方式

enum FillMode: String, CaseIterable, Identifiable {
    case stretch
    case fit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stretch: return "拉伸铺满"
        case .fit: return "保持比例"
        }
    }

    var detail: String {
        switch self {
        case .stretch: return "横向撑满面板，物体变宽，无黑边"
        case .fit: return "等比缩放，两侧留黑边，物体不变形"
        }
    }
}

// MARK: - 渲染分辨率基准

enum SizeBasis: String, CaseIterable, Identifiable {
    case height
    case width
    case area

    var id: String { rawValue }

    var title: String {
        switch self {
        case .height: return "高度"
        case .width: return "宽度"
        case .area: return "像素量"
        }
    }
}

// MARK: - 变形行为

enum FitBehavior: String {
    case exact
    case horizontalStretch
    case verticalStretch
    case letterbox

    var title: String {
        switch self {
        case .exact: return "无变形"
        case .horizontalStretch: return "横向拉伸"
        case .verticalStretch: return "纵向压缩"
        case .letterbox: return "等比 + 黑边"
        }
    }

    var isStretched: Bool {
        self == .horizontalStretch || self == .verticalStretch
    }
}

// MARK: - 比例预设

struct AspectPreset: Identifiable, Equatable {
    let id: String
    let title: String
    let ratio: Double?
}

let presetList: [AspectPreset] = [
    AspectPreset(id: "native", title: "原生", ratio: nil),
    AspectPreset(id: "r16x9", title: "16:9", ratio: 16.0 / 9.0),
    AspectPreset(id: "r16x10", title: "16:10", ratio: 1.6),
    AspectPreset(id: "r3x2", title: "3:2", ratio: 1.5),
    AspectPreset(id: "r4x3", title: "4:3", ratio: 4.0 / 3.0),
    AspectPreset(id: "r21x9", title: "21:9", ratio: 21.0 / 9.0),
    AspectPreset(id: "custom", title: "自定义", ratio: nil)
]

// MARK: - 设备面板信息

struct DisplayInfo: Equatable {
    var pixelSize: CGSize
    var pointSize: CGSize
    var scale: CGFloat
    var nativeScale: CGFloat
    var modelName: String
    var machineID: String
    var source: String

    static let placeholder = DisplayInfo(
        pixelSize: CGSize(width: 1206, height: 2622),
        pointSize: CGSize(width: 402, height: 874),
        scale: 3,
        nativeScale: 3,
        modelName: "iPhone（未探测到）",
        machineID: "-",
        source: "fallback"
    )

    /// 统一按横屏处理：长边 × 短边
    var landscape: CGSize {
        CGSize(width: max(pixelSize.width, pixelSize.height),
               height: min(pixelSize.width, pixelSize.height))
    }

    var aspect: Double {
        landscape.height > 1 ? Double(landscape.width / landscape.height) : 2.0
    }

    var pointLabel: String {
        "\(Int(pointSize.width.rounded()))×\(Int(pointSize.height.rounded())) pt"
    }

    var pixelSizeLabel: String {
        "\(Int(pixelSize.width.rounded()))×\(Int(pixelSize.height.rounded()))"
    }

    var scaleLabel: String {
        String(format: "%.2f/%.2f", Double(scale), Double(nativeScale))
    }

    /// nativeScale 与 scale 不一致 => 系统启用过显示缩放
    var isZoomed: Bool {
        abs(Double(nativeScale) - Double(scale)) > 0.01
    }

    var zoomLabel: String {
        isZoomed ? "已开启" : "未开启"
    }

    var aspectLabel: String {
        String(format: "%.3f:1", aspect)
    }
}

// MARK: - 换算结果

struct RenderPlan {
    var panel: CGSize
    var panelAspect: Double
    var targetAspect: Double
    var render: CGSize
    var renderAspect: Double
    var vFOV: Double
    var hFOVPanel: Double
    var hFOVRender: Double
    var displayScaleX: Double
    var displayScaleY: Double
    var fit: FitBehavior
    var basis: SizeBasis
    var fill: FillMode

    var panelWidth: Int { Int(panel.width.rounded()) }
    var panelHeight: Int { Int(panel.height.rounded()) }
    var renderWidth: Int { Int(render.width.rounded()) }
    var renderHeight: Int { Int(render.height.rounded()) }

    var panelLabel: String { "\(panelWidth)×\(panelHeight)" }
    var renderLabel: String { "\(renderWidth)×\(renderHeight)" }

    /// 物体横向相对纵向的放大倍数（1.0 = 不变形）
    var distortion: Double {
        displayScaleY > 0.0001 ? displayScaleX / displayScaleY : 1.0
    }

    var hFOVDelta: Double { hFOVRender - hFOVPanel }

    /// 目标比例相对面板比例保留下来的横向视野
    var fovKeepRatio: Double {
        min(1.0, max(0.0, targetAspect / panelAspect))
    }

    /// 渲染像素量 / 面板像素量
    var pixelRatio: Double {
        let r = Double(render.width * render.height)
        let p = Double(panel.width * panel.height)
        return p > 0 ? r / p : 1.0
    }

    var renderMegapixels: Double {
        Double(render.width * render.height) / 1_000_000.0
    }
}

// MARK: - 换算

enum LabMath {
    static func clampedRenderSize(panelW: Double, panelH: Double, aspect: Double, basis: SizeBasis) -> CGSize {
        var w = 0.0
        var h = 0.0

        switch basis {
        case .height:
            h = panelH
            w = (panelH * aspect).rounded()
        case .width:
            w = panelW
            h = (panelW / aspect).rounded()
        case .area:
            let area = panelW * panelH
            h = (area / aspect).squareRoot().rounded()
            w = (h * aspect).rounded()
        }

        if w > panelW {
            w = panelW
            h = (panelW / aspect).rounded()
        }
        if h > panelH {
            h = panelH
            w = (panelH * aspect).rounded()
        }

        return CGSize(width: max(w, 2), height: max(h, 2))
    }

    static func makePlan(panelLandscape: CGSize,
                         targetAspect: Double,
                         basis: SizeBasis,
                         vFOV: Double,
                         fill: FillMode) -> RenderPlan {
        let pw = Double(panelLandscape.width)
        let ph = Double(panelLandscape.height)
        let panelAspect = ph > 0 ? pw / ph : 2.0
        let safeAspect = max(0.25, min(targetAspect, 6.0))
        let rs = clampedRenderSize(panelW: pw, panelH: ph, aspect: safeAspect, basis: basis)
        let rw = Double(rs.width)
        let rh = Double(rs.height)
        let rA = rh > 0 ? rw / rh : safeAspect

        let vDeg = max(20.0, min(vFOV, 120.0))
        let tanHalfV = tan(vDeg * Double.pi / 360.0)
        let hPanel = 2.0 * atan(tanHalfV * panelAspect) * 180.0 / Double.pi
        let hRender = 2.0 * atan(tanHalfV * rA) * 180.0 / Double.pi

        var sx = 1.0
        var sy = 1.0
        var fit: FitBehavior = .exact

        if fill == .stretch {
            sx = rw > 0 ? pw / rw : 1.0
            sy = rh > 0 ? ph / rh : 1.0
            let delta = sx - sy
            if abs(delta) < 0.0005 {
                fit = .exact
            } else if delta > 0 {
                fit = .horizontalStretch
            } else {
                fit = .verticalStretch
            }
        } else {
            let s = min(rw > 0 ? pw / rw : 1.0, rh > 0 ? ph / rh : 1.0)
            sx = s
            sy = s
            fit = .letterbox
        }

        return RenderPlan(panel: panelLandscape,
                          panelAspect: panelAspect,
                          targetAspect: safeAspect,
                          render: rs,
                          renderAspect: rA,
                          vFOV: vDeg,
                          hFOVPanel: hPanel,
                          hFOVRender: hRender,
                          displayScaleX: sx,
                          displayScaleY: sy,
                          fit: fit,
                          basis: basis,
                          fill: fill)
    }

    /// 头部在屏幕上的像素宽度（等距投影近似）
    static func headPixels(renderWidth: Double,
                           hFOV: Double,
                           displayScaleX: Double,
                           distance: Double,
                           radius: Double = 0.11) -> Double {
        let half = hFOV * Double.pi / 360.0
        let t = tan(half)
        guard t > 0.0001, distance > 0.01 else { return 0 }
        return renderWidth * (radius / distance) / t * displayScaleX
    }

    /// 面板原生状态下头部像素宽度
    static func nativeHeadPixels(panelWidth: Double,
                                 hFOVPanel: Double,
                                 distance: Double,
                                 radius: Double = 0.11) -> Double {
        let half = hFOVPanel * Double.pi / 360.0
        let t = tan(half)
        guard t > 0.0001, distance > 0.01 else { return 0 }
        return panelWidth * (radius / distance) / t
    }
}
