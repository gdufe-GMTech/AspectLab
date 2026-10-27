import UIKit
import Foundation

enum DisplayProbe {
    static func detect() -> DisplayInfo? {
        guard let screen = activeScreen() else { return nil }

        let nativeSize = screen.nativeBounds.size
        let pointSize = screen.bounds.size
        let scale = screen.scale

        let pixels: CGSize
        if nativeSize.width > 1 && nativeSize.height > 1 {
            pixels = nativeSize
        } else {
            pixels = CGSize(width: pointSize.width * scale,
                            height: pointSize.height * scale)
        }

        let machine = machineIdentifier()

        return DisplayInfo(pixelSize: pixels,
                           pointSize: pointSize,
                           scale: scale,
                           nativeScale: screen.nativeScale,
                           modelName: friendlyName(for: machine),
                           machineID: machine,
                           source: "UIScreen")
    }

    private static func activeScreen() -> UIScreen? {
        let scenes = UIApplication.shared.connectedScenes
        var fallback: UIScreen?

        for scene in scenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            if windowScene.activationState == .foregroundActive {
                return windowScene.screen
            }
            if fallback == nil {
                fallback = windowScene.screen
            }
        }

        return fallback
    }

    private static func machineIdentifier() -> String {
        var info = utsname()
        uname(&info)
        let text: String = withUnsafeBytes(of: &info.machine) { raw -> String in
            let bytes = raw.prefix { $0 != 0 }
            return String(decoding: Array(bytes), as: UTF8.self)
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "unknown" : trimmed
    }

    private static func friendlyName(for machine: String) -> String {
        let table: [String: String] = [
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",
            "iPhone17,5": "iPhone 16e"
        ]
        if let name = table[machine] {
            return name
        }
        return "未收录机型（\(machine)）"
    }
}
