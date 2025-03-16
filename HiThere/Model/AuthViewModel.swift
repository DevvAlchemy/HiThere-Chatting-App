//
//  AuthViewModel.swift
//  HiThere
//
//  Created by Royal K on 2025-03-13.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

// This is a simple error struct we can use to show error messages
struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

// This class connects our app to Firebase Authentication
class AuthViewModel: ObservableObject {
    // These published variables update the UI automatically when they change
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: ErrorMessage?

    // When this class is created, check if the user is already logged in
    init() {
        // Check if a user is already signed in
        if let firebaseUser = Auth.auth().currentUser {
            self.isAuthenticated = true
            self.fetchUserProfile(userId: firebaseUser.uid)
        }

        // Listen for auth changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    // User is signed in
                    print("User signed in: \(user.uid)")
                    self?.isAuthenticated = true
                    self?.fetchUserProfile(userId: user.uid)
                } else {
                    // User is signed out
                    print("User signed out")
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
                self?.isLoading = false
            }
        }
    }

    // Sign in with email and password
    func signIn(email: String, password: String) {
        // Check that email and password aren't empty
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            errorMessage = ErrorMessage(message: "Please fill in all fields")
            return
        }

        isLoading = true
        print("Attempting to sign in with email: \(email)")

        // Try to sign in with Firebase
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Something went wrong
                    print("Sign in error: \(error.localizedDescription)")
                    self?.errorMessage = ErrorMessage(message: error.localizedDescription)
                    self?.isLoading = false
                    return
                }

                print("Sign in successful")

                // If successful, the state listener will update isAuthenticated
                // But we'll set it here too for safety
                if let userId = result?.user.uid {
                    self?.isAuthenticated = true
                    self?.fetchUserProfile(userId: userId)
                }
            }
        }
    }

    // Create a new account
    func signUp(email: String, password: String, username: String) {
        // Check that all fields aren't empty
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty,
              !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = ErrorMessage(message: "Please fill in all fields")
            return
        }

        isLoading = true
        print("Attempting to create account with email: \(email)")

        // Try to create account with Firebase
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                // Something went wrong
                DispatchQueue.main.async {
                    print("Account creation error: \(error.localizedDescription)")
                    self?.errorMessage = ErrorMessage(message: error.localizedDescription)
                    self?.isLoading = false
                }
                return
            }

            print("Account created successfully")

            guard let userId = result?.user.uid else {
                DispatchQueue.main.async {
                    print("Could not get user ID after account creation")
                    self?.errorMessage = ErrorMessage(message: "Could not create user")
                    self?.isLoading = false
                }
                return
            }

            // Create a profile for the new user in Firestore
            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "username": username,
                "email": email,
                "createdAt": FieldValue.serverTimestamp(),
                "lastSeen": FieldValue.serverTimestamp(),
                "photoURL": ""
            ]

            // Save the user data to Firestore
            db.collection("users").document(userId).setData(userData) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error saving user data: \(error.localizedDescription)")
                        self?.errorMessage = ErrorMessage(message: error.localizedDescription)
                        self?.isLoading = false
                        return
                    }

                    print("User data saved successfully")

                    // Set authentication state manually
                    self?.isAuthenticated = true

                    // Create a User object directly (don't wait for the listener)
                    self?.currentUser = User(
                        id: userId,
                        username: username,
                        email: email,
                        photoURL: "",
                        lastSeen: Timestamp(date: Date())
                    )

                    self?.isLoading = false
                }
            }
        }
    }

    // Sign out the current user
    func signOut() {
        do {
            try Auth.auth().signOut()
            // Set these directly rather than waiting for the listener
            self.isAuthenticated = false
            self.currentUser = nil
            print("User signed out successfully")
        } catch {
            errorMessage = ErrorMessage(message: "Error signing out: \(error.localizedDescription)")
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    // Get user information from Firestore
    func fetchUserProfile(userId: String) {
        print("Fetching user profile for ID: \(userId)")
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists else {
                print("User document doesn't exist for ID: \(userId)")
                return
            }

            let data = document.data() ?? [:]
            print("User data retrieved: \(data)")

            // Update user's "last seen" time
            self.updateLastSeen(userId: userId)

            // Create a User object from the Firestore data
            DispatchQueue.main.async {
                self.currentUser = User(
                    id: userId,
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    photoURL: data["photoURL"] as? String ?? "",
                    lastSeen: data["lastSeen"] as? Timestamp ?? Timestamp()
                )

                print("User profile updated: \(String(describing: self.currentUser?.username))")
            }
        }
    }

    // Update when the user was last active
    private func updateLastSeen(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "lastSeen": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error updating last seen: \(error.localizedDescription)")
            }
        }
    }
}
