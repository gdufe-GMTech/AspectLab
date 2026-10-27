import SwiftUI
import UIKit

@main
struct AspectLabApp: App {
    init() {
        configureBars()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func configureBars() {
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Theme.bg)
        tab.shadowColor = UIColor(Theme.line)
        tab.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.dim)
        tab.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.dim)
        ]
        tab.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.accent)
        tab.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.accent)
        ]
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}
