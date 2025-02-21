import YandexMapsMobile
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        YMKMapKit.setApiKey("d1f7d375-35bb-429e-9739-d04cba5ab9ff")
        YMKMapKit.sharedInstance()
        
        return true
    }
}

