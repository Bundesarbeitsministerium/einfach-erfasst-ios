import UIKit

class Start2ViewController: BaseStartViewController {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!

    @IBAction func nextAction(_ sender: AnyObject) {
        if self.saveEmail() {
            parentViewModel?.showControllerVithIndex(controllerIndex + 1)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Force font because some bug with IB.
        emailField.font = UIFont(name: "BundesSerifWeb-Italic", size: 20)
        emailField.layer.borderWidth = 2.0
        emailField.layer.borderColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1).cgColor
        emailField.delegate = self

        separatorHeightConstraint.constant = 1 / UIScreen.main.scale
    }

    func saveEmail() -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let userInfo = appDelegate.getUserInfo()
        userInfo.email = emailField.text! as NSString
        appDelegate.saveContext()
        return true
    }
}
