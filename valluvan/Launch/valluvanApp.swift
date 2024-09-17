//
//  valluvanApp.swift
//  valluvan
//
//  Created by DevarajNS on 9/12/24.
//

import SwiftUI
import SQLite3

@main
struct ValluvanApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @State private var notificationKuralId: Int?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenKuralNotification"))) { notification in
                    if let kuralId = notification.userInfo?["kuralId"] as? Int {
                        notificationKuralId = kuralId
                    }
                }
                .environment(\.notificationKuralId, $notificationKuralId)
        }
    }
}

private struct NotificationKuralIdKey: EnvironmentKey {
    static let defaultValue: Binding<Int?> = .constant(nil)
}

extension EnvironmentValues {
    var notificationKuralId: Binding<Int?> {
        get { self[NotificationKuralIdKey.self] }
        set { self[NotificationKuralIdKey.self] = newValue }
    }
}
