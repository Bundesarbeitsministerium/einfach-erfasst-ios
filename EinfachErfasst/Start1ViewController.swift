import UIKit


class Start1ViewController: BaseStartViewController {

    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!

    @IBAction func nextAction(_ sender: AnyObject) {
        if self.saveUserData() {
            parentViewModel?.showControllerVithIndex(controllerIndex + 1)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        firstNameField.layer.borderWidth = 2.0
        firstNameField.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1).cgColor

//        firstNameField.attributedPlaceholder = NSAttributedString(string: firstNameField.placeholder!, attributes: [NSForegroundColorAttributeName: Constants.kTextColor])

        lastNameField.layer.borderWidth = 2.0
        lastNameField.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1).cgColor

        firstNameField.delegate = self
        lastNameField.delegate = self

        separatorHeightConstraint.constant = 1 / UIScreen.main.scale
    }

    func saveUserData() -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let userInfo = appDelegate.getUserInfo()
        userInfo.firstName = firstNameField.text! as NSString
        userInfo.lastName = lastNameField.text! as NSString
        appDelegate.saveContext()

        return true
    }

    // MARK: - UITextFieldDelegate methods

    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = super.textFieldShouldReturn(textField)
        if textField == firstNameField {
            lastNameField.becomeFirstResponder()
        }
        return false
    }
}
