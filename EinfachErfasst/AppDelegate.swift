import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var localNotificationReceived: Bool = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        if #available(iOS 8.0, *) {
            application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: nil))
        } else {
            application.registerForRemoteNotifications(matching: [.alert, .sound, .badge])
        }

        self.exportUserInfoToCoreData()


        if let _ = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification {
            self.localNotificationReceived = true
        }

        self.window?.backgroundColor = Constants.kAppBackgroundColor
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default

        // Define back button indicator appearance:
        UINavigationBar.appearance().backIndicatorImage = UIImage(named: "back-icon")
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "back-icon")

        self.excludeDatabaseFromBackup()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.saveContext()
        self.setupLocalNotifications()
    }

    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Keys.kEELocalNotificationReceivedKey), object: nil)
    }

    func exportUserInfoToCoreData() {

        // Fetch data from db.
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserInfo")
        // get not sended items.
        do {
            let fetchResults = try managedObjectContext!.fetch(fetchRequest) as? [UserInfoEntity]
            if fetchResults!.count > 0 {
                return;
            } else {
            }
        } catch _ {
        }

        let defaults = UserDefaults.standard
        let firstName = defaults.string(forKey: Constants.Keys.kFirstNameDefaultsKey)
        let lastName = defaults.string(forKey: Constants.Keys.kLastNameDefaultsKey)
        let email = defaults.string(forKey: Constants.Keys.kEmailDefaultsKey)
        let touAccepted = defaults.bool(forKey: Constants.Keys.kUserAgreementAcceptedDefaultsKey)

        // Cerate new entity and export data.
        let userInfo = NSEntityDescription.insertNewObject(forEntityName: "UserInfo", into: self.managedObjectContext!) as! UserInfoEntity
        if let firstName = firstName {
            userInfo.firstName = firstName as NSString
        }

        if let lastName = lastName {
            userInfo.lastName = lastName as NSString
        }

        if let email = email {
            userInfo.email = email as NSString
        }

        userInfo.touAccepted = NSNumber(value: touAccepted as Bool)
        self.saveContext()

        // Clear defaults
        defaults.removeObject(forKey: Constants.Keys.kFirstNameDefaultsKey)
        defaults.removeObject(forKey: Constants.Keys.kLastNameDefaultsKey)
        defaults.removeObject(forKey: Constants.Keys.kEmailDefaultsKey)
        defaults.removeObject(forKey: Constants.Keys.kUserAgreementAcceptedDefaultsKey)
    }

    func addSkipBackupAttributeToIntemAtUrl(url: URL) -> Bool {
        assert(FileManager.default.fileExists(atPath: url.path))

        do {
            try (url as NSURL).setResourceValue(NSNumber(value: true as Bool), forKey: URLResourceKey.isExcludedFromBackupKey)
        } catch let error as NSError {
            print("Error excluding \(url.lastPathComponent) from backup: \(error.localizedDescription)")
            return false
        }
        return true
    }

    func excludeDatabaseFromBackup() {
        let url = self.applicationDocumentsDirectory.appendingPathComponent("EinfachErfasst.sqlite")
        _ = self.addSkipBackupAttributeToIntemAtUrl(url: url)
    }


    // MARK: - Helper functions.
    func touAccepted() -> Bool {
        let userInfo = self.getUserInfo()
        return userInfo.touAccepted.boolValue
    }

    func getUserInfo() -> UserInfoEntity {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserInfo")
        do {
            let fetchResults = try managedObjectContext!.fetch(fetchRequest) as? [UserInfoEntity]
            if fetchResults!.count > 0 {
                return fetchResults![0]
            }
        } catch _ {
        }
        let userInfo = NSEntityDescription.insertNewObject(forEntityName: "UserInfo", into: self.managedObjectContext!) as! UserInfoEntity
        self.saveContext()
        return userInfo
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.pixelpark.CoreDataTest" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "TimesModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("EinfachErfasst.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        let options = [NSMigratePersistentStoresAutomaticallyOption: NSNumber(value: true as Bool), NSInferMappingModelAutomaticallyOption: NSNumber(value: true as Bool), NSPersistentStoreFileProtectionKey: FileProtectionType.complete] as [String : Any]
        do {
            try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        } catch _ {
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error!), \(error!.userInfo)")
            abort()
        }

        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch _ {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error while saving context.")
                    abort()
                }

            }
            self.setupLocalNotifications()
        }
    }

    // MARK: - Custom methods

    func lastSendDate() -> Date {
        let defaults = UserDefaults.standard
        if let lastSendDate = defaults.object(forKey: Constants.Keys.kLastSendDateDefaultsKey) as? Date {
            return lastSendDate
        }
        return Date()
    }

    func setupLocalNotifications() {
        // clear all previously scheduled notifications
        UIApplication.shared.cancelAllLocalNotifications()

        let lastSendDate = self.lastSendDate()

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackEntity")
        let sortDescriptor = NSSortDescriptor(key: "dateStart", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = NSPredicate(format: "sended = false AND dateEnd > %@", lastSendDate as CVarArg)

        // get not sended items.
        do {
            let fetchResults = try managedObjectContext!.fetch(fetchRequest) as? [TrackEntity]
            if fetchResults!.count > 0 {
                if UIApplication.shared.applicationIconBadgeNumber > 0 { // Notification already has been shown.
                    return
                }
                let calendar = Calendar.current
                var sevenDays = DateComponents()
                sevenDays.day = 7
                var notificationDate = (calendar as NSCalendar).date(byAdding: sevenDays, to: lastSendDate, options: [])
                var components = (calendar as NSCalendar).components([.year, .month, .day, .hour, .minute], from: notificationDate!)
                components.hour = 9
                components.minute = 0
                notificationDate = calendar.date(from: components)

                let localNotification = UILocalNotification()
                localNotification.fireDate = notificationDate
                localNotification.timeZone = TimeZone.current
                localNotification.alertBody = "Bitte versenden Sie ihre Arbeitszeiten!"

                localNotification.alertAction = "Versenden"
                localNotification.soundName = UILocalNotificationDefaultSoundName
                localNotification.applicationIconBadgeNumber = 1

                UIApplication.shared.scheduleLocalNotification(localNotification)
            } else {
                UIApplication.shared.applicationIconBadgeNumber = 0 // No items for that period, clear badge.
            }
        } catch _ {
            UIApplication.shared.applicationIconBadgeNumber = 0 // No items for that period, clear badge.
        }
    }
}
