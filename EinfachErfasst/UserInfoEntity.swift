import UIKit
import CoreData

@objc(UserInfoEntity)
class UserInfoEntity: NSManagedObject {
    @NSManaged var firstName: NSString
    @NSManaged var lastName: NSString
    @NSManaged var email: NSString
    @NSManaged var touAccepted: NSNumber
}
