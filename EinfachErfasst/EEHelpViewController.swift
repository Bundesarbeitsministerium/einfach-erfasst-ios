import UIKit

class EEHelpViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!

    var controllerIndex: Int = 0

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        separatorHeightConstraint.constant = 1 / UIScreen.main.scale

        let htmlFile = Bundle.main.path(forResource: "Help\(controllerIndex + 1)", ofType: "html")
        let htmlString: NSString?
        do {
            try htmlString = NSString(contentsOfFile: htmlFile!, encoding: String.Encoding.utf8.rawValue)
        } catch _ {
            htmlString = NSString(string: "")
        }

        let baseUrl = URL(fileURLWithPath: Bundle.main.bundlePath)

        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.loadHTMLString(htmlString! as String, baseURL: baseUrl)
    }
}
