import UIKit

protocol EEPauseAdjustmentDelegate {
    func confirmAutomaticPauseAdjustment() -> ()
    func rejectAutomaticPauseAdjustment() -> ()
}

class EEBaseTrackingViewController: UIViewController, EEPauseAdjustmentDelegate {
    // MARK: - Properties

    var dateStart: Date?
    var dateEnd: Date?
    var pauseValue: TimeInterval = 0
    var automaticallyAdjustedPauseValue: TimeInterval = 0

    // MARK: - Methods
    func showPauseWarningController() -> Bool {

        var difference = dateEnd!.timeIntervalSince(dateStart!)
        difference = ceil(difference)

        var imagineDate = Date(timeInterval: difference, since: dateStart!)

        let calendar = Calendar.current
        let calendarUnits: NSCalendar.Unit = [NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second]
        let components = (calendar as NSCalendar).components(calendarUnits, from: dateStart!, to: imagineDate, options: [])

        let now = Date()

        imagineDate = Date(timeInterval: pauseValue, since: now)

        let pauseCalendarUnits = NSCalendar.Unit.minute
        let pauseComponents = (calendar as NSCalendar).components(pauseCalendarUnits, from: now, to: imagineDate, options: [])

        let pauseMinutes = pauseComponents.minute

        // Logic goes there:
        var neededPause: Int = 0
        var minimumPauseMinutes: Int = 0
        var hoursValue: Int = 0
        if workedMoreThan9Hours(components) {
            neededPause = 45
            hoursValue = 9
            if components.hour! > 9 {
                minimumPauseMinutes = 45
            } else {
                if components.minute! < 31 {
                    neededPause = 30
                    minimumPauseMinutes = 30
                } else {
                    minimumPauseMinutes = components.minute! < 45 ? components.minute! : 45
                }
            }
        } else if workedMoreThan6Hours(components) {
            neededPause = 30
            hoursValue = 6
            if components.hour! > 6 {
                minimumPauseMinutes = 30
            } else {
                minimumPauseMinutes = components.minute! < 30 ? components.minute! : 30
            }
        } else {
            // No pause needed
            return false
        }

        if minimumPauseMinutes > pauseMinutes! {
            // Adjust pause time:
            let newPauseValue = minimumPauseMinutes * 60
            automaticallyAdjustedPauseValue = Double(newPauseValue)

            let pauseWarningController = self.storyboard?.instantiateViewController(withIdentifier: "pausewarningcontroller") as! PauseWarningController
            pauseWarningController.pauseAdjustmentDelegate = self
            self.tabBarController?.definesPresentationContext = true
            if #available(iOS 8.0, *) {
                pauseWarningController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            } else {
                // Fallback on earlier versions
            }

            pauseWarningController.hoursValue = hoursValue
            pauseWarningController.pauseMinutesValue = pauseMinutes!
            pauseWarningController.neededPauseMinutesValue = neededPause
            self.tabBarController?.present(pauseWarningController, animated: true, completion: nil)
            return true
        }

        return false
    }

    // MARK: - EEPauseAdjustmentDelegate methods
    func confirmAutomaticPauseAdjustment() {
        // Override required.
    }

    func rejectAutomaticPauseAdjustment() {
        // Override required.
    }
}
