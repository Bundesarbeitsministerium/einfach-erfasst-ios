import UIKit
import CoreData
import MessageUI

class TimesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var deleteButtonItem: UIBarButtonItem!
    @IBOutlet weak var sendEmailButtonItem: UIBarButtonItem!
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!

    // MARK: - IBActions
    @IBAction func editAction(_ sender: AnyObject) {
        // Switch mode:
        if self.tableView.isEditing {
            self.exitEditMode()
        } else {
            self.enterEditMode()
        }
    }

    @IBAction func addAction(_ sender: AnyObject) {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "zurück", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        let addEditController = self.storyboard?.instantiateViewController(withIdentifier: "AddEditTrackEntityViewController") as! AddEditTrackEntityViewController
        self.navigationController?.pushViewController(addEditController, animated: true)
    }

    @IBAction func deleteAction(_ sender: AnyObject) {
        let deleteConfirmationAlert = UIAlertView(title: nil, message: "Die von Ihnen ausgewählten Einträge werden unwiderruflich gelöscht.", delegate: self, cancelButtonTitle: "Abbrechen")
        deleteConfirmationAlert.addButton(withTitle: "OK")
        deleteConfirmationAlert.show()
    }

    @IBAction func sendEmailAction(_ sender: AnyObject) {
        if selectedItems.count == 0 {
            return
        }

        if !userDataValid() {
            self.shouldSendItems = true
            self.showAccountDetailViewController()
            return
        }

        let selectedPaths = Array(selectedItems.keys)
        var itemsToSend = [TrackEntity]()
        for indexPath in selectedPaths {
            let date = self.sortedMonths![indexPath.section]
            var items = self.sections![date]
            itemsToSend.append(items![indexPath.row])
        }

        // Sort itemsToSend:
        let sortedItemsToSend = itemsToSend.sorted(by: { $0.dateStart.compare($1.dateStart as Date) == ComparisonResult.orderedAscending })

        let mailFormatter = DateFormatter()
        mailFormatter.dateFormat = "HH:mm"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"

        var totalDifference: TimeInterval = 0
        var bodyString = ""
        for item in sortedItemsToSend {
            let startTime = mailFormatter.string(from: item.dateStart as Date)
            let endTime = mailFormatter.string(from: item.dateEnd as Date)
            let dateString = dateFormatter.string(from: item.dateStart as Date)

            // build worked time:
            var difference = item.dateEnd.timeIntervalSince(item.dateStart as Date)
            difference = ceil(difference)
            difference -= item.pause.doubleValue

            totalDifference += difference

            let imagineDate = Date(timeInterval: difference, since: item.dateStart as Date)

            let calendar = Calendar.current
            let calendarUnits: NSCalendar.Unit = [NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second]
            let components = (calendar as NSCalendar).components(calendarUnits, from: item.dateStart as Date, to: imagineDate, options: [])
            let workedTime = String(format: "%02d:%02d", components.hour!, components.minute!)

            let pauseFrom = Date(timeIntervalSince1970: 0)
            let pauseTo = Date(timeIntervalSince1970: item.pause.doubleValue)
            let pauseComponents = (calendar as NSCalendar).components(calendarUnits, from: pauseFrom, to: pauseTo, options: [])
            let pauseString = String(format: "%02d:%02d", pauseComponents.hour!, pauseComponents.minute!)

            bodyString += "Datum: \(dateString)\n"
            bodyString += "Arbeitsbeginn: \(startTime)\n"
            bodyString += "Arbeitsende: \(endTime)\n"
            bodyString += "Arbeitsdauer: \(workedTime)\n"
            bodyString += "Pausendauer: \(pauseString)\n\n"
        }

        // calculate total time:
        let now = Date()
        let futureDate = Date(timeInterval: totalDifference, since: now)

        let calendar = Calendar.current
        let calendarUnits: NSCalendar.Unit = [NSCalendar.Unit.hour, NSCalendar.Unit.minute, NSCalendar.Unit.second]
        let components = (calendar as NSCalendar).components(calendarUnits, from: now, to: futureDate, options: [])

        let totalTime = String(format: "%02d:%02d", components.hour!, components.minute!)
        bodyString += "Gesamtarbeitsdauer: \(totalTime)"

        let userInfo = appDelegate.getUserInfo()

        if MFMailComposeViewController.canSendMail() {
            let mailComposeViewController = MFMailComposeViewController()

            var subjectString = "Zeiterfassung von "
            subjectString += "\(userInfo.firstName) \(userInfo.lastName)"

            let firstString = dateFormatter.string(from: sortedItemsToSend.first!.dateStart as Date)
            let lastString = dateFormatter.string(from: sortedItemsToSend.last!.dateStart as Date)
            if (firstString != lastString) {
                subjectString += " \(firstString) – \(lastString)"
            } else {
                subjectString += " \(firstString)"
            }

            bodyString = "\(userInfo.firstName) \(userInfo.lastName)\n\n" + bodyString
            mailComposeViewController.mailComposeDelegate = self
            mailComposeViewController.setToRecipients([userInfo.email as String])
            mailComposeViewController.setSubject(subjectString)
            mailComposeViewController.setMessageBody(bodyString, isHTML: false)
            self.present(mailComposeViewController, animated: true, completion: nil)

            self.markSelectedTimeEntitiesAsSended()
            updateLastSendDate()
            self.clearAppBadge()
            self.appDelegate.saveContext()
        } else {
            let mailAlert = UIAlertView(title: "Sie müssen in den Geräteeinstellungen ihren E-Mail Account konfigurieren um fortzufahren.", message: nil, delegate: nil, cancelButtonTitle: "OK")
            mailAlert.show()
        }
    }

    // MARK: - Properties
    var timesList = [TrackEntity]()
    var sections: [Date: [TrackEntity]]?
    var sortedMonths: Array<Date>?
    var shouldSendItems: Bool = false

    var sectionHeadersLeadingConstraints = [Date: NSLayoutConstraint]()
    var sectionCheckboxes = [Date: UIButton]()

    var checkedSections = [Date: Bool]()
    var selectedItems = [IndexPath: Bool]()


    var appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var managedObjectContext: NSManagedObjectContext?

    // MARK: Methods
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.delegate = self

        managedObjectContext = appDelegate.managedObjectContext
        NotificationCenter.default.addObserver(self, selector: #selector(TimesViewController.contextSaved(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: managedObjectContext)


        self.navigationItem.rightBarButtonItem?.title = "auswählen".uppercased()
        self.navigationItem.leftBarButtonItem?.title = "eintrag hinzufügen".uppercased()

        self.navigationItem.rightBarButtonItem!.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "BundesSansWeb-Bold", size: 14)!], for: UIControlState())
        self.navigationItem.leftBarButtonItem!.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "BundesSansWeb-Bold", size: 14)!], for: UIControlState())

        self.deleteButtonItem.title = "löschen".uppercased()
        self.deleteButtonItem.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "BundesSansWeb-Bold", size: 14)!], for: UIControlState())
        self.sendEmailButtonItem.title = "versenden".uppercased()
        self.sendEmailButtonItem.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "BundesSansWeb-Bold", size: 14)!], for: UIControlState())

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        self.updateData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        self.navigationController?.isNavigationBarHidden = false

        self.navigationController?.navigationBar.barTintColor = UIColor(red:0, green:0.73, blue:0.88, alpha:1)
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }

    @objc func contextSaved(_ notification: Notification) {
        updateData()
    }

    func updateData() {
        self.fetchTimes()

        self.sections = [Date:Array<TrackEntity>]()
        for item in timesList {
            let dateRepresentingThisMonth = self.dateAtBeginningOfMonthForDate(item.dateStart as Date)
            // If we don't yet have an array to hold the items for this month, create one
            var itemsOnThisMonth = self.sections![dateRepresentingThisMonth]
            if (itemsOnThisMonth == nil) {
                itemsOnThisMonth = [TrackEntity]()
            }

            // Add the event to the list for this month
            itemsOnThisMonth!.append(item)
            // Use the string date as dictionary key to later retrieve the items list this month
            self.sections![dateRepresentingThisMonth] = itemsOnThisMonth
        }

        // Create a sorted list of months
        let unsortedMonths = Array(self.sections!.keys)
        self.sortedMonths = unsortedMonths.sorted(by: { $0.compare($1) == ComparisonResult.orderedDescending })


        // Clear checked sections:
        for date in sortedMonths! {
            checkedSections[date] = nil
        }

        self.tableView.reloadData()
    }

    func enterEditMode() {
        self.tableView.setEditing(true, animated: true)

        for (_, constraint) in sectionHeadersLeadingConstraints {
            constraint.constant = 0
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.tableView.layoutIfNeeded()
        })

        let rightButtonItem = self.navigationItem.rightBarButtonItem
        rightButtonItem!.title = "abbrechen".uppercased()
        self.tabBarController?.tabBar.isHidden = true
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.navigationItem.leftBarButtonItem?.title = ""
    }

    func exitEditMode() {
        self.tableView.setEditing(false, animated: true)

        for (_, constraint) in sectionHeadersLeadingConstraints {
            constraint.constant = -45
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.tableView.layoutIfNeeded()
        })

        let rightButtonItem = self.navigationItem.rightBarButtonItem
        rightButtonItem?.title = "auswählen".uppercased()
        self.tabBarController?.tabBar.isHidden = false
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        self.navigationItem.leftBarButtonItem?.title = "eintrag hinzufügen".uppercased()
        // clear selections.
        self.clearAllSelections()
    }

    func showEditButton() {
        let editButton = self.navigationItem.rightBarButtonItem
        editButton?.isEnabled = true
        if self.tableView.isEditing {
            editButton?.title = "abbrechen".uppercased()
        } else {
            editButton?.title = "auswählen".uppercased()
        }
    }

    func hideEditButton() {
        let editButton = self.navigationItem.rightBarButtonItem
        editButton?.isEnabled = false
        editButton?.title = ""
    }

    func fetchTimes() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackEntity")
        let sortDescriptor = NSSortDescriptor(key: "dateStart", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            let fetchResults = try managedObjectContext!.fetch(fetchRequest) as? [TrackEntity]
            timesList = fetchResults!
        } catch _ {
            timesList = [TrackEntity]()
        }

        if timesList.count == 0 {
            // Exit editing mode and disable edit button.
            if tableView.isEditing {
                self.exitEditMode()
            }
            self.hideEditButton()

            // Show empty view
            let emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: tableView.frame.size.height))
            emptyLabel.text = "Keine Einträge vorhanden"
            emptyLabel.textAlignment = NSTextAlignment.center
            emptyLabel.font = UIFont(name: "BundesSansWeb", size: 14)
            emptyLabel.textColor = Constants.kTextColor

            self.tableView.backgroundView = emptyLabel
        } else {
            // Hide empty view
            self.tableView.backgroundView = nil
            self.showEditButton()
        }
    }

    func deleteTimeEntry(_ timeEntry: TrackEntity) {
        managedObjectContext?.delete(timeEntry)
    }

    func dateAtBeginningOfMonthForDate(_ inputDate: Date) -> Date {
        let calendar = Calendar.current
        var components = (calendar as NSCalendar).components([.year, .month], from: inputDate)
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0

        return calendar.date(from: components)!
    }

    @objc func sectionSelected(_ sender: NSObject) {
        if !tableView.isEditing { return }

        let senderButton = sender as? UIButton
        let senderGR = sender as? UITapGestureRecognizer

        for (date, button) in sectionCheckboxes {
            if senderButton == button || senderGR?.view?.tag == button.tag {
                if let _ = checkedSections[date] {
                    checkedSections[date] = nil // clear value
                    button.setImage(UIImage(named: "unchecked"), for: UIControlState())
                    self.deselectAllCellsInSection(date)
                } else {
                    checkedSections[date] = true
                    button.setImage(UIImage(named: "checked"), for: UIControlState())
                    self.selectAllCellsInSection(date)
                }
                break
            }
        }
    }

    @objc func cellCheckboxSelected(_ sender: UIButton) {
        let convertedFrame = sender.convert(sender.bounds, to: self.tableView)
        let indexPath = tableView.indexPathForRow(at: convertedFrame.origin)

        self.selectDeselectCellAtIndexPath(indexPath!)
    }

    func selectDeselectCellAtIndexPath(_ indexPath: IndexPath) {
        if let _ = selectedItems[indexPath] {
            selectedItems[indexPath] = nil // clear value.
            // deselect section:
            let date = self.sortedMonths![indexPath.section]
            if let _ = checkedSections[date] {
                // uncheck section here
                checkedSections[date] = nil
                let button = sectionCheckboxes[date]
                button?.setImage(UIImage(named: "unchecked"), for: UIControlState())
            }
        } else {
            // If value is empty then it not selected
            selectedItems.updateValue(true, forKey: indexPath)
        }
        self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
    }

    func selectAllCellsInSection(_ date: Date) {
        let sectionIndex = self.sortedMonths!.index(of: date)
        let numberOfItems = self.sections![date]?.count

        // Build indexPaths and mark them as checked
        for row in 0..<numberOfItems! {
            let indexPath = IndexPath(row: row, section: sectionIndex!)
            if let cell = self.tableView.cellForRow(at: indexPath) as? TimeEntryCell {
                cell.customEditControl.setImage(UIImage(named: "checked"), for: UIControlState())
            }
            self.selectedItems[indexPath] = true
        }
    }

    func deselectAllCellsInSection(_ date: Date) {
        let sectionIndex = self.sortedMonths!.index(of: date)
        let numberOfItems = self.sections![date]?.count

        // Build indexPaths and mark them as unchecked
        for row in 0..<numberOfItems! {
            let indexPath = IndexPath(row: row, section: sectionIndex!)
            if let cell = self.tableView.cellForRow(at: indexPath) as? TimeEntryCell {
                cell.customEditControl.setImage(UIImage(named: "unchecked"), for: UIControlState())
            }
            self.selectedItems[indexPath] = nil
        }
    }

    func clearAllSelections() {
        // clear selected paths and sections:
        selectedItems.removeAll(keepingCapacity: false)
        checkedSections.removeAll(keepingCapacity: false)

        // do visual sections clear
        for (_, button) in sectionCheckboxes {
            button.setImage(UIImage(named: "unchecked"), for: UIControlState())
        }

        // do visual cells clear
        for (sectionIndex, sectionDate) in self.sortedMonths!.enumerated() {
            let elements = self.sections![sectionDate]
            for rowIndex in 0..<elements!.count {
                if let cell = self.tableView.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex)) as? TimeEntryCell {
                    cell.customEditControl.setImage(UIImage(named: "unchecked"), for: UIControlState())
                }
            }
        }
    }

    func userDataValid() -> Bool {
        let userInfo = appDelegate.getUserInfo()
        var result = true
        if userInfo.firstName == "" || userInfo.lastName == "" || userInfo.email == "" {
            result = false
        }
        return result
    }

    func showAccountDetailViewController() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "zurück", style: UIBarButtonItemStyle.plain, target: nil, action: nil)

        let accountDetailViewController = self.storyboard?.instantiateViewController(withIdentifier: "AccountDetailsViewController") as! AccountDetailsViewController
        accountDetailViewController.parentIsTimesScreen = true
        self.navigationController?.pushViewController(accountDetailViewController, animated: true)
    }

    func clearAppBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func markSelectedTimeEntitiesAsSended() {
        let selectedPaths = Array(selectedItems.keys)
        var itemsToMark = [TrackEntity]()
        for indexPath in selectedPaths {
            let date = self.sortedMonths![indexPath.section]
            var items = self.sections![date]
            itemsToMark.append(items![indexPath.row])
        }

        for trackEntity in itemsToMark {
            trackEntity.sended = true
        }
    }

    func deleteSelectedTimeEntities() {
        let selectedPaths = Array(selectedItems.keys)
        for indexPath in selectedPaths {
            // delete indexpaths
            let date = self.sortedMonths![indexPath.section]
            var items = self.sections![date]
            // TODO: think how to better remove items
            let item = items?[indexPath.row]
            self.sections![date] = items
            self.deleteTimeEntry(item!)
//            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }

        self.clearAllSelections()
        self.appDelegate.saveContext()
    }

    // MARK: - UITableViewDataSource methods
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackEntityCell") as! TimeEntryCell
        cell.configureCell()

        let date = self.sortedMonths![indexPath.section]
        let itemsOnThisMonth = self.sections![date]!
        let timeItem = itemsOnThisMonth[indexPath.row]
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "DE")
        // day of week.
        dateFormatter.dateFormat = "EEE"
        // Remove trailing dot from day of week string.
        var dayOfWeekString = dateFormatter.string(from: timeItem.dateStart as Date)
        if dayOfWeekString.hasSuffix(".") {
            dayOfWeekString = String(dayOfWeekString.dropLast())
        }

        cell.dayOfWeekLabel.text = dayOfWeekString

        dateFormatter.dateFormat = "dd."
        cell.dayOfMonthLabel.text = dateFormatter.string(from: timeItem.dateStart as Date)

        dateFormatter.dateFormat = "HH:mm"
        let hoursStart = dateFormatter.string(from: timeItem.dateStart as Date)
        let hoursEnd = dateFormatter.string(from: timeItem.dateEnd as Date)

        cell.startEndTimesLabel.text = "\(hoursStart) - \(hoursEnd)"

        // Calculate total hours.

        var difference = timeItem.dateEnd.timeIntervalSince(timeItem.dateStart as Date)
        difference = ceil(difference)
        difference -= timeItem.pause.doubleValue

        let imagineDate = Date(timeInterval: difference, since: timeItem.dateStart as Date)

        let calendar = Calendar.current
        let calendarUnits: NSCalendar.Unit = [.hour, .minute, .second]
        let components = (calendar as NSCalendar).components(calendarUnits, from: timeItem.dateStart as Date, to: imagineDate, options: [])

        cell.totalHoursLabel.text = String(format: "%02d:%02d h", components.hour!, components.minute!)

        cell.customEditControl.addTarget(self, action: #selector(TimesViewController.cellCheckboxSelected(_:)), for: .touchUpInside)
        if let _ = selectedItems[indexPath] {
            cell.customEditControl.setImage(UIImage(named: "checked"), for: UIControlState())
        } else {
            cell.customEditControl.setImage(UIImage(named: "unchecked"), for: UIControlState())
        }

        if timeItem.sended.boolValue {
            cell.backgroundColor = UIColor(red: 0.89, green: 0.95, blue: 0.82, alpha: 1.00)
        } else {
            cell.backgroundColor = UIColor.clear
        }

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 77))
        sectionView.backgroundColor = UIColor.white

        let sectionContainer = UIView()
        sectionView.addSubview(sectionContainer)

        sectionContainer.translatesAutoresizingMaskIntoConstraints = false

        sectionView.addConstraint(NSLayoutConstraint(item: sectionContainer, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: sectionView, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
        sectionView.addConstraint(NSLayoutConstraint(item: sectionContainer, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: sectionView, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
        sectionView.addConstraint(NSLayoutConstraint(item: sectionContainer, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: sectionView, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0))

        let constraint = NSLayoutConstraint(item: sectionContainer, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: sectionView, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
        if self.tableView.isEditing {
            constraint.constant = 0
        } else {
            constraint.constant = -45
        }
        sectionView.addConstraint(constraint)

        let date = self.sortedMonths![section]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "DE")
        formatter.dateFormat = "MMMM yyyy"

        sectionHeadersLeadingConstraints.updateValue(constraint, forKey: date)

        // Section checkbox configuration.
        let checkbox = UIButton(frame: CGRect(x: 0, y: 0, width: 27, height: 27))
        checkbox.tag = section
        if checkedSections[date] == true {
            checkbox.setImage(UIImage(named: "checked"), for: UIControlState())
        } else {
            checkbox.setImage(UIImage(named: "unchecked"), for: UIControlState())
        }

        sectionContainer.addSubview(checkbox)
        checkbox.translatesAutoresizingMaskIntoConstraints = false

        sectionContainer.addConstraint(NSLayoutConstraint(item: checkbox, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: sectionContainer, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        sectionContainer.addConstraint(NSLayoutConstraint(item: checkbox, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: sectionContainer, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 15))

        checkbox.addTarget(self, action: #selector(TimesViewController.sectionSelected(_:)), for: UIControlEvents.touchUpInside)
        sectionCheckboxes.updateValue(checkbox, forKey: date)

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TimesViewController.sectionSelected(_:)))
        sectionView.addGestureRecognizer(gestureRecognizer)
        sectionView.tag = section
        sectionView.isUserInteractionEnabled = true

        // Section title configuration.
        let sectionTitle = UILabel()
        sectionTitle.font = UIFont(name: "BundesSans Web", size: 26)

        sectionTitle.text = formatter.string(from: date)

        sectionContainer.addSubview(sectionTitle)
        sectionTitle.translatesAutoresizingMaskIntoConstraints = false

        sectionContainer.addConstraint(NSLayoutConstraint(item: sectionTitle, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: sectionContainer, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        sectionContainer.addConstraint(NSLayoutConstraint(item: sectionTitle, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: checkbox, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 20))


        sectionView.layer.masksToBounds = false
        sectionView.layer.shadowOffset = CGSize(width: 0, height: 3)
        sectionView.layer.shadowRadius = 2
        sectionView.layer.shadowOpacity = 0.5
        sectionView.layer.shadowColor = UIColor.lightGray.cgColor
        return sectionView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 77.0 as CGFloat
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let date = self.sortedMonths![section]
        let itemsOnThisMonth = self.sections![date]
        return itemsOnThisMonth!.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = self.sections {
            return sections.count
        }
        return 0
    }

    // MARK: - UITableViewDelegate methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if tableView.isEditing {
            self.selectDeselectCellAtIndexPath(indexPath)
        } else {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "zurück", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
            let addEditController = self.storyboard?.instantiateViewController(withIdentifier: "AddEditTrackEntityViewController") as! AddEditTrackEntityViewController
            let date = self.sortedMonths![indexPath.section]
            let sectionItems = self.sections![date]
            let trackEntity = sectionItems![indexPath.row]
            addEditController.trackEntity = trackEntity
            self.navigationController?.pushViewController(addEditController, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }


    // MARK: - MFMailComposeViewControllerDelegate methods
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.tableView.reloadData()
        controller.dismiss(animated: true, completion: nil)
    }

    // MARK: - UINavigationControllerDelegate methods
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController == self {
            if self.tableView.isEditing {
                self.tabBarController?.tabBar.isHidden = true
            } else {
                self.tabBarController?.tabBar.isHidden = false
            }
        }
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController == self {
            if self.tableView.isEditing && self.shouldSendItems {
                // try to send items again
                if userDataValid() {
                    self.sendEmailAction(sendEmailButtonItem)
                }
            }
            self.shouldSendItems = false
        }
    }

    // MARK: - UIAlertViewDelegate methods
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex != alertView.cancelButtonIndex {
            deleteSelectedTimeEntities()
        }
    }
}
