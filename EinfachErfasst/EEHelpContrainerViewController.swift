import UIKit

class EEHelpContainerViewController: EEBaseSettingsViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    let kPagesCount = 9

    var pageViewController: UIPageViewController?
    var viewControllers = [EEHelpViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()

        initViewControllers()
        self.pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.pageViewController!.delegate = self
        self.pageViewController!.dataSource = self
        self.setupPageControl()

        let viewControllers = [self.viewControllers[0]]
        self.pageViewController!.setViewControllers(viewControllers, direction: .forward, animated: false, completion: {done in })

        self.addChildViewController(self.pageViewController!)
        self.view.addSubview(self.pageViewController!.view)

        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        let pageViewRect = self.view.bounds
        self.pageViewController!.view.frame = pageViewRect

        self.pageViewController!.didMove(toParentViewController: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    func initViewControllers() {
        for index in 0..<kPagesCount {
            let helpController = self.storyboard?.instantiateViewController(withIdentifier: "EEHelpViewController") as! EEHelpViewController
            helpController.controllerIndex = index
            self.viewControllers.append(helpController)
        }
    }

    fileprivate func setupPageControl() {
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor.lightGray
        appearance.currentPageIndicatorTintColor = UIColor(red:0, green:0.73, blue:0.88, alpha:1)
        appearance.backgroundColor = UIColor.white
    }

    // MARK: - UIPageViewControllerDelegate methods
    func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
        // Set the spine position to "min" and the page view controller's view controllers array to contain just one view controller. Setting the spine position to 'UIPageViewControllerSpineLocationMid' in landscape orientation sets the doubleSided property to true, so set it to false here.
        let currentViewController = self.pageViewController!.viewControllers![0] as UIViewController
        let viewControllers = [currentViewController]
        self.pageViewController!.setViewControllers(viewControllers, direction: .forward, animated: true, completion: {done in })

        self.pageViewController!.isDoubleSided = false
        return .min
    }

    // MARK: - UIPageViewControllerDataSource methods
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let helpController = viewController as! EEHelpViewController
        if (helpController.controllerIndex > 0) {
            return self.viewControllers[helpController.controllerIndex - 1]
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let helpController = viewController as! EEHelpViewController
        if (helpController.controllerIndex < kPagesCount - 1) {
            return self.viewControllers[helpController.controllerIndex + 1]
        }
        return nil
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return kPagesCount
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        let controller = pageViewController.viewControllers![0] as! EEHelpViewController
        return controller.controllerIndex
    }

}
