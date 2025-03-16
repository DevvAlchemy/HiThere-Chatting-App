//
//  ConversationViewModel.swift
//  HiThere
//
//  Created by Royal K on 2025-03-13.
//

import Foundation
import Firebase
import FirebaseFirestore
import Combine

class ConversationsViewModel: ObservableObject {
    // Published properties update the UI when they change
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Reference to Firestore database
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // This runs when the object is destroyed
    deinit {
        // Remove the listener to prevent memory leaks
        listener?.remove()
    }

    // Fetch all conversations for a user
    func fetchConversations(for userId: String) {
        isLoading = true

        // Remove any existing listener
        listener?.remove()

        // Set up a real-time listener for changes
        // This is like having a live connection to the database
        listener = db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageDate", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.conversations = []
                    return
                }

                // Convert Firestore documents to Conversation objects
                self.conversations = documents.compactMap { document in
                    Conversation.fromFirestore(id: document.documentID, data: document.data())
                }
            }
    }

    // Create a conversation with yourself
    func createSelfChat(userId: String) {
        isLoading = true

        // First check if a self-chat already exists
        db.collection("conversations")
            .whereField("participantIds", isEqualTo: [userId, userId]) //allowing self messaging
            .whereField("isSelfChat", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                // If we already have a self-chat, don't create another one
                if let documents = snapshot?.documents, !documents.isEmpty {
                    self.isLoading = false
                    return
                }

                // Create a new self-chat conversation
                let newConversation: [String: Any] = [
                    "participantIds": [userId, userId],
                    "lastMessageText": "Send a message to yourself",
                    "lastMessageDate": FieldValue.serverTimestamp(),
                    "isSelfChat": true
                ]

                // Add the new conversation to Firestore
                self.db.collection("conversations").addDocument(data: newConversation) { error in
                    self.isLoading = false

                    if let error = error {
                        self.errorMessage = "Error creating notes: \(error.localizedDescription)"
                    }

                    // The listener will automatically update the conversations list
                }
            }
    }
}
