//
//  Conversation.swift
//  HiThere
//
//  Created by Royal K on 2025-03-13.
//

import Foundation
import FirebaseFirestore

// This represents a conversation between users
struct Conversation: Identifiable {
    // Unique ID for the conversation
    var id: String

    // The user IDs of people in this conversation
    var participantIds: [String]

    // The text of the most recent message
    var lastMessageText: String

    // When the last message was sent
    var lastMessageDate: Timestamp

    // Is this a self-chat (messaging yourself)?
    var isSelfChat: Bool

    // Helper function to get the other person's ID in a conversation
    func getOtherUserId(currentUserId: String) -> String? {
        if isSelfChat {
            return currentUserId
        }
        return participantIds.first(where: { $0 != currentUserId })
    }

    // This helper creates a dictionary to save to Firestore
    var asFirestoreDictionary: [String: Any] {
        return [
            "participantIds": participantIds,
            "lastMessageText": lastMessageText,
            "lastMessageDate": lastMessageDate,
            "isSelfChat": isSelfChat
        ]
    }

    // Create from Firestore data
    static func fromFirestore(id: String, data: [String: Any]) -> Conversation? {
        guard let participantIds = data["participantIds"] as? [String],
              let lastMessageText = data["lastMessageText"] as? String,
              let isSelfChat = data["isSelfChat"] as? Bool else {
            return nil
        }

        let lastMessageDate = data["lastMessageDate"] as? Timestamp ?? Timestamp(date: Date())

        return Conversation(
            id: id,
            participantIds: participantIds,
            lastMessageText: lastMessageText,
            lastMessageDate: lastMessageDate,
            isSelfChat: isSelfChat
        )
    }
}

// This represents a single message in a conversation
struct Message: Identifiable {
    // Unique ID for the message
    var id: String

    // The conversation this message belongs to
    var conversationId: String

    // The user who sent this message
    var senderId: String

    // The message text
    var text: String

    // When the message was sent
    var timestamp: Timestamp

    // Has the message been read?
    var isRead: Bool

    // Helper to get the message date
    var date: Date {
        return timestamp.dateValue()
    }

    // This helper creates a dictionary to save to Firestore
    var asFirestoreDictionary: [String: Any] {
        return [
            "conversationId": conversationId,
            "senderId": senderId,
            "text": text,
            "timestamp": timestamp,
            "isRead": isRead
        ]
    }

    // Create from Firestore data
    static func fromFirestore(id: String, data: [String: Any]) -> Message? {
        guard let conversationId = data["conversationId"] as? String,
              let senderId = data["senderId"] as? String,
              let text = data["text"] as? String else {
            return nil
        }

        let timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
        let isRead = data["isRead"] as? Bool ?? false

        return Message(
            id: id,
            conversationId: conversationId,
            senderId: senderId,
            text: text,
            timestamp: timestamp,
            isRead: isRead
        )
    }
}
