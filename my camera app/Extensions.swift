//
//  Extensions.swift
//  my camera app
//
//  Created by ryan teixeira on 2/25/16.
//  Copyright © 2016 Ryan Teixeira. All rights reserved.
//

import Foundation
import UIKit

public extension UIApplication {
    // UIApplication.sharedApplication().openAppSettings()
    func openAppSettings() {
        let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
        if let url = settingsUrl {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}

public extension UIScreen {
    class var screenWidth : Float  {
        get {
            let mainScreen = UIScreen.mainScreen()
            return Float(mainScreen.bounds.size.width)
        }
    }
    
    class var screenHeight : Float  {
        get {
            let mainScreen = UIScreen.mainScreen()
            return Float(mainScreen.bounds.size.height)
        }
    }
    
}

public extension UIViewController {

    public func alert(message: String, title:String?) {
        dispatch_async(dispatch_get_main_queue()) {
            var alertTitle:String
            if title == nil { alertTitle = "" }
            else { alertTitle = title! }
            let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}

