import Foundation
import Combine
import CoreGraphics

struct DisplaySample: Identifiable {
    let id = UUID()
    let time: Date
    let pixel: CGSize
    let point: CGSize
    let scale: CGFloat
    let nativeScale: CGFloat
    let label: String

    init(time: Date, display: DisplayInfo, label: String) {
        self.time = time
        self.pixel = display.pixelSize
        self.point = display.pointSize
        self.scale = display.scale
        self.nativeScale = display.nativeScale
        self.label = label
    }

    var pixelLabel: String {
        "\(Int(pixel.width.rounded()))×\(Int(pixel.height.rounded()))"
    }

    var pointLabel: String {
        "\(Int(point.width.rounded()))×\(Int(point.height.rounded())) pt"
    }

    var scaleLabel: String {
        String(format: "%.2f/%.2f", Double(scale), Double(nativeScale))
    }

    var signature: String {
        pixelLabel + "|" + pointLabel + "|" + scaleLabel
    }

    var timeLabel: String {
        DisplaySample.formatter.string(from: time)
    }

    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

/// 只读采样器：按秒读取 UIScreen，只在数值变化时记一条。
/// 它不改任何东西，作用是把「系统分辨率到底变没变」变成可对照的记录。
final class DisplayLogger: ObservableObject {
    @Published private(set) var samples: [DisplaySample] = []
    @Published private(set) var baseline: DisplaySample?
    @Published private(set) var isWatching = false

    private var timer: Timer?

    var latest: DisplaySample? { samples.first }

    func markBaseline() {
        sample(label: "基线", force: true)
        baseline = samples.first
    }

    func sampleNow() {
        sample(label: "手动", force: true)
    }

    func toggleWatch() {
        if isWatching {
            stop()
        } else {
            start()
        }
    }

    func start() {
        guard timer == nil else { return }
        isWatching = true
        sample(label: "开始", force: true)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.sample(label: "变化", force: false)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isWatching = false
    }

    func clear() {
        samples.removeAll()
        baseline = nil
    }

    private func sample(label: String, force: Bool) {
        guard let detected = DisplayProbe.detect() else { return }
        let item = DisplaySample(time: Date(), display: detected, label: label)
        if !force, let last = samples.first, last.signature == item.signature {
            return
        }
        samples.insert(item, at: 0)
        if samples.count > 30 {
            samples.removeLast(samples.count - 30)
        }
    }
}
