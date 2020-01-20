import Foundation
import CoreData

@objc(TrackEntity)
class TrackEntity: NSManagedObject {

    @NSManaged var dateEnd: Date
    @NSManaged var dateStart: Date
    @NSManaged var pause: NSNumber
    @NSManaged var sended: NSNumber

}
