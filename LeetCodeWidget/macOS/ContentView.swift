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
    @State private var username: String = ""
    @State private var showSetup = false
    
    var body: some View {
        NavigationStack {
            if showSetup {
                SetupView(username: $username) {
                    showSetup = false
                    loadCachedData()
                    refreshData()
                }
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        if isLoading {
                            ProgressView("Loading...")
                                .controlSize(.large)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else if let stats = stats {
                            VStack(alignment: .leading, spacing: 24) {
                                // Header Section
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("LeetCode Progress")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    
                                    Text("Solved \(stats.totalSolved) problems")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(.secondary)
                                    
                                    if !username.isEmpty {
                                        Text("Username: \(username)")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(.tertiary)
                                            .padding(.top, 2)
                                    }
                                }
                                
                                // Calendar Section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Submission Calendar (Last 12 Months)")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    
                                    YearCalendarView(calendar: stats.submissionCalendar)
                                    
                                    // Legend
                                    HStack(spacing: 20) {
                                        HStack(spacing: 6) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.green)
                                                .frame(width: 12, height: 12)
                                            Text("Has submissions")
                                                .font(.system(size: 11, design: .rounded))
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        HStack(spacing: 6) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 12, height: 12)
                                            Text("No submissions")
                                                .font(.system(size: 11, design: .rounded))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else if let error = errorMessage {
                            VStack(spacing: 16) {
                                Label("Error: \(error)", systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(.red)
                                    .font(.system(size: 14, design: .rounded))
                                
                                Button(action: refreshData) {
                                    Label("Try Again", systemImage: "arrow.clockwise")
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }
                        
                        // Action buttons
                        VStack(spacing: 10) {
                            Button(action: refreshData) {
                                Label("Refresh Data", systemImage: "arrow.clockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(isLoading)
                            
                            Button(action: {
                                showSetup = true
                            }) {
                                Label("Change Username", systemImage: "person.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                        }
                        .padding(.top, 8)
                        
                        // Footer
                        HStack {
                            Spacer()
                            Text("Created by Suraj Van Verma")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.quaternary)
                            Spacer()
                        }
                        .padding(.top, 16)
                    }
                    .padding(28)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 800)
        .onAppear {
            checkSetup()
        }
    }
    
    private func checkSetup() {
        let config = WidgetConfiguration.shared
        username = config.username
        
        if username.isEmpty {
            showSetup = true
        } else {
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
        let leetCodeUsername = config.username.isEmpty ? username : config.username
        
        guard !leetCodeUsername.isEmpty else {
            showSetup = true
            isLoading = false
            return
        }
        
        LeetCodeAPI.shared.fetchStats(username: leetCodeUsername) { result in
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

// Year Calendar View (organized by day of week like LeetCode)
struct YearCalendarView: View {
    let calendar: [Int: Int]
    
    private var monthsData: [(name: String, weeks: [[Int]])] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        // Get date 12 months ago
        guard let twelveMonthsAgo = cal.date(byAdding: .month, value: -12, to: today) else {
            return []
        }
        
        // Find the first day of the month that contains twelveMonthsAgo
        let startComponents = cal.dateComponents([.year, .month], from: twelveMonthsAgo)
        guard let firstDayOfStartMonth = cal.date(from: startComponents) else {
            return []
        }
        
        var months: [(name: String, weeks: [[Int]])] = []
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM yyyy"
        
        // Process 12 months
        for monthOffset in 0..<12 {
            guard let monthStart = cal.date(byAdding: .month, value: monthOffset, to: firstDayOfStartMonth) else {
                continue
            }
            
            let monthName = monthFormatter.string(from: monthStart)
            let monthComponents = cal.dateComponents([.year, .month], from: monthStart)
            
            // Find the first and last day of this month
            guard let firstDayOfMonth = cal.date(from: monthComponents),
                  let lastDayOfMonth = cal.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth) else {
                continue
            }
            
            // Find the Sunday of the week containing the first day of month
            let monthFirstWeekday = cal.component(.weekday, from: firstDayOfMonth) - 1 // 0=Sunday
            guard let monthWeekStart = cal.date(byAdding: .day, value: -monthFirstWeekday, to: firstDayOfMonth) else {
                continue
            }
            
            // Calculate how many weeks we need for this month
            let daysInMonth = cal.dateComponents([.day], from: firstDayOfMonth, to: lastDayOfMonth).day ?? 0
            let weeksNeeded = Int(ceil(Double(monthFirstWeekday + daysInMonth + 1) / 7.0))
            
            // Transposed: columns = days of week (7 columns), rows = weeks (fill top to bottom)
            // Each column represents a day of week, filled vertically
            var daysOfWeek: [[Int]] = Array(repeating: [], count: 7)
            
            for week in 0..<weeksNeeded {
                for dayOfWeek in 0..<7 {
                    let daysOffset = week * 7 + dayOfWeek
                    if let date = cal.date(byAdding: .day, value: daysOffset, to: monthWeekStart) {
                        // Only include dates within this month and before today
                        if date >= firstDayOfMonth && date <= lastDayOfMonth && date <= today {
                            let startOfDay = cal.startOfDay(for: date)
                            let timestamp = Int(startOfDay.timeIntervalSince1970)
                            let count = self.calendar[timestamp] ?? 0
                            daysOfWeek[dayOfWeek].append(count)
                        } else if date < firstDayOfMonth || date > lastDayOfMonth {
                            daysOfWeek[dayOfWeek].append(-1) // Outside month range
                        } else {
                            daysOfWeek[dayOfWeek].append(0) // Future date
                        }
                    } else {
                        daysOfWeek[dayOfWeek].append(-1)
                    }
                }
            }
            
            // Convert to weeks format for display (but transposed)
            var weeks: [[Int]] = []
            let maxRows = daysOfWeek.map { $0.count }.max() ?? 0
            for row in 0..<maxRows {
                var weekData: [Int] = []
                for col in 0..<7 {
                    if row < daysOfWeek[col].count {
                        weekData.append(daysOfWeek[col][row])
                    } else {
                        weekData.append(-1)
                    }
                }
                weeks.append(weekData)
            }
            
            months.append((name: monthName, weeks: weeks))
        }
        
        return months
    }
    
    var body: some View {
        // Organize months in a grid: 3 columns, 4 rows
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
        
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(Array(monthsData.enumerated()), id: \.offset) { index, month in
                VStack(alignment: .leading, spacing: 8) {
                    // Month label
                    Text(month.name)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 2)
                    
                    // Month grid - rows = weeks, columns = days of week (7 columns)
                    let gridColumns = Array(repeating: GridItem(.fixed(12), spacing: 2), count: 7)
                    
                    LazyVGrid(columns: gridColumns, spacing: 2) {
                        ForEach(0..<month.weeks.count * 7, id: \.self) { gridIndex in
                            let week = gridIndex / 7
                            let day = gridIndex % 7
                            
                            if week < month.weeks.count && day < month.weeks[week].count {
                                let count = month.weeks[week][day]
                                
                                if count == -1 {
                                    // Outside month range - show transparent
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.clear)
                                        .frame(width: 12, height: 12)
                                } else {
                                    let color = count > 0 ? Color.green : Color.gray.opacity(0.25)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(color)
                                        .frame(width: 12, height: 12)
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.clear)
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
        .padding(20)
    }
}

