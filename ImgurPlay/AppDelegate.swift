//
//  AppDelegate.swift
//  ImgurPlay
//
//  Created by Ken Streger on 5/23/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import UIKit

import AeroGearOAuth2

// **********************************************************************************************************************
// The openURL app delegate handles the token info returned to the app after Oauth2 login.
// **********************************************************************************************************************


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    public weak var mainViewController: ViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // **********************************************************************************************************************
    // After Oauth2 login, the token information is returned to the app via this delegate.  A notification is sent to the
    // OAuth2 library to process the incoming data from the login browser
    // **********************************************************************************************************************
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

        prepareDefaultSettings()  // AeroGearOAuth2 requirement for Keychain maintenance
        
        let notification = Notification(name: Notification.Name(kImgurURLNotification), object:nil, userInfo:[UIApplicationLaunchOptionsKey.url:url])
        NotificationCenter.default.post(notification)
        return true
    }
    
    
    // AeroGearOAuth2 requirement for Keychain maintenance
    private func prepareDefaultSettings() {
        let userDefaults = UserDefaults.standard

        let clear = userDefaults.bool(forKey: "clearShootKeychain")
        if (clear) {
            print("clearing Keychain")
            let kc = KeychainWrap()
            _ = kc.resetKeychain()
        }
        // default values
        userDefaults.register(defaults: ["key_url" : ""])

    }
}

