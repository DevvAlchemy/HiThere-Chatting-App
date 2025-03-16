//
//  ConversationsListView.swift
//  HiThere
//
//  Created by Royal K on 2025-03-13.
//

import SwiftUI
import FirebaseFirestore

struct ConversationsListView: View {
    // Connect to our view model that handles the data
    @StateObject private var viewModel = ConversationsViewModel()

    // Get access to the user's information
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                // Show a loading spinner when loading conversations
                if viewModel.isLoading {
                    ProgressView("Loading conversations...")
                }
                // Show a message when there are no conversations
                else if viewModel.conversations.isEmpty {
                    VStack(spacing: 20) {
                        Text("No conversations yet")
                            .font(.title)
                            .foregroundColor(.gray)

                        // Button to start a self-chat
                        Button(action: {
                            guard let userId = authViewModel.currentUser?.id else { return }
                            viewModel.createSelfChat(userId: userId)
                        }) {
                            Label("Message Yourself", systemImage: "bubble.left.and.bubble.right")
                                .font(.headline)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                // Show the list of conversations
                else {
                    List {
                        // Self-chat button at the top i'll use this for test and also for saving notes
                        Button(action: {
                            print("Message Yourself button tapped!") //will remove later. keeping for development testing
                            guard let userId = authViewModel.currentUser?.id else { return }
                            print("User ID available: \(userId)") //will remove later too
                            viewModel.createSelfChat(userId: userId)
                        }) {
                            HStack {
                                Image(systemName: "note.text")
                                    .font(.title2)
                                    .foregroundColor(.red)

                                Text("Notes to Myself")
                                    .fontWeight(.bold)
                            }
                            .padding(.vertical, 8)
                        }

                        // List of all conversations
                        ForEach(viewModel.conversations) { conversation in
                            NavigationLink(destination:
                                ChatView(conversation: conversation)
                                    .environmentObject(authViewModel)
                            ) {
                                ConversationRow(
                                    conversation: conversation,
                                    currentUserId: authViewModel.currentUser?.id ?? ""
                                )
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        if let userId = authViewModel.currentUser?.id {
                            viewModel.fetchConversations(for: userId)
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView().environmentObject(authViewModel)) {
                        Image(systemName: "person.circle")
                            .font(.title3)
                    }
                }
            }
            .onAppear {
                // Load conversations when the view appears
                if let userId = authViewModel.currentUser?.id {
                    viewModel.fetchConversations(for: userId)
                }
            }
            // If the user changes, reload conversations
            .onChange(of: authViewModel.currentUser?.id) { oldValue, newValue in
                if let userId = newValue {
                    viewModel.fetchConversations(for: userId)
                }
            }
        }
    }
}

// This is the row that shows each conversation in the list
struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: String

    // We need to store username data for all users
    @State private var otherUserName: String = "Loading..."

    var body: some View {
        HStack(spacing: 15) {
            // Profile picture or placeholder
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 50, height: 50)

                // First letter of username
                Text(otherUserName.prefix(1).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            VStack(alignment: .leading, spacing: 5) {
                // Username
                Text(conversation.isSelfChat ? "Notes to Myself" : otherUserName)
                    .font(.headline)

                // Preview of last message
                Text(conversation.lastMessageText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            // Time of last message
            Text(formatDate(conversation.lastMessageDate.dateValue()))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .onAppear {
            // Getting the other user's name when this row appears
            if !conversation.isSelfChat {
                if let otherUserId = conversation.getOtherUserId(currentUserId: currentUserId) {
                    fetchUserName(userId: otherUserId)
                }
            }
        }
    }

    // Get the username for a user ID
    private func fetchUserName(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            guard let document = document, document.exists,
                  let data = document.data(),
                  let username = data["username"] as? String else {
                return
            }

            // Update the username
            self.otherUserName = username
        }
    }

    // Format the date nicely
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            // Today: show the time
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            // Yesterday
            return "Yesterday"
        } else {
            //if older tjan yesterday then  show the date
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yy"
            return formatter.string(from: date)
        }
    }
}
