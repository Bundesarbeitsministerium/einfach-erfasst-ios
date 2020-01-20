import UIKit
class BaseStartViewController: UIViewController, UITextFieldDelegate {

    var keyboardIsShowing: Bool = false
    var keyboardFrame: CGRect = CGRect.null
    var kPreferredTextFieldToKeyboardOffset: CGFloat = 20.0
    var activeTextField: UITextField?

    var controllerIndex: Int = 0
    var parentViewModel: StartModelController?
    var initialViewRect: CGRect = CGRect.null

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(BaseStartViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(BaseStartViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        self.keyboardIsShowing = true
        if let info = notification.userInfo {
            self.keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            self.arrangeViewOffsetFromKeyboard()
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        self.keyboardIsShowing = false

        self.returnViewToInitialFrame()
    }

    func arrangeViewOffsetFromKeyboard() {
        if activeTextField == nil {
            return
        }

        // Save original view frame
        if self.initialViewRect.equalTo(CGRect.null) {
            self.initialViewRect = self.view.frame
        }

        let theApp: UIApplication = UIApplication.shared
        let windowView: UIView? = theApp.delegate!.window!

        let textFieldLowerPoint: CGPoint = CGPoint(x: self.activeTextField!.frame.origin.x, y: self.activeTextField!.frame.origin.y + self.activeTextField!.frame.size.height)

        let convertedTextFieldLowerPoint: CGPoint = self.activeTextField!.superview!.convert(textFieldLowerPoint, to: windowView)

        let targetTextFieldLowerPoint: CGPoint = CGPoint(x: self.activeTextField!.frame.origin.x, y: self.keyboardFrame.origin.y - kPreferredTextFieldToKeyboardOffset)

        let targetPointOffset: CGFloat = targetTextFieldLowerPoint.y - convertedTextFieldLowerPoint.y
        if targetPointOffset < 0 {
            let adjustedViewFrameCenter: CGPoint = CGPoint(x: self.view.center.x, y: self.view.center.y + targetPointOffset)

            UIView.animate(withDuration: 0.2, animations:  {
                self.view.center = adjustedViewFrameCenter
            })
        }
    }

    func returnViewToInitialFrame() {
        if !self.initialViewRect.equalTo(self.view.frame) && !self.initialViewRect.equalTo(CGRect.null){
            UIView.animate(withDuration: 0.2, animations: {
                self.view.frame = self.initialViewRect
            })
        }
    }

    // MARK: - UITextFieldDelegate methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeTextField = textField

        if(self.keyboardIsShowing) {
            self.arrangeViewOffsetFromKeyboard()
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.activeTextField = nil
        textField.resignFirstResponder()
        return false
    }
}
