//
//  AppDelegate.swift
//  CoinAlert
//
//  Created by Andrew Sorenson on 4/8/21.
//

import UIKit
import BackgroundTasks
import Firebase
import FirebaseMessaging
import FirebaseAnalytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    static var notificationsEnabled: Bool = true

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //firebase
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        
        //APNS
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        //guard against users who don't give notification permission
        UNUserNotificationCenter.current()
          .requestAuthorization(
            options: authOptions) { [weak self] granted, _ in
            print("Permission granted: \(granted)")
            guard granted else {
                //no notifications enabled
                AppDelegate.notificationsEnabled = false
                return
            }
            self?.getNotificationSettings()
          }
        
        application.registerForRemoteNotifications()

        Messaging.messaging().delegate = self
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    // MARK: Private Methods
    
    private func getNotificationSettings() {
        
        //return granted settings
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            
            print("Notification settings: \(settings)")
            //verify user has authorized notifications
            guard settings.authorizationStatus == .authorized else { return }
            //if so, then register device for Remote Notifications
            DispatchQueue.main.async {
              UIApplication.shared.registerForRemoteNotifications()
            }

        }
    }
 
}


// MARK: Push Notification Setup

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler:
    @escaping (UNNotificationPresentationOptions) -> Void
    ) {
    completionHandler([[.banner, .sound]])
    }

    func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
    ) {
    completionHandler()
    }
    
    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
//        print("APNS device Token: \(token)")
        
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(
      _ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
      print("Failed to register for notifications: \(error)")
    }

}


extension AppDelegate: MessagingDelegate {
  func messaging(
    _ messaging: Messaging,
    didReceiveRegistrationToken fcmToken: String?
  ) {
    Messaging.messaging().token { token, error in
      if let error = error {
        print("Error fetching FCM registration token: \(error)")
      } else if let token = token {
        //set userToken value as FCM token
        CoinTableViewController.userToken = token
//        print("FCM registration token: \(token)")
      }
    }
    
    let tokenDict = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: tokenDict)
  }
    
}


