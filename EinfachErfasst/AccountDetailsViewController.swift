import UIKit

class AccountDetailsViewController: BaseStartViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!

    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!

    // MARK: - IBActions
    @IBAction func saveAction(_ sender: AnyObject) {
        self.saveUserDataToUserInfo()
        if (self.firstNameField.text!.isEmpty || self.lastNameField.text!.isEmpty || self.emailField.text!.isEmpty) && parentIsTimesScreen {
            // show error
            let alert = UIAlertView(title: "Hinweis", message: "Um Ihre Arbeitszeiten versenden zu können, füllen Sie bitte alle Felder vollständig aus.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    var parentIsTimesScreen: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        separatorHeightConstraint.constant = 1 / UIScreen.main.scale
        firstNameField.layer.borderWidth = 2.0
        firstNameField.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1).cgColor

        lastNameField.layer.borderWidth = 2.0
        lastNameField.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1).cgColor

        emailField.layer.borderWidth = 2.0
        emailField.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1).cgColor

        // Add padding right for fields.
        firstNameField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);
        lastNameField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);
        emailField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);

        firstNameField.delegate = self
        lastNameField.delegate = self
        emailField.delegate = self

        self.setFieldsFromUserInfo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.barTintColor = Constants.kAppBackgroundColor
        self.navigationController?.navigationBar.tintColor = Constants.kAppTintColor

        self.tabBarController?.tabBar.isHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    func setFieldsFromUserInfo() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let userInfo = appDelegate.getUserInfo()
        self.firstNameField.text = userInfo.firstName as String
        self.lastNameField.text = userInfo.lastName as String
        self.emailField.text = userInfo.email as String
    }

    func saveUserDataToUserInfo() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let userInfo = appDelegate.getUserInfo()
        userInfo.firstName = self.firstNameField.text! as NSString
        userInfo.lastName = self.lastNameField.text! as NSString
        userInfo.email = self.emailField.text! as NSString
        appDelegate.saveContext()
    }

    // MARK: - UITextFieldDelegate methods
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = super.textFieldShouldReturn(textField)
        if textField == firstNameField {
            lastNameField.becomeFirstResponder()
        } else if textField == lastNameField {
            emailField.becomeFirstResponder()
        }
        return false
    }
}
