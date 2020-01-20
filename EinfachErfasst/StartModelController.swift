import UIKit

class StartModelController: NSObject, UIPageViewControllerDataSource {

    var viewControllers = [UIViewController]()
    var storyboard: UIStoryboard?
    var pageViewController: UIPageViewController?

    init(storyBoard: UIStoryboard, pageViewController: UIPageViewController) {
        super.init()
        self.storyboard = storyBoard
        self.pageViewController = pageViewController
        initViewControllers()
    }

    func initViewControllers() {
        let start1ViewController = storyboard?.instantiateViewController(withIdentifier: "Start1ViewController") as! Start1ViewController
        let start2ViewController = storyboard?.instantiateViewController(withIdentifier: "Start2ViewController") as! Start2ViewController
        let start3ViewController = storyboard?.instantiateViewController(withIdentifier: "Start3ViewController") as! Start3ViewController

        start1ViewController.controllerIndex = 0
        start2ViewController.controllerIndex = 1
        start3ViewController.controllerIndex = 2

        start1ViewController.parentViewModel = self
        start2ViewController.parentViewModel = self
        start3ViewController.parentViewModel = self

        viewControllers.append(start1ViewController)
        viewControllers.append(start2ViewController)
        viewControllers.append(start3ViewController)
    }

    func showControllerVithIndex(_ index: Int) {
        let controllers = [self.viewControllers[index]]
        self.pageViewController?.setViewControllers(controllers, direction: UIPageViewControllerNavigationDirection.forward, animated: true, completion: {done in })
    }

    // MARK: - Page View Controller Data Source
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let startViewController = viewController as! BaseStartViewController
        if (startViewController.controllerIndex > 0) {
            return self.viewControllers[startViewController.controllerIndex - 1]
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let startViewController = viewController as! BaseStartViewController
        if (startViewController.controllerIndex < 2) {
            return self.viewControllers[startViewController.controllerIndex + 1]
        }
        return nil
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return 3
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        let controller = pageViewController.viewControllers![0] as! BaseStartViewController
        return controller.controllerIndex
    }

}
