//
//  ChatViewModel.swift
//  HiThere
//
//  Created by Royal K on 2025-03-13.
//

import Foundation
import Firebase
import FirebaseFirestore

class ChatViewModel: ObservableObject {
    // Published properties update the UI when they change
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Reference to Firestore database
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // Clean up when this object is destroyed
    deinit {
        // Remove the listener to prevent memory leaks and this will help me avoid problems from accumulating
        listener?.remove()
    }

    // Load all messages for a conversation
    func loadMessages(for conversationId: String) {
        isLoading = true

        // Remove any existing listener
        listener?.remove()

        // Set up a real-time listener for messages
        listener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Error loading messages: \(error.localizedDescription)"
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.messages = []
                    return
                }

                // Convert Firestore documents to Message objects
                self.messages = documents.compactMap { document in
                    Message.fromFirestore(id: document.documentID, data: document.data())
                }

                // Mark messages as read
                self.markMessagesAsRead(in: conversationId)
            }
    }

    // Send a new message
    func sendMessage(text: String, senderId: String, conversationId: String) {
        // Create a new message
        let newMessage: [String: Any] = [
            "text": text,
            "senderId": senderId,
            "conversationId": conversationId,
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false
        ]

        // Reference to the conversation and messages collection
        let conversationRef = db.collection("conversations").document(conversationId)

        // Use a batch to update both the conversation and add the message
        let batch = db.batch()

        // Add the new message
        let newMessageRef = conversationRef.collection("messages").document()
        batch.setData(newMessage, forDocument: newMessageRef)

        // Update the conversation's last message info
        batch.updateData([
            "lastMessageText": text,
            "lastMessageDate": FieldValue.serverTimestamp()
        ], forDocument: conversationRef)

        // Commit all the changes at once
        batch.commit { [weak self] error in
            if let error = error {
                self?.errorMessage = "Error sending message: \(error.localizedDescription)"
            }
        }
    }

    // Mark messages as read
    private func markMessagesAsRead(in conversationId: String) {
        // This function would mark messages as read when the user views them
        // for now i will skip it and focus on other things, will add this in real app tho
    }
}
