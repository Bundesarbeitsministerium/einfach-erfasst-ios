import UIKit

class RootViewController: UIViewController, UIPageViewControllerDelegate, UITabBarControllerDelegate {
    var pageViewController: UIPageViewController?
    var tabsViewController: UITabBarController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        NotificationCenter.default.addObserver(self, selector: #selector(RootViewController.localNotificationReceived(_:)), name: NSNotification.Name(rawValue: Constants.Keys.kEELocalNotificationReceivedKey), object: nil)

        // Configure tababar appearance.
        UITabBar.appearance().tintColor = Constants.kAppTintColor

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        if appDelegate.touAccepted() {
            self.showTabbar()
        } else {
            self.showPageController()
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var modelController: StartModelController {
        // Return the model controller object, creating it if necessary.
        // In more complex implementations, the model controller may be passed to the view controller.
        if _modelController == nil {
            _modelController = StartModelController(storyBoard: self.storyboard!, pageViewController: self.pageViewController!)
        }
        return _modelController!
    }

    var _modelController: StartModelController? = nil

    func showPageController() {
        self.pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.pageViewController!.delegate = self
        self.setupPageControl()

        let viewControllers = [self.modelController.viewControllers[0]]

        self.pageViewController!.setViewControllers(viewControllers, direction: .forward, animated: false, completion: {done in })

        self.pageViewController!.dataSource = self.modelController

        self.addChildViewController(self.pageViewController!)
        self.view.addSubview(self.pageViewController!.view)

        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        let pageViewRect = self.view.bounds
        self.pageViewController!.view.frame = pageViewRect

        self.pageViewController!.didMove(toParentViewController: self)
    }

    func showTabbar() {
        tabsViewController = self.storyboard?.instantiateViewController(withIdentifier: "tabbarcontroller") as? UITabBarController
        tabsViewController!.delegate = self

        self.addChildViewController(tabsViewController!)
        self.view.addSubview(tabsViewController!.view!)
        tabsViewController!.didMove(toParentViewController: self)

        for tabbarItem in tabsViewController!.tabBar.items! {
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

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if appDelegate.localNotificationReceived {
            tabsViewController!.selectedIndex = 0
            appDelegate.localNotificationReceived = false
        } else {
            tabsViewController!.selectedIndex = 1
        }

    }

    fileprivate func setupPageControl() {
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor.lightGray
        appearance.currentPageIndicatorTintColor = UIColor(red:0, green:0.73, blue:0.88, alpha:1)
        appearance.backgroundColor = UIColor.white
    }

    @objc func localNotificationReceived(_ notification: Notification) {
        if let tabsViewController = self.tabsViewController {
            tabsViewController.selectedIndex = 0
        }
    }

    // MARK: - UIPageViewController delegate methods

    func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
        // Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to true, so set it to false here.
        let currentViewController = self.pageViewController!.viewControllers![0]
        let viewControllers = [currentViewController]
        self.pageViewController!.setViewControllers(viewControllers, direction: .forward, animated: true, completion: {done in })

        self.pageViewController!.isDoubleSided = false
        return .min
    }

    // MARK: - UITabBarController delegate methods
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let navigationController = viewController as? UINavigationController {
            navigationController.popToRootViewController(animated: false)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Keys.kEELocalNotificationReceivedKey), object: nil)
    }
}
