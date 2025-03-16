//
//  MassagingManager.swift
//  HiThere
//
//  Created by Royal K on 2025-03-15.
//

import Foundation
import Firebase
import FirebaseMessaging
import UserNotifications

// This is a separate class for handling Firebase Cloud Messaging
// It needs to be a class (not a struct) to conform to Objective-C protocols
class MessagingManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    // Singleton instance that can be accessed from anywhere
    static let shared = MessagingManager()

    // We'll use this reference to update the user's FCM token
    private let db = Firestore.firestore()

    // We need this to inject the auth model
    weak var authViewModel: AuthViewModel?

    // Private initializer for singleton pattern
    private override init() {
        super.init()
    }

    // Setup method to be called when the app starts
    func setup() {
        // Set this class as the messaging delegate
        Messaging.messaging().delegate = self

        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Request permission to show notifications
        requestNotificationPermission()
    }

    // Ask the user for permission to show notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if granted {
                print("Notification permission granted")

                // Register for remote notifications with Apple
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - MessagingDelegate
    // This is called when Firebase gives us a new FCM token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }

        print("Firebase registration token: \(token)")

        // Save this token to the user's profile so we can send them notifications
        if let userId = authViewModel?.currentUser?.id {
            db.collection("users").document(userId).updateData([
                "fcmToken": token
            ]) { error in
                if let error = error {
                    print("Error updating FCM token: \(error.localizedDescription)")
                } else {
                    print("FCM token updated successfully")
                }
            }
        }
    }
}
