import UIKit
import CoreData

enum TrackingState: Int {
    case none = 0, started, stopped, pauseStarted
}

class TrackingViewController: EEBaseTrackingViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var trackTimeLabel: UILabel!
    @IBOutlet weak var trackTimeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var beginDateLabel: UILabel!
    @IBOutlet weak var beginTimeLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var pauseTrackTimeLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var pauseTrackTimeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pauseTimeLabel: UILabel!
    @IBOutlet weak var scrollViewContent: UIView!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet var separatorHeightConstraints: [NSLayoutConstraint]!
    @IBOutlet var verticalPaddingConstraints: [NSLayoutConstraint]!

    // MARK: - IBActions
    @IBAction func saveButtonAction(_ sender: AnyObject) {

        if let start = self.dateStart, let end = self.dateEnd {

            // Trim seconds from times.
            let calendar = Calendar.current
            var startSeconds = (calendar as NSCalendar).components(NSCalendar.Unit.second, from: start as Date)
            startSeconds.second = -startSeconds.second!
            self.dateStart = (calendar as NSCalendar).date(byAdding: startSeconds, to: start as Date, options: [])

            var endSeconds = (calendar as NSCalendar).components(NSCalendar.Unit.second, from: end as Date)
            endSeconds.second = -endSeconds.second!
            self.dateEnd = (calendar as NSCalendar).date(byAdding: endSeconds, to: end as Date, options: [])

            self.pauseValue -= self.pauseValue.truncatingRemainder(dividingBy: 60)


            if self.showPauseWarningController() {
                return
            }

            self.saveData()
        }
    }

    @IBAction func startAction(_ sender: AnyObject) {
        // Start action.
        switch currentTrackingState {
        case .none:
            currentTrackingState = .started
            setStartTime(Date())
            startTimeTrackingTimer()
        case .started:
            currentTrackingState = .stopped
            setEndTime(Date())
            stopTimeTrackingTimer()
        case .stopped:
            currentTrackingState = .started
            clearEndTime()
            startTimeTrackingTimer()
        case .pauseStarted:
            // TODO: move same code to separate function
            currentTrackingState = .stopped
            setEndTime(Date())
            stopTimeTrackingTimer()
            stopPauseTrackingTimer()
            setPauseEnd()
        }

        updateButtons()
        saveTrackingState()
    }

    @IBAction func pauseAction(_ sender: AnyObject) {
        // Pause action.
        switch currentTrackingState {
        case .none:
            break
        case .started:
            currentTrackingState = .pauseStarted
            stopTimeTrackingTimer()
            setStartPauseTime()
            startPauseTrackingTimer()
        case .stopped:
            currentTrackingState = .stopped // Do nothing
        case .pauseStarted:
            currentTrackingState = .started
            stopPauseTrackingTimer()
            setPauseEnd()
            startTimeTrackingTimer()
        }

        updateButtons()
        saveTrackingState()
    }

    // MARK: - Properties
    var trackTimeHeight: CGFloat = 0
    var pauseTrackTimeHeight: CGFloat = 0


    // Current state.
    var pauseStartValue: Date?
    var pauseEndValue: Date?

    var currentTrackingState: TrackingState = .none

    var dateFormatter = DateFormatter()
    var timeFormatter = DateFormatter()
    var trackingFormatter = DateFormatter()
    var pauseTrackingFormatter = DateFormatter()

    var timeTrackingTimer: Timer?
    var pauseTrackingTimer: Timer?

    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        for constraint in self.separatorHeightConstraints {
            constraint.constant = 1 / UIScreen.main.scale
        }

        // Save original label heights
        trackTimeHeight = trackTimeHeightConstraint.constant
        pauseTrackTimeHeight = pauseTrackTimeHeightConstraint.constant

        // Fix for iphone 4s screen size.
        let size = UIScreen.main.bounds.size
        if size.height <= 480 { // Iphone 4s
//            contentViewHeightConstraint.constant = -50
            for constraint in verticalPaddingConstraints {
                constraint.constant = 15
            }
            trackTimeHeight -= 10
            trackTimeHeightConstraint.constant = trackTimeHeight
        }

        // Init formatters.
        dateFormatter.dateFormat = "EEE, dd.MM."
        dateFormatter.locale = Locale(identifier: "DE")

        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "DE")

        trackingFormatter.dateFormat = "HH:mm:ss"

        pauseTrackingFormatter.dateFormat = "HH:mm:ss"

        // Init state.
        self.initUserInterface()

        self.restoreTrackingState()
    }

    func showPauseTrackingTime() {
        pauseTrackTimeHeightConstraint.constant = pauseTrackTimeHeight
        trackTimeHeightConstraint.constant = trackTimeHeight - pauseTrackTimeHeight
    }

    func hidePauseTrackingTime() {
        pauseTrackTimeHeightConstraint.constant = 0
        trackTimeHeightConstraint.constant = trackTimeHeight
    }

    func initUserInterface() {
        self.trackTimeLabel.text = "00:00:00"
        self.pauseTrackTimeLabel.text = "00:00:00"
        self.beginDateLabel.text = ""
        self.beginTimeLabel.text = ""
        self.endDateLabel.text = ""
        self.endTimeLabel.text = ""
        self.pauseTimeLabel.text = ""

        self.currentTrackingState = .none
        self.clearStartTime()
        self.clearEndTime()
        self.clearPauseTime()

        updateButtons()
    }

    func saveTrackingState() {
        let defaults = UserDefaults.standard

        defaults.set(currentTrackingState.rawValue, forKey: Constants.Keys.TrackingState.kCurrentStateKey)
        defaults.set(dateStart, forKey: Constants.Keys.TrackingState.kDateStartKey)
        defaults.set(dateEnd, forKey: Constants.Keys.TrackingState.kDateEndKey)
        defaults.set(pauseStartValue, forKey: Constants.Keys.TrackingState.kPauseStartKey)
        defaults.set(pauseValue, forKey: Constants.Keys.TrackingState.kPauseValueKey)

        defaults.synchronize()
    }

    func restoreTrackingState() {
        let defaults = UserDefaults.standard

        if let dateStart = defaults.object(forKey: Constants.Keys.TrackingState.kDateStartKey) as? Date {
            self.setStartTime(dateStart)
        }
        if let dateEnd = defaults.object(forKey: Constants.Keys.TrackingState.kDateEndKey) as? Date {
            self.setEndTime(dateEnd)
        }
        if let pauseStart = defaults.object(forKey: Constants.Keys.TrackingState.kPauseStartKey) as? Date {
            self.pauseStartValue = pauseStart
        }
        self.pauseValue = defaults.double(forKey: Constants.Keys.TrackingState.kPauseValueKey)
        if self.pauseValue > 0 {
            setPauseTrackingLabel()
        }

        if let trackingState = TrackingState(rawValue: defaults.integer(forKey: Constants.Keys.TrackingState.kCurrentStateKey)) {
            self.currentTrackingState = trackingState

            switch self.currentTrackingState {
            case .none:
                break
            case .started:
                startTimeTrackingTimer()
            case .stopped:
                if let endDate = self.dateEnd {
                    setTimeTrackingLabelFromDate(endDate as Date)
                } else {
                    setTimeTrackingLabelFromDate(Date())
                }
                break
            case .pauseStarted:
                setTimeTrackingLabelFromDate(self.pauseStartValue!)
                startPauseTrackingTimer()
                break
            }
        }

        updateButtons()
    }

    func clearTrackingState() {
        let defaults = UserDefaults.standard

        defaults.removeObject(forKey: Constants.Keys.TrackingState.kCurrentStateKey)
        defaults.removeObject(forKey: Constants.Keys.TrackingState.kDateStartKey)
        defaults.removeObject(forKey: Constants.Keys.TrackingState.kDateEndKey)
        defaults.removeObject(forKey: Constants.Keys.TrackingState.kPauseStartKey)
        defaults.removeObject(forKey: Constants.Keys.TrackingState.kPauseValueKey)
    }

    func startTimeTrackingTimer() {
        timeTrackingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(TrackingViewController.updateTimeTrackingLabel), userInfo: nil, repeats: true)
    }

    func stopTimeTrackingTimer() {
        if let timeTrackingTimer = self.timeTrackingTimer {
            timeTrackingTimer.invalidate()
        }
    }

    func startPauseTrackingTimer() {
        pauseTrackingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(TrackingViewController.updatePauseTrackingLabel), userInfo: nil, repeats: true)
    }

    func stopPauseTrackingTimer() {
        if let pauseTrackingTimer = self.pauseTrackingTimer {
            pauseTrackingTimer.invalidate()
        }
    }

    func updateButtons() {
        saveButton.isEnabled = false
        saveButton.alpha = 0.5
        switch currentTrackingState {
        case .none:
            startButton.setImage(UIImage(named: "icon-start"), for: UIControlState())
            pauseButton.setImage(UIImage(named: "icon-pause"), for: UIControlState())
            hidePauseTrackingTime()
        case .started:
            startButton.setImage(UIImage(named: "icon-stop"), for: UIControlState())
            pauseButton.setImage(UIImage(named: "icon-pause-active"), for: UIControlState())
            hidePauseTrackingTime()
        case .stopped:
            startButton.setImage(UIImage(named: "icon-start"), for: UIControlState())
            pauseButton.setImage(UIImage(named: "icon-pause"), for: UIControlState())
            hidePauseTrackingTime()
            saveButton.isEnabled = true
            saveButton.alpha = 1
        case .pauseStarted:
            startButton.setImage(UIImage(named: "icon-stop"), for: UIControlState())
            pauseButton.setImage(UIImage(named: "icon-pause-end"), for: UIControlState())
            showPauseTrackingTime()
        }
    }

    func setStartTime(_ startTime: Date) {
        dateStart = startTime

        var beginDateString = dateFormatter.string(from: dateStart! as Date)
        // Remove trailing dot from day of week.
        beginDateString = beginDateString.replacingOccurrences(of: ".,", with: ",", options: NSString.CompareOptions.literal, range: nil)

        beginDateLabel.text = beginDateString
        beginTimeLabel.text = timeFormatter.string(from: dateStart! as Date)
    }

    func setEndTime(_ endTime: Date) {
        dateEnd = endTime

        var endDateString = dateFormatter.string(from: dateEnd! as Date)
        // Remove trailing dot from day of week.
        endDateString = endDateString.replacingOccurrences(of: ".,", with: ",", options: NSString.CompareOptions.literal, range: nil)

        endDateLabel.text = endDateString
        endTimeLabel.text = timeFormatter.string(from: dateEnd! as Date)
    }

    func clearEndTime() {
        dateEnd = nil
        endDateLabel.text = ""
        endTimeLabel.text = ""
    }

    func clearStartTime() {
        dateStart = nil
    }

    func clearPauseTime() {
        pauseValue = 0
        pauseStartValue = nil
        pauseEndValue = nil
    }

    func setStartPauseTime() {
        pauseStartValue = Date()
    }

    func setPauseEnd() {
        let now = Date()
        let difference = now.timeIntervalSince(pauseStartValue!)
        pauseValue += difference
    }

    func setTimeTrackingLabelFromDate(_ date: Date) {
        var difference = date.timeIntervalSince(dateStart! as Date)
        difference = ceil(difference)
        difference -= pauseValue

        let imagineDate = Date(timeInterval: difference, since: dateStart! as Date)

        let calendar = Calendar.current
        let calendarUnits: NSCalendar.Unit = [NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second]
        let components = (calendar as NSCalendar).components(calendarUnits, from: dateStart! as Date, to: imagineDate, options: [])

        trackTimeLabel.text = String(format: "%02d:%02d:%02d", components.hour!, components.minute!, components.second!)
    }

    func setPauseTrackingLabel() {
        let now = Date()
        let imagineDate = Date(timeInterval: pauseValue, since: now)
        let calendar = Calendar.current
        let calenarUnits: NSCalendar.Unit = [NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second]
        let components = (calendar as NSCalendar).components(calenarUnits, from: now, to: imagineDate, options: [])

        pauseTimeLabel.text = String(format: "%02d:%02d", components.hour!, components.minute!)
    }

    @objc func updateTimeTrackingLabel() {
        let now = Date()
        var difference = now.timeIntervalSince(dateStart! as Date)
        difference = ceil(difference)
        difference -= pauseValue

        let imagineDate = Date(timeInterval: difference, since: dateStart! as Date)

        let calendar = Calendar.current
        let calendarUnits: NSCalendar.Unit = [NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second]
        let components = (calendar as NSCalendar).components(calendarUnits, from: dateStart! as Date, to: imagineDate, options: [])

        trackTimeLabel.text = String(format: "%02d:%02d:%02d", components.hour!, components.minute!, components.second!)
    }

    @objc func updatePauseTrackingLabel() {
        let now = Date()
        var difference = now.timeIntervalSince(pauseStartValue!)
        difference = ceil(difference)
        difference += pauseValue

        let imagineDate = Date(timeInterval: difference, since: pauseStartValue!)
        let calendar = Calendar.current
        let calenarUnits: NSCalendar.Unit = [NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second]
        let components = (calendar as NSCalendar).components(calenarUnits, from: pauseStartValue!, to: imagineDate, options: [])

        pauseTrackTimeLabel.text = String(format: "%02d:%02d:%02d", components.hour!, components.minute!, components.second!)
        pauseTimeLabel.text = String(format: "%02d:%02d", components.hour!, components.minute!)
    }

    func saveData() {
        if let start = dateStart, let end = dateEnd {
            let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let context: NSManagedObjectContext = appDelegate.managedObjectContext!
            let newItem = NSEntityDescription.insertNewObject(forEntityName: "TrackEntity", into: context) as! TrackEntity
            newItem.dateStart = start
            newItem.dateEnd = end
            newItem.pause = NSNumber(value: self.pauseValue as Double)
            newItem.sended = NSNumber(value: false as Bool)
            appDelegate.saveContext()
            self.initUserInterface()
            self.clearTrackingState()
        }
    }

    // MARK: - EEPauseAdjustmentDelegate methods
    override func confirmAutomaticPauseAdjustment() {
        self.pauseValue = automaticallyAdjustedPauseValue

        self.setTimeTrackingLabelFromDate(dateEnd! as Date)
        self.setPauseTrackingLabel()
        self.saveData()
    }

    override func rejectAutomaticPauseAdjustment() {
        automaticallyAdjustedPauseValue = 0
        self.saveData()
    }
}
