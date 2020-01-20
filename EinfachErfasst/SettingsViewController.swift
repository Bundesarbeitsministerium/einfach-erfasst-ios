import UIKit

enum SettingsOptions: Int {
    case accountDetails = 0, clearAccountData, agreement, imprint, helpText, settingOptionsCount
}

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var headerSeparatorView: UIView!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.tableView.tableFooterView = UIView()

        // Set custom separator to be as tin as UITableView separator.
        self.separatorHeightConstraint.constant = 1 / UIScreen.main.scale
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "zurück", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
    }

    func showHelpController() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "zurück", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        let helpContainer = self.storyboard?.instantiateViewController(withIdentifier: "EEHelpContainerViewController") as! EEHelpContainerViewController
        self.navigationController?.pushViewController(helpContainer, animated: true)
    }

    // MARK: - UITableViewDataSource methods
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell")!
        //var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "SettingsCell")

        cell.accessoryView = UIImageView(image: UIImage(named: "disclosure-indicator"))

        switch SettingsOptions(rawValue: indexPath.row)! {
        case .accountDetails:
            cell.textLabel?.text = "Account ändern"
        case .agreement:
            cell.textLabel?.text = "Nutzungsvereinbarung"
        case .imprint:
            cell.textLabel?.text = "Impressum"
        case .clearAccountData:
            cell.textLabel?.text = "Nutzerdaten löschen"
        case .helpText:
            cell.textLabel?.text = "Hilfe"
        default:
            // Should not be called, so do nothing
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingsOptions.settingOptionsCount.rawValue
    }

    // MARK: - UITableViewDelegate methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch SettingsOptions(rawValue: indexPath.row)! {
        case .accountDetails:
            self.performSegue(withIdentifier: "kShowAccountDetailsID", sender: self)
        case .agreement:
            self.performSegue(withIdentifier: "kShowUserAgreementID", sender: self)
        case .imprint:
            self.performSegue(withIdentifier: "kShowImprintID", sender: self)
        case .clearAccountData:
            self.performSegue(withIdentifier: "kShowClearDataID", sender: self)
        case .helpText:
            self.showHelpController()
        default:
            return
        }
    }
}
