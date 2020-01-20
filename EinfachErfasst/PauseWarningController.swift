import UIKit

class PauseWarningController: UIViewController {

    @IBOutlet weak var warningLabel: UILabel!

    @IBAction func noAction(_ sender: AnyObject) {
        // Nein action
        if let delegate = self.pauseAdjustmentDelegate {
            delegate.rejectAutomaticPauseAdjustment()
        }
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func understandAction(_ sender: AnyObject) {
        // JA action
        if let delegate = self.pauseAdjustmentDelegate {
            delegate.confirmAutomaticPauseAdjustment()
        }
        self.dismiss(animated: true, completion: nil)
    }

    var pauseAdjustmentDelegate: EEPauseAdjustmentDelegate?
    var hoursValue: Int = 0
    var pauseMinutesValue: Int = 0
    var neededPauseMinutesValue: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        warningLabel.text = "Bei der Registrierung Ihrer Arbeitszeit wurden \(pauseMinutesValue) Minuten Pause erfasst. Die gesetzlich vorgeschriebene Pausenzeit beträgt \(neededPauseMinutesValue) Minuten (siehe Hilfe)."
    }
}
