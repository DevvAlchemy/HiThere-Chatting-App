//
//  ChatView.swift
//  HiThere
//
//  Created by Royal K on 2025-03-13.
//

import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    // The conversation we're viewing
    let conversation: Conversation

    // View model to handle chat logic
    @StateObject private var viewModel = ChatViewModel()

    // Access to user information
    @EnvironmentObject var authViewModel: AuthViewModel

    // For the message text input
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

    // For the other user's name
    @State private var otherUserName = "Chat"

    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == authViewModel.currentUser?.id
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    // This is an invisible view at the bottom we can scroll to
                    .id("bottomID")
                }
                .onChange(of: viewModel.messages.count) { _, newValue in
                    // Scroll to bottom when new messages arrive
                    withAnimation {
                        scrollView.scrollTo("bottomID", anchor: .bottom)
                    }
                }
                .onAppear {
                    // Scroll to bottom when view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            scrollView.scrollTo("bottomID", anchor: .bottom)
                        }
                    }
                }
            }

            // Message input area at the bottom
            HStack(spacing: 12) {
                // Text field for typing messages
                TextField("Message", text: $messageText)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .focused($isInputFocused)

                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .red)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color.white)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -5)
        }
        .navigationTitle(conversation.isSelfChat ? "Notes to Myself" : otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // When the view appears, load messages and get the other user's name
            viewModel.loadMessages(for: conversation.id)

            if !conversation.isSelfChat,
               let otherUserId = conversation.getOtherUserId(currentUserId: authViewModel.currentUser?.id ?? "") {
                fetchUserName(userId: otherUserId)
            }
        }
    }

    // Send a new message
    private func sendMessage() {
        // Don't send empty messages
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentUserId = authViewModel.currentUser?.id else {
            return
        }

        // Send the message
        viewModel.sendMessage(
            text: messageText,
            senderId: currentUserId,
            conversationId: conversation.id
        )

        // Clear the text field
        messageText = ""
    }

    // Fetch the other user's name
    private func fetchUserName(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            guard let document = document, document.exists,
                  let data = document.data(),
                  let username = data["username"] as? String else {
                return
            }

            // Update the title with the username
            self.otherUserName = username
        }
    }
}

// This shows individual message bubbles
struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            // Add spacing on the left or right depending on who sent the message
            if isFromCurrentUser { Spacer() }

            // The message bubble
            Text(message.text)
                .padding(12)
                .background(isFromCurrentUser ? Color.red : Color.gray.opacity(0.2))
                .foregroundColor(isFromCurrentUser ? .white : .black)
                .cornerRadius(20)
                .cornerRadius(20, corners: isFromCurrentUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                .frame(maxWidth: 280, alignment: isFromCurrentUser ? .trailing : .leading)

            if !isFromCurrentUser { Spacer() }
        }
        .padding(.vertical, 4)
    }
}

// Helper to make rounded corners only on certain sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

