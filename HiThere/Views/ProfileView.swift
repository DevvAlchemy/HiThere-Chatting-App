//
//  ProfileView.swift
//  HiThere
//
//  Created by Royal K on 2025-03-13.
//

import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    // Access to user information
    @EnvironmentObject var authViewModel: AuthViewModel

    // For showing the sign out confirmation
    @State private var showingSignOutAlert = false

    // For navigation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                // Profile header with picture
                VStack(spacing: 20) {
                    // Profile picture or placeholder
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 120, height: 120)

                        if let user = authViewModel.currentUser {
                            Text(user.username.prefix(1).uppercased())
                                .font(.system(size: 50))
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    }

                    // Username
                    if let user = authViewModel.currentUser {
                        Text(user.username)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                .padding(.top, 40)

                // Profile information
                VStack(spacing: 20) {
                    // Email
                    if let user = authViewModel.currentUser {
                        ProfileInfoRow(title: "Email", value: user.email)
                    }

                    // Last active status
                    if let user = authViewModel.currentUser {
                        ProfileInfoRow(
                            title: "Status",
                            value: user.isOnline ? "Online" : "Last seen \(formatDate(user.lastSeen.dateValue()))"
                        )
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.top, 30)

                Spacer()

                // Sign out button
                Button(action: {
                    showingSignOutAlert = true
                }) {
                    Text("Sign Out")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)

                // Confirmation dialog for signing out
                .alert("Sign Out", isPresented: $showingSignOutAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Sign Out", role: .destructive) {
                        authViewModel.signOut()
                    }
                } message: {
                    Text("Are you sure you want to sign out?")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    // Format the date nicely
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "today at \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

// A single row of profile information
struct ProfileInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
    }
}

