//
//  MainTabView.swift
//  HiThere
//
//  Created by Royal K on 2025-03-13.
//

import SwiftUI

struct MainTabView: View {
    // Access to user information
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        // Just show the conversations list for now
        // In a more complex app, I can add more tabs here
        ConversationsListView()
            .environmentObject(authViewModel)
    }
}
