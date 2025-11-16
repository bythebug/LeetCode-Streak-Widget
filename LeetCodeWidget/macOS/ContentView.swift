//
//  ContentView.swift
//  LeetCodeWidget macOS
//
//  Created by Suraj Van Verma
//

import SwiftUI

struct ContentView: View {
    @State private var stats: LeetCodeStats?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Loading...")
                        .controlSize(.large)
                } else if let stats = stats {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LeetCode Progress")
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            
                            Text("Solved \(stats.totalSolved) problems")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add the widget to your desktop to see your submission calendar!")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.tertiary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Created by Suraj Van Verma")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(.quaternary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                } else if let error = errorMessage {
                    Label("Error: \(error)", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.system(size: 14, design: .rounded))
                }
                
                Button(action: refreshData) {
                    Label("Refresh Data", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isLoading)
            }
            .padding(32)
            .frame(minWidth: 480, minHeight: 360)
        }
        .onAppear {
            loadCachedData()
            if DataCache.shared.shouldRefresh() {
                refreshData()
            }
        }
    }
    
    private func loadCachedData() {
        stats = DataCache.shared.load()
    }
    
    private func refreshData() {
        isLoading = true
        errorMessage = nil
        
        let config = WidgetConfiguration.shared
        LeetCodeAPI.shared.fetchStats(username: config.username) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let newStats):
                    self.stats = newStats
                    DataCache.shared.save(newStats)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    // Try to load cached data as fallback
                    self.stats = DataCache.shared.load()
                }
            }
        }
    }
}

