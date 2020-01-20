import UIKit

class UserAgreementViewController: EEBaseSettingsViewController {
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        separatorHeightConstraint.constant = 1 / UIScreen.main.scale
        let htmlFile = Bundle.main.path(forResource: "Agreement", ofType: "html")
        let htmlString: NSString?
        do {
            htmlString = try NSString(contentsOfFile: htmlFile!, encoding: String.Encoding.utf8.rawValue)
        } catch _ {
            htmlString = NSString(string: "")
        }
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.loadHTMLString(htmlString! as String, baseURL: nil)
    }
}
