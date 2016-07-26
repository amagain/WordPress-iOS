import UIKit
import WordPressShared

class WPSplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        preferredDisplayMode = .AllVisible

        extendedLayoutIncludesOpaqueBars = true

        // Values based on the behaviour of Settings.app
        preferredPrimaryColumnWidthFraction = 0.38
        minimumPrimaryColumnWidth = 320
        maximumPrimaryColumnWidth = 390
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    override var viewControllers: [UIViewController] {
        didSet {
            // Ensure that each top level navigation controller has
            // `extendedLayoutIncludesOpaqueBars` set to true. Otherwise we
            // see a large tab bar sized gap underneath each view controller.
            for viewController in viewControllers {
                if let viewController = viewController as? UINavigationController {
                    viewController.extendedLayoutIncludesOpaqueBars = true
                }
            }
        }
    }

    override func showDetailViewController(vc: UIViewController, sender: AnyObject?) {
        var detailVC = vc

        // Ensure that detail view controllers are wrapped in a navigation controller
        if !(vc is UINavigationController || collapsed) {
            detailVC = UINavigationController(rootViewController: vc)
        }

        super.showDetailViewController(detailVC, sender: self)
    }

    /** Sets the primary view controller of the split view as specified, and
     *  automatically sets the detail view controller if the primary
     *  conforms to `WPSplitViewControllerDetailProvider` and can vend a
     *  detail view controller.
     */
    func setInitialPrimaryViewController(viewController: UIViewController) {
        var initialViewControllers = [viewController]

        if let navigationController = viewController as? UINavigationController,
            let rootViewController = navigationController.viewControllers.first,
            let detailProvider = rootViewController as? WPSplitViewControllerDetailProvider,
            let detailViewController = detailProvider.initialDetailViewControllerForSplitView(self) {

            // Ensure it's wrapped in a navigation controller
            if detailViewController is UINavigationController {
                initialViewControllers.append(detailViewController)
            } else {
                initialViewControllers.append(UINavigationController(rootViewController: detailViewController))
            }

            viewControllers = initialViewControllers
        }
    }
}

extension WPSplitViewController: UISplitViewControllerDelegate {
    /** By default, the top view controller from the primary navigation
     *  controller will be popped and used as the secondary view controller.
     *  However, we want to ensure the the secondary view controller is a
     *  navigation controller, so we'll pop off everything but the root view
     *  controller and wrap it in a navigation controller if necessary.
     */
    func splitViewController(splitViewController: UISplitViewController, separateSecondaryViewControllerFromPrimaryViewController primaryViewController: UIViewController) -> UIViewController? {
        guard let primaryNavigationController = primaryViewController as? UINavigationController else {
            return nil
        }

        let viewControllers = Array(primaryNavigationController.viewControllers.dropFirst())
        primaryNavigationController.popToRootViewControllerAnimated(false)

        if let firstViewController = viewControllers.first as? UINavigationController {
            // If it's already a navigation controller, just return it
            return firstViewController
        } else {
            let navigationController = UINavigationController()
            navigationController.viewControllers = viewControllers

            return navigationController
        }
    }
}

extension UIViewController {
    var splitViewControllerIsCollapsed: Bool {
        return splitViewController?.collapsed ?? true
    }
}

@objc
protocol WPSplitViewControllerDetailProvider {
    func initialDetailViewControllerForSplitView(splitView: WPSplitViewController) -> UIViewController?
}
