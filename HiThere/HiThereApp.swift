//
//  HiThereApp.swift
//  HiThere
//
//  Created by Royal K on 2025-03-13.
//

import SwiftUI
import Firebase
import FirebaseCore

@main
struct HiThere: App {
    // Register the app delegate for Firebase setup and debugging
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    // StateObject for the authentication view model
    @StateObject private var authViewModel = AuthViewModel()

    // Initialize Firebase and setup messaging when the app starts
    init() {
        // Configure Firebase
        FirebaseApp.configure()

        // Setup messaging - we'll connect the auth model later
        MessagingManager.shared.setup()

        print("App initialized with Firebase")
    }

    var body: some Scene {
        WindowGroup {
            // Based on authentication state, show either sign-in or main content
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(authViewModel)
                        .onAppear {
                            // Connect auth model to messaging manager when logged in
                            MessagingManager.shared.authViewModel = authViewModel
                        }
                } else {
                    SignInView()
                        .environmentObject(authViewModel)
                }
            }
            // Add state change logging for debugging
            .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
                print("App root: Authentication state changed from \(oldValue) to \(newValue)")

                // If user is now authenticated, connect the auth model to messaging
                if newValue {
                    MessagingManager.shared.authViewModel = authViewModel
                }
            }
        }
    }
}
