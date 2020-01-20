import UIKit

struct Constants {
    struct Keys {
        // Keys for user data in NSUserDefaults.
        static let kFirstNameDefaultsKey = "kFirstNameDefaultsKey"
        static let kLastNameDefaultsKey = "kLastNameDefaultsKey"
        static let kEmailDefaultsKey = "kEmailDefaultsKey"
        static let kUserAgreementAcceptedDefaultsKey = "kUserAgreementAcceptedDefaultsKey"

        static let kLastSendDateDefaultsKey = "kLastSendDateDefaultsKey"

        // Notification keys.
        static let kDateSelectedNotificationKey = "kDateSelectedNotificationKey"
        static let kEELocalNotificationReceivedKey = "kEELocalNotificationReceivedKey"

        struct TrackingState {
            static let kDateStartKey = "kDateStartKey"
            static let kDateEndKey = "kDateEndKey"
            static let kPauseValueKey = "kPauseValueKey"
            static let kPauseStartKey = "kPauseStartKey"
            static let kCurrentStateKey = "kCurrentStateKey"
        }
    }

    static let kAppTintColor = UIColor(red:0, green:0.73, blue:0.88, alpha:1)
    static let kAppBackgroundColor = UIColor(red: 245/255, green: 248/255, blue: 249/255, alpha: 1)
    static let kTextColor = UIColor(red:0.4, green:0.4, blue:0.4, alpha:1)
}
