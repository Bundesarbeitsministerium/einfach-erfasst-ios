import UIKit
import CoreData
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ClearUserDataViewController: EEBaseSettingsViewController, UIAlertViewDelegate {

    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!

    @IBAction func clearUserDataAction(_ sender: AnyObject) {
        let deleteConfirmationAlert = UIAlertView(title: nil, message: "Möchten sie wirklich ihre Daten löschen?", delegate: self, cancelButtonTitle: "ABBRECHEN")
        deleteConfirmationAlert.addButton(withTitle: "OK")
        deleteConfirmationAlert.show()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        separatorHeightConstraint.constant = 1 / UIScreen.main.scale
    }

    func clearAllUserData() {
        // Clear saved account adata:
        let defaults = UserDefaults.standard

        // TODO: User info fields in defaults now deprecated
        defaults.removeObject(forKey: Constants.Keys.kFirstNameDefaultsKey)
        defaults.removeObject(forKey: Constants.Keys.kLastNameDefaultsKey)
        defaults.removeObject(forKey: Constants.Keys.kEmailDefaultsKey)
        defaults.removeObject(forKey: Constants.Keys.kUserAgreementAcceptedDefaultsKey)

        defaults.removeObject(forKey: Constants.Keys.kLastSendDateDefaultsKey)

        // Clear current tracking state:
        defaults.removeObject(forKey: Constants.Keys.TrackingState.kCurrentStateKey)
        defaults.removeObject(forKey: Constants.Keys.TrackingState.kDateStartKey)
        defaults.removeObject(forKey: Constants.Keys.TrackingState.kDateEndKey)
        defaults.removeObject(forKey: Constants.Keys.TrackingState.kPauseStartKey)
        defaults.removeObject(forKey: Constants.Keys.TrackingState.kPauseValueKey)
        defaults.synchronize()

        // Clear core data content:
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "TrackEntity", in: context!)
        fetchRequest.includesPropertyValues = false

        do {
            let allTrackEntities = try context?.fetch(fetchRequest) as? [TrackEntity]
            for trackEntity in allTrackEntities! {
                context?.delete(trackEntity)
            }
        } catch let error as NSError {
            print("Fetch failed \(error.localizedDescription)")
        }

        let infoFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserInfo")
        do {
            let infoEntities = try context?.fetch(infoFetchRequest) as? [UserInfoEntity]
            if infoEntities?.count > 0 {
                let userInfo = infoEntities![0]
                userInfo.firstName = ""
                userInfo.lastName = ""
                userInfo.email = ""
                userInfo.touAccepted = NSNumber(value: false as Bool)
            }
        } catch _ {
        }

        appDelegate.saveContext()

        // TODO: clear tracking screen. And maybe time list screen.
        // Send clear all data notification?
    }

    // MARK: - UIAlertViewDelegate methods
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex != alertView.cancelButtonIndex {
            self.clearAllUserData()
            self.navigationController?.popViewController(animated: true)
        }
    }
}
