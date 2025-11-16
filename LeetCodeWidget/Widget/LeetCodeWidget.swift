//
//  LeetCodeWidget.swift
//  LeetCodeWidget
//
//  Created by Suraj Van Verma
//

import WidgetKit
import SwiftUI

struct LeetCodeWidgetEntry: TimelineEntry {
    let date: Date
    let stats: LeetCodeStats?
    let error: String?
}

struct LeetCodeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LeetCodeWidgetEntry {
        LeetCodeWidgetEntry(
            date: Date(),
            stats: LeetCodeStats(totalSolved: 150, submissionCalendar: [:]),
            error: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LeetCodeWidgetEntry) -> Void) {
        let stats = DataCache.shared.load()
        let entry = LeetCodeWidgetEntry(
            date: Date(),
            stats: stats,
            error: nil
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LeetCodeWidgetEntry>) -> Void) {
        let currentDate = Date()
        let config = WidgetConfiguration.shared
        let refreshInterval = config.syncFrequency.refreshInterval
        let refreshDate = currentDate.addingTimeInterval(refreshInterval)
        
        // Check if we should refresh based on sync frequency
        let shouldRefresh = {
            if let lastRefresh = DataCache.shared.getLastRefreshDate() {
                let timeSinceRefresh = currentDate.timeIntervalSince(lastRefresh)
                return timeSinceRefresh >= refreshInterval
            }
            return true
        }()
        
        // Try to fetch new data if cache is stale
        if shouldRefresh {
            LeetCodeAPI.shared.fetchStats { result in
                let entry: LeetCodeWidgetEntry
                
                switch result {
                case .success(let stats):
                    DataCache.shared.save(stats)
                    entry = LeetCodeWidgetEntry(date: currentDate, stats: stats, error: nil)
                case .failure(let error):
                    // Use cached data if available, otherwise show error
                    if let cachedStats = DataCache.shared.load() {
                        entry = LeetCodeWidgetEntry(date: currentDate, stats: cachedStats, error: nil)
                    } else {
                        let errorMessage = error.localizedDescription
                        entry = LeetCodeWidgetEntry(date: currentDate, stats: nil, error: errorMessage)
                    }
                }
                
                let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                completion(timeline)
            }
        } else {
            // Use cached data
            let stats = DataCache.shared.load()
            let entry = LeetCodeWidgetEntry(
                date: currentDate,
                stats: stats,
                error: nil
            )
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct LeetCodeWidgetView: View {
    var entry: LeetCodeWidgetEntry
    
    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text("LeetCode Progress")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            
            if let stats = entry.stats {
                // Subtitle
                Text("Solved \(stats.totalSolved) problems")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                
                // 7x7 Grid
                GridView(calendar: stats.submissionCalendar)
                    .padding(.top, 6)
            } else if let error = entry.error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.red)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct GridView: View {
    let calendar: [Int: Int]
    
    // Calculate the last 49 days
    private var gridData: [Int] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var data: [Int] = []
        
        // Get last 49 days (including today)
        for i in 0..<49 {
            if let date = cal.date(byAdding: .day, value: -i, to: today) {
                let startOfDay = cal.startOfDay(for: date)
                let timestamp = Int(startOfDay.timeIntervalSince1970)
                let count = self.calendar[timestamp] ?? 0
                data.append(count)
            } else {
                data.append(0)
            }
        }
        
        return data.reversed() // Oldest to newest (left to right, top to bottom)
    }
    
    var body: some View {
        let columns = Array(repeating: GridItem(.fixed(8), spacing: 2), count: 7)
        
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(0..<49, id: \.self) { index in
                let count = gridData[index]
                let color = count > 0 ? Color.green : Color.gray.opacity(0.3)
                
                Rectangle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct LeetCodeWidget: Widget {
    let kind: String = "LeetCodeWidget"
    
    var body: StaticConfiguration<LeetCodeWidgetView> {
        StaticConfiguration(kind: kind, provider: LeetCodeWidgetProvider()) { entry in
            LeetCodeWidgetView(entry: entry)
        }
    }
}

