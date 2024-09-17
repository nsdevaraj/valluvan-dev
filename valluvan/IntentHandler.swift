import Intents

class IntentHandler: INExtension, GoToKuralIntentHandling {
    func handle(intent: GoToKuralIntent, completion: @escaping (GoToKuralIntentResponse) -> Void) {
        guard let kuralId = intent.kuralId?.intValue else {
            completion(GoToKuralIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        let userActivity = NSUserActivity(activityType: "com.devois.valluvan.goToKural")
        userActivity.userInfo = ["kuralId": kuralId]
        
        completion(GoToKuralIntentResponse(code: .success, userActivity: userActivity))
    }
}