import UIKit

class TimeEntryCell: UITableViewCell {

    @IBOutlet weak var dayOfWeekLabel: UILabel!
    @IBOutlet weak var dayOfMonthLabel: UILabel!
    @IBOutlet weak var totalHoursLabel: UILabel!
    @IBOutlet weak var startEndTimesLabel: UILabel!
    @IBOutlet weak var customEditControl: UIButton!
    @IBOutlet weak var customEditWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingSpaceToContainer: NSLayoutConstraint!
    @IBOutlet weak var verticalSeparatorHeightConstraint: NSLayoutConstraint!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initInterface()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        initInterface()
    }

    func initInterface() {
        self.accessoryView = UIImageView(image: UIImage(named: "disclosure-indicator"))
    }

    func configureCell() {
        verticalSeparatorHeightConstraint.constant = 1 / UIScreen.main.scale
        if self.isEditing {
            self.leadingSpaceToContainer.constant = 0
        } else {
            self.leadingSpaceToContainer.constant = -45
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        if editing {
            self.leadingSpaceToContainer.constant = 0
        } else {
            self.leadingSpaceToContainer.constant = -45
        }
        super.setEditing(editing, animated: animated)
    }
}
