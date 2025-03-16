//
//  AppDelegate.swift
//  HiThere
//
//  Created by Royal K on 2025-03-15.
//

import UIKit
import Firebase
import FirebaseMessaging
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        // Additional Firebase logging
        print("AppDelegate: didFinishLaunchingWithOptions")

        // Add authentication state observer/ if FirebaseAuth is imported i do not need to use FirebaseAuth.Auth.auth
      Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                print("AppDelegate: User is signed in with ID: \(user.uid)")
            } else {
                print("AppDelegate: No user is signed in")
            }
        }

        return true
    }

    // Handle registration for remote notifications
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("AppDelegate: didRegisterForRemoteNotificationsWithDeviceToken")
        Messaging.messaging().apnsToken = deviceToken
    }

    // Handle remote notification registration errors
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate: Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Handle receiving a remote notification
    func application(_ application: UIApplication,
                    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("AppDelegate: Did receive remote notification")

        if let messageID = userInfo["gcm.message_id"] {
            print("Message ID: \(messageID)")
        }

        completionHandler(.newData)
    }
}
