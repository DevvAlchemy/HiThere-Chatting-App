//
//  NotificationService.swift
//  HiThere
//
//  Created by Royal K on 2025-03-13.
//

import Foundation
import FirebaseFirestore
import FirebaseMessaging

// This class handles sending push notifications
class NotificationService {
    // Singleton instance so we can access it from anywhere
    static let shared = NotificationService()

    private init() {}

    // Send a notification when a message is received
    func sendMessageNotification(to userId: String, from senderName: String, messageText: String) {
        // Get the user's FCM token from Firestore
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            guard let document = document, document.exists,
                  let data = document.data(),
                  let fcmToken = data["fcmToken"] as? String else {
                print("No FCM token available for user")
                return
            }

            // In a real app, you would send the notification using Firebase Cloud Functions
            // or a server-side component. For this tutorial app, we'll just print what would happen.
            print("Would send notification to token: \(fcmToken)")
            print("Notification content: New message from \(senderName): \(messageText)")

            // The actual implementation would look something like this:
            // 1. Call a Cloud Function that sends the notification
            // 2. The Cloud Function would use the FCM API to send the notification
            // 3. The notification would appear on the user's device
        }
    }

    // Handle an incoming notification
    func handleNotificationReceived(userInfo: [AnyHashable: Any]) {
        // Process the notification data
        if let messageId = userInfo["messageId"] as? String,
           let conversationId = userInfo["conversationId"] as? String {
            print("Received notification for message: \(messageId) in conversation: \(conversationId)")

            // You could use this to:
            // 1. Update the UI if the app is in the foreground
            // 2. Mark messages as delivered
            // 3. Update conversation badges
        }
    }
}
