import UIKit
import AVFoundation
import UserNotifications
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category.")
        }
        return true
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDailyKuralSettingChange), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    @objc private func handleDailyKuralSettingChange() {
        if AppState().isDailyKuralEnabled {
            NotificationManager.shared.scheduleRandomKuralNotification()
        } else {
            NotificationManager.shared.cancelAllNotifications()
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let kuralId = response.notification.request.content.userInfo["kuralId"] as? Int {
            NotificationCenter.default.post(name: Notification.Name("OpenKuralNotification"), object: nil, userInfo: ["kuralId": kuralId])
        }
        completionHandler()
    }
    
    private func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) async -> Bool { // Marked as async
        if userActivity.activityType == "com.devois.valluvan.goToKural",
           let kuralId = userActivity.userInfo?["kuralId"] as? Int {
            // Removed DispatchQueue.main.async as it's not needed in async context
            // Get the active window scene
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let contentView = window.rootViewController?.view as? ContentView {
                await contentView.handleSiriGoToKural(kuralId: kuralId) // Added await
            }
            return true
        }
        return false
    }
}
