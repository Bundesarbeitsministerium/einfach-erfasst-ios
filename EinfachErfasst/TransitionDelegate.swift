import UIKit

@objc
class TransitionDelegate: NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let inView = transitionContext.containerView

        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        inView.addSubview(toVC!.view)

        let screenRect = UIScreen.main.bounds
        toVC?.view.frame = CGRect(x: 0, y: screenRect.size.height, width: fromVC!.view.frame.size.width, height: fromVC!.view.frame.size.height)

        UIView.animate(withDuration: 0.25, animations: {
            toVC!.view.frame = CGRect(x: 0, y: 0, width: fromVC!.view.frame.size.width, height: fromVC!.view.frame.size.height)
            }, completion: {
                (value: Bool) in
                transitionContext.completeTransition(true)
        })
    }

    // MARK: -
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}
