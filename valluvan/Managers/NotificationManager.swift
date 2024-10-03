import Foundation
import UserNotifications
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var selectedTime: Date = Date() {
        didSet {
            let calendar = Calendar.current
            hour = calendar.component(.hour, from: selectedTime)
            minute = calendar.component(.minute, from: selectedTime)
        }
    }
    
    @Published var hour: Int = 9
    @Published var minute: Int = 0
    
    private init() { 
        let calendar = Calendar.current
        let now = Date()
        hour = calendar.component(.hour, from: now)
        minute = calendar.component(.minute, from: now)
        selectedTime = now
    }
    
    func scheduleRandomKuralNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.scheduleNotification()
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func scheduleNotification() {
        guard AppState().isDailyKuralEnabled else {
            print("Daily Kural notifications are disabled")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Daily Thirukkural"
        
        let randomKuralId = Int.random(in: 1...1330)
        if let kural = DatabaseManager.shared.getKuralById(randomKuralId, language: "English") {
            content.body = "\(randomKuralId). \(kural.content)\n\nTap to read more..."
            content.userInfo = ["kuralId": randomKuralId]
        } else {
            content.body = "Discover today's wisdom from Thirukkural"
        }
        
        content.sound = UNNotificationSound.default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailyKural", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
