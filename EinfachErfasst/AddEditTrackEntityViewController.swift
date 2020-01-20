import UIKit
import CoreData

class AddEditTrackEntityViewController: EEBaseTrackingViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var beginDateLabel: UILabel!
    @IBOutlet weak var beginTimeLabel: UILabel!

    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!

    @IBOutlet weak var pauseTimeLabel: UILabel!
    @IBOutlet weak var totalHoursLabel: UILabel!

    @IBOutlet var separatorHeightConstraints: [NSLayoutConstraint]!

    // MARK: - IBActions
    @IBAction func saveAction(_ sender: AnyObject) {
        // Save here
        if !self.isDataValid() {
           return
        }
        if self.showPauseWarningController() {
            return
        }

        self.saveData()
    }


    @IBAction func changeBeginTimeAction(_ sender: AnyObject) {
        if pickerViewController == nil {
            pickerViewController = self.storyboard?.instantiateViewController(withIdentifier: "PickerViewController") as? PickerViewController
        }
        pickerViewController!.dateMode = true
        pickerViewController!.dateToShow = dateStart
        self.lastSelectedDateState = .start

        if #available(iOS 8.0, *) {
            self.tabBarController?.definesPresentationContext = true
            pickerViewController!.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.tabBarController?.present(pickerViewController!, animated: true, completion: nil)
        } else {
            pickerViewController!.transitioningDelegate = transitionDelegate
            pickerViewController!.modalPresentationStyle = UIModalPresentationStyle.custom
            self.navigationController?.present(pickerViewController!, animated: true, completion: nil)
        }
    }

    @IBAction func changeEndTimeAction(_ sender: AnyObject) {
        if pickerViewController == nil {
            pickerViewController = self.storyboard?.instantiateViewController(withIdentifier: "PickerViewController") as? PickerViewController
        }
        pickerViewController!.dateMode = true
        pickerViewController!.dateToShow = dateEnd
        self.lastSelectedDateState = .end

        if #available(iOS 8.0, *) {
            self.tabBarController?.definesPresentationContext = true
            pickerViewController!.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.tabBarController?.present(pickerViewController!, animated: true, completion: nil)
        } else {
            pickerViewController!.transitioningDelegate = transitionDelegate
            pickerViewController!.modalPresentationStyle = UIModalPresentationStyle.custom
            self.navigationController?.present(pickerViewController!, animated: true, completion: nil)
        }
    }

    @IBAction func changePauseTimeAction(_ sender: AnyObject) {
        if pickerViewController == nil {
            pickerViewController = self.storyboard?.instantiateViewController(withIdentifier: "PickerViewController") as? PickerViewController
        }
        pickerViewController!.dateMode = false
        pickerViewController!.intervalToShow = pauseValue
        self.lastSelectedDateState = .pause

        if #available(iOS 8.0, *) {
            self.tabBarController?.definesPresentationContext = true
            pickerViewController!.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.tabBarController?.present(pickerViewController!, animated: true, completion: nil)
        } else {
            pickerViewController!.transitioningDelegate = transitionDelegate
            pickerViewController!.modalPresentationStyle = UIModalPresentationStyle.custom
            self.navigationController?.present(pickerViewController!, animated: true, completion: nil)
        }
    }

    // MARK: - Properties
    let transitionDelegate = TransitionDelegate()
    var pickerViewController: PickerViewController?

    var trackEntity: TrackEntity?

    var dateFormatter: DateFormatter = DateFormatter()
    var timeFormatter: DateFormatter = DateFormatter()

    var lastSelectedDateState: DateStateIdentifier = .start

    // MARK: - Methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.navigationBar.tintColor = Constants.kAppTintColor
        self.navigationController?.navigationBar.barTintColor = UIColor.white
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        for constraint in separatorHeightConstraints {
            constraint.constant = 1 / UIScreen.main.scale
        }
        NotificationCenter.default.addObserver(self, selector: #selector(AddEditTrackEntityViewController.dateSelected(_:)), name: NSNotification.Name(rawValue: Constants.Keys.kDateSelectedNotificationKey), object: nil)

        dateFormatter.dateFormat = "EEE, dd.MM."
        dateFormatter.locale = Locale(identifier: "DE")
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "DE")

        if self.trackEntity == nil {
            self.setAddState()
        } else {
            self.setEditState()
        }
    }

    func isDataValid() -> Bool {
        if let dateStart = dateStart, let dateEnd = dateEnd {
            if dateStart.compare(dateEnd as Date) == ComparisonResult.orderedDescending { // endTime before startTime
                self.showValidationAlert("Anfangszeit sollte vor der Endzeit liegen.")
                return false
            } else {
                var workInterval = dateEnd.timeIntervalSince(dateStart as Date)
                workInterval -= pauseValue
                if workInterval < 0 {
                    self.showValidationAlert("Die Pausenzeit ist länger als die Gesamtzeit.")
                    return false // pause interval is to long.
                }
            }
        } else {
            // dateStart or dateEnd is not set yet.
            self.showValidationAlert("Anfangs- oder Endzeit sind nicht gesetzt.")
            return false
        }
        return true
    }

    func showValidationAlert(_ message: String) {
        let alertView = UIAlertView(title: "Warnung", message: message, delegate: nil, cancelButtonTitle: "OK")
        alertView.show()
    }

    @objc func dateSelected(_ notification: Notification) {
        self.tabBarController?.tabBar.isHidden = false
        // determine which date was selected:
        switch self.lastSelectedDateState {
        case .start:
            let newDate = notification.object as! Date
            self.dateStart = newDate
            self.setBeginTime()
        case .end:
            let newDate = notification.object as! Date
            self.dateEnd = newDate
            self.setEndTime()
        case .pause:
            let newPause = notification.object as! NSNumber
            self.pauseValue = newPause.doubleValue
            self.updatePauseTimeLabel()
        }

        self.updateTotalHoursLabel()
    }

    func setAddState() {
        totalHoursLabel.text = "00:00 h"
        beginDateLabel.text = ""
        beginTimeLabel.text = ""

        endDateLabel.text = ""
        endTimeLabel.text = ""

        pauseTimeLabel.text = "00:00"
    }

    func setEditState() {
        dateStart = trackEntity?.dateStart
        dateEnd = trackEntity?.dateEnd
        pauseValue = trackEntity!.pause.doubleValue

        self.setBeginTime()
        self.setEndTime()
        self.updateTotalHoursLabel()
        self.updatePauseTimeLabel()
    }

    func setBeginTime() {
        var beginDateString = dateFormatter.string(from: dateStart! as Date)
        // Remove trailing dot from day of week.
        beginDateString = beginDateString.replacingOccurrences(of: ".,", with: ",", options: NSString.CompareOptions.literal, range: nil)

        beginDateLabel.text = beginDateString
        beginTimeLabel.text = timeFormatter.string(from: dateStart! as Date)
    }

    func setEndTime() {
        var endDateString = dateFormatter.string(from: dateEnd! as Date)
        // Remove trailing dot from day of week.
        endDateString = endDateString.replacingOccurrences(of: ".,", with: ",", options: NSString.CompareOptions.literal, range: nil)

        endDateLabel.text = endDateString
        endTimeLabel.text = timeFormatter.string(from: dateEnd! as Date)
    }

    func updateTotalHoursLabel() {
        if dateStart != nil && dateEnd != nil {
            var difference = dateEnd!.timeIntervalSince(dateStart! as Date)
            difference = ceil(difference)
            difference -= pauseValue
            let imagineDate = Date(timeInterval: difference, since: dateStart! as Date)

            let calendar = Calendar.current
            let calendarUnits: NSCalendar.Unit = [NSCalendar.Unit.hour, NSCalendar.Unit.minute]
            let components = (calendar as NSCalendar).components(calendarUnits, from: dateStart! as Date, to: imagineDate, options: [])

            self.totalHoursLabel.text = String(format: "%02d:%02d h", components.hour!, components.minute!)
        }
    }

    func updatePauseTimeLabel() {
        let now = Date()
        let imagineDate = Date(timeInterval: pauseValue, since: now)

        let calendar = Calendar.current
        let calendarUnits: NSCalendar.Unit = [NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second]
        let components = (calendar as NSCalendar).components(calendarUnits, from: now, to: imagineDate, options: [])

        let resultDate = calendar.date(from: components)
        self.pauseTimeLabel.text = timeFormatter.string(from: resultDate!)
    }

    func saveData() {
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext!
        if self.trackEntity == nil {
            let newItem = NSEntityDescription.insertNewObject(forEntityName: "TrackEntity", into: context) as! TrackEntity
            newItem.dateStart = dateStart!
            newItem.dateEnd = dateEnd!
            newItem.pause = NSNumber(value: self.pauseValue as Double)
            newItem.sended = NSNumber(value: false as Bool)
        } else {
            trackEntity?.dateStart = dateStart!
            trackEntity?.dateEnd = dateEnd!
            trackEntity?.pause = NSNumber(value: self.pauseValue as Double)
            trackEntity?.sended = NSNumber(value: false as Bool)
        }
        appDelegate.saveContext()

        self.navigationController?.popViewController(animated: true)
    }

    // MARK: - EEPauseAdjustmentDelegate methods
    override func confirmAutomaticPauseAdjustment() {
        self.pauseValue = automaticallyAdjustedPauseValue
        self.updatePauseTimeLabel()
        self.updateTotalHoursLabel()

        self.saveData()
    }

    override func rejectAutomaticPauseAdjustment() {
        automaticallyAdjustedPauseValue = 0
        self.saveData()
    }
}
