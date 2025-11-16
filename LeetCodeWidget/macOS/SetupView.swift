//
//  SetupView.swift
//  LeetCodeWidget macOS
//
//  Created by Suraj Van Verma
//

import SwiftUI

struct SetupView: View {
    @Binding var username: String
    @State private var tempUsername: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var onComplete: () -> Void
    
    private var isFirstTime: Bool {
        username.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: isFirstTime ? "chart.bar.fill" : "person.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                
                Text(isFirstTime ? "Welcome to LeetCode Widget" : "Change Username")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(isFirstTime ? "Enter your LeetCode username to get started" : "Update your LeetCode username")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("LeetCode Username")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                
                TextField("Enter your LeetCode username", text: $tempUsername)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.large)
                    .autocorrectionDisabled()
                    .onSubmit {
                        if !tempUsername.isEmpty {
                            saveUsername()
                        }
                    }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 32)
            
            Button(action: saveUsername) {
                Label(isFirstTime ? "Continue" : "Save", systemImage: isFirstTime ? "arrow.right" : "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(tempUsername.isEmpty || isSubmitting)
            .padding(.horizontal, 32)
            
            Spacer()
            
            Text("Created by Suraj Van Verma")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.quaternary)
                .padding(.bottom, 20)
        }
        .frame(minWidth: 480, minHeight: 360)
        .onAppear {
            tempUsername = username
        }
    }
    
    private func saveUsername() {
        guard !tempUsername.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a valid username"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        // Save username
        username = tempUsername.trimmingCharacters(in: .whitespaces)
        WidgetConfiguration.shared.username = username
        
        // Test the username by fetching data
        LeetCodeAPI.shared.fetchStats(username: username) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    onComplete()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

