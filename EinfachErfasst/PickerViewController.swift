import UIKit

enum DateStateIdentifier: Int {
    case start, end, pause
}

class PickerViewController: UIViewController {

    // MARK: - IBActions

    @IBAction func doneAction(_ sender: AnyObject) {
        if dateState == .start || dateState == .end {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Keys.kDateSelectedNotificationKey), object: datePicker.date)
        } else {
            let date = datePicker.date
            let calendar = Calendar.current
            let unitFlags: NSCalendar.Unit = [NSCalendar.Unit.hour, NSCalendar.Unit.minute]
            let components = (calendar as NSCalendar).components(unitFlags, from: date)
            let minutesInterval = components.minute! * 60
            let hoursInterval = components.hour! * 3600
            let newPauseValue = minutesInterval + hoursInterval

            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Keys.kDateSelectedNotificationKey), object: NSNumber(value: Double(newPauseValue) as Double))
        }
        self.dismiss(animated: false, completion: nil)
    }

    // MARK: - IBOutlets
    @IBOutlet weak var doneButtonItem: UIBarButtonItem!
    @IBOutlet weak var datePicker: UIDatePicker!

    // MARK: - Properties

    var dateMode: Bool = true
    var dateToShow: Date? {
        didSet {
            if datePicker != nil {
                self.setDateSelectionState()
            }
        }
    }
    var intervalToShow: TimeInterval = 0 {
        didSet {
            self.setPauseSelectionState()
        }
    }
    var dateState: DateStateIdentifier = .start

    var maxDate: Date?
    var minDate: Date?


    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.view.backgroundColor = UIColor.clear

        datePicker.locale = Locale(identifier: "DE")

        if dateMode {
            self.setDateSelectionState()
        } else {
            self.setPauseSelectionState()
        }
    }

    func setDateSelectionState() {
        self.dateState = .start
        datePicker.datePickerMode = UIDatePickerMode.dateAndTime
        if let date = dateToShow {
            datePicker.date = date
        } else {
            datePicker.date = Date()
        }

        let calendar = Calendar.current
        let unitFlags: NSCalendar.Unit = [NSCalendar.Unit.second]
        let components = (calendar as NSCalendar).components(unitFlags, from:datePicker.date)
        datePicker.date = datePicker.date.addingTimeInterval(Double(-components.second!))

        datePicker.maximumDate = maxDate
        datePicker.minimumDate = minDate
    }

    func setPauseSelectionState() {
        self.dateState = .pause
        if let datePicker = self.datePicker {
            datePicker.datePickerMode = UIDatePickerMode.time

            var components = DateComponents()

            // Fast way to convert interval to minutes and hours.
            let interval = Int(intervalToShow)
            let minutes = (interval / 60) % 60;
            let hours = (interval / 3600);

            components.minute = minutes
            components.hour = hours

            let calendar = Calendar.current
            datePicker.date = calendar.date(from: components)!
        }
    }
}
