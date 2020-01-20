import UIKit

func isAtLeastIOS8() -> Bool {
    switch UIDevice.current.systemVersion.compare("8.0.0", options: NSString.CompareOptions.numeric) {
    case .orderedSame, .orderedDescending:
        return true
    case .orderedAscending:
        return false
    }
}

func workedMoreThan9Hours(_ workedHoursComponents: DateComponents) -> Bool {
    let hours = workedHoursComponents.hour
    let minutes = workedHoursComponents.minute
    if hours! > 9 {
        return true
    } else if (hours! == 9) && (minutes! > 0) {
        return true
    }
    return false
}

func workedMoreThan6Hours(_ workdedHoursComponents: DateComponents) -> Bool {
    let hours = workdedHoursComponents.hour
    let minutes = workdedHoursComponents.minute
    if hours! > 6 {
        return true
    } else if (hours! == 6) && (minutes! > 0) {
        return true
    }
    return false
}

func backBarButtonItemWithTarget(_ target: AnyObject?, action: Selector) -> UIBarButtonItem {
    let backButton = UIButton()
    backButton.setTitle("zurück", for: UIControlState())
    backButton.setTitleColor(Constants.kAppTintColor, for: UIControlState())
    backButton.titleLabel?.font = UIFont(name: "BundesSansWeb", size: 18)
    backButton.setImage(UIImage(named: "back-icon"), for: UIControlState())
    backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
    backButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
    backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
    backButton.sizeToFit()
    backButton.addTarget(target, action: action, for: UIControlEvents.touchUpInside)
    let backItem = UIBarButtonItem(customView: backButton)
    return backItem
}

func updateLastSendDate() {
    let defaults = UserDefaults.standard
    defaults.set(Date(), forKey: Constants.Keys.kLastSendDateDefaultsKey)
    defaults.synchronize()
}
