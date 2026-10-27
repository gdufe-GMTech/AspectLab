import SwiftUI

enum Theme {
    static let bg = Color(red: 0.043, green: 0.055, blue: 0.075)
    static let card = Color(red: 0.078, green: 0.098, blue: 0.125)
    static let cardAlt = Color(red: 0.106, green: 0.129, blue: 0.161)
    static let line = Color(red: 0.160, green: 0.190, blue: 0.230)
    static let text = Color(red: 0.930, green: 0.950, blue: 0.970)
    static let dim = Color(red: 0.560, green: 0.610, blue: 0.670)
    static let accent = Color(red: 0.200, green: 0.840, blue: 0.650)
    static let warn = Color(red: 0.980, green: 0.700, blue: 0.280)
    static let danger = Color(red: 0.950, green: 0.380, blue: 0.380)

    static let skyTop = Color(red: 0.078, green: 0.145, blue: 0.196)
    static let skyBottom = Color(red: 0.176, green: 0.278, blue: 0.302)
    static let groundTop = Color(red: 0.145, green: 0.196, blue: 0.176)
    static let groundBottom = Color(red: 0.086, green: 0.118, blue: 0.114)
}

struct CardView<Content: View>: View {
    var padding: CGFloat = 14
    let content: Content

    init(padding: CGFloat = 14, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.line, lineWidth: 1)
        )
    }
}

struct CardTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .tracking(1.2)
            .foregroundColor(Theme.dim)
            .padding(.bottom, 10)
    }
}

struct KeyValueRow: View {
    let key: String
    let value: String
    var tint: Color = Theme.text

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(key)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.dim)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(tint)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 5)
    }
}

struct HairLine: View {
    var body: some View {
        Rectangle()
            .fill(Theme.line)
            .frame(height: 1)
    }
}
