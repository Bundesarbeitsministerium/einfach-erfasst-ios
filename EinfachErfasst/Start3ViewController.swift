import UIKit

class Start3ViewController: BaseStartViewController {
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!


    @IBAction func acceptAction(_ sender: AnyObject) {
        self.saveAgreementAccepted()
        self.performSegue(withIdentifier: "show-tab-bar", sender: sender)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        separatorHeightConstraint.constant = 1 / UIScreen.main.scale

        let htmlFile = Bundle.main.path(forResource: "Agreement", ofType: "html")
        let htmlString: NSString?
        do {
            try htmlString = NSString(contentsOfFile: htmlFile!, encoding: String.Encoding.utf8.rawValue)
        } catch _ {
            htmlString = NSString(string: "")
        }
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.loadHTMLString(htmlString! as String, baseURL: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier == "show-tab-bar" {
            let tabbarController = segue.destination as! UITabBarController
            for tabbarItem in tabbarController.tabBar.items! {
                let item = tabbarItem
                switch item.title! {
                case "ZEITEN":
                    item.selectedImage = UIImage(named: "times-tab-active-icon")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
                case "ERFASSUNG":
                    item.selectedImage = UIImage(named: "track-tab-active-icon")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
                case "EINSTELLUNGEN":
                    item.selectedImage = UIImage(named: "settings-tab-active-icon")?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
                default:
                    break
                }
            }
            tabbarController.selectedIndex = 1
        }
    }

    func saveAgreementAccepted() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let userInfo = appDelegate.getUserInfo()
        userInfo.touAccepted = NSNumber(value: true as Bool)
        appDelegate.saveContext()

        // Init last send date.
        updateLastSendDate()
    }
}
