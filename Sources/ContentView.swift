import SwiftUI

struct ContentView: View {
    @StateObject private var model = LabModel()
    @State private var selection: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                SetupView(model: model)
                    .tabItem { Label("分辨率", systemImage: "aspectratio") }
                    .tag(0)

                PreviewView(model: model)
                    .tabItem { Label("预览", systemImage: "eye") }
                    .tag(1)

                MetricsView(model: model)
                    .tabItem { Label("数据", systemImage: "chart.bar") }
                    .tag(2)

                ForensicsView(model: model)
                    .tabItem { Label("取证", systemImage: "magnifyingglass") }
                    .tag(3)
            }
            .accentColor(Theme.accent)
            .onAppear {
                model.refreshDisplay()
            }

            if let toast = model.toast {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text(toast)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Theme.cardAlt)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Theme.line, lineWidth: 1)
                )
                .padding(.bottom, 78)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: model.toast)
        .preferredColorScheme(.dark)
        .background(Theme.bg.ignoresSafeArea())
    }
}
