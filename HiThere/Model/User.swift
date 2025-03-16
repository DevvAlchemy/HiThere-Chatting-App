//
//  User.swift
//  HiThere
//
//  Created by Royal K on 2025-03-13.
//

import Foundation
import FirebaseFirestore

// This model represents a user in our app
struct User: Identifiable {
    // The user's unique ID
    var id: String

    // The username they display
    var username: String

    // Their email address
    var email: String

    // URL to their profile picture (if they have one)
    var photoURL: String

    // When they were last active
    var lastSeen: Timestamp

    // Helper property to check if user is currently online
    var isOnline: Bool {
        // Consider user online if they've been active in the last 5 minutes
        let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
        return lastSeen.dateValue() > fiveMinutesAgo
    }

    // This helper creates a dictionary to save to Firestore
    var asFirestoreDictionary: [String: Any] {
        return [
            "username": username,
            "email": email,
            "photoURL": photoURL,
            "lastSeen": lastSeen
        ]
    }
}
