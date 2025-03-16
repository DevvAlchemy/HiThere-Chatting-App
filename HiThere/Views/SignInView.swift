//
//  SignInView.swift
//  HiThere
//
//  Created by Royal K on 2025-03-13.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct SignInView: View {
    // These variables store what the user types
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isSigningUp = false  // Controls if we're showing login or signup

    // This connects to our Firebase authentication
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // This creates our red and white angled background
                // At first Error will occur because i have to assign it's utility so moving forward i'll remember to ignore them or i can add it and just do the background but add the neede ui in the middle
                BackgroundShape()

                VStack(spacing: 25) {
                    // App title at the top
                    Text("HiThere Chat")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 50)

                    Spacer()

                    // Login form in a white card
                    VStack(spacing: 20) {
                        Text(isSigningUp ? "Create Account" : "Welcome Back") //one or the other
                            .font(.title)
                            .fontWeight(.bold)

                        // Only show username field when signing up
                        if isSigningUp {
                            TextField("Username", text: $username)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .autocapitalization(.none)
                        }

                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textContentType(.emailAddress)

                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .textContentType(isSigningUp ? .newPassword : .password)

                        // Sign in button
                        Button(action: {
                            if isSigningUp {
                                viewModel.signUp(email: email, password: password, username: username)
                            } else {
                                viewModel.signIn(email: email, password: password)
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(10)
                            } else {
                                Text(isSigningUp ? "Sign Up" : "Sign In")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(viewModel.isLoading || !isValidInput)
                        .opacity(isValidInput ? 1.0 : 0.6)

                        // Switch between login and signup
                        Button(action: {
                            withAnimation {
                                isSigningUp.toggle()
                                // Clear the form when switching modes
                                if isSigningUp {
                                    password = "" // Clear password for security
                                }
                            }
                        }) {
                            Text(isSigningUp ? "Already have an account? Sign In" : "New user? Create Account")
                                .foregroundColor(.blue)
                        }

                        // Show any error messages
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage.message)
                                .foregroundColor(.red)
                                .font(.callout)
                                .padding(.top, 10)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(25)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            // Show the main app when user is logged in
            .fullScreenCover(isPresented: $viewModel.isAuthenticated) {
                MainTabView()
                    .environmentObject(viewModel)
            }
            // Add logging for debugging state changes
            .onChange(of: viewModel.isAuthenticated) { _, newValue in
                print("Authentication state changed: \(newValue)")
            }
            // Include logging when view appears
            .onAppear {
                print("SignInView appeared, isAuthenticated: \(viewModel.isAuthenticated)")
                print("Current auth user: \(String(describing: Auth.auth().currentUser?.uid))")
            }
        }
    }

    // Check if the input is valid before enabling the button
    private var isValidInput: Bool {
        if isSigningUp {
            return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  !password.isEmpty && password.count >= 6 &&
                  !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                  !password.isEmpty
        }
    }
}

// This is our custom text field style to make inputs look pretty
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(15)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
    }
}

// This creates our red and white angled background
struct BackgroundShape: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Red upper part
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.6))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height * 0.3))
                    path.closeSubpath()
                }
                .fill(Color.red)

                // White lower part
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.3))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.6))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(Color.white)
            }
        }
        .ignoresSafeArea()
    }
}
