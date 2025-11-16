//
//  LeetCodeData.swift
//  LeetCodeWidget
//
//  Created by Suraj Van Verma
//

import Foundation

struct LeetCodeResponse: Codable {
    let data: LeetCodeData
    
    struct LeetCodeData: Codable {
        let matchedUser: MatchedUser?
        
        struct MatchedUser: Codable {
            let submissionCalendar: String
            let submitStats: SubmitStats
            
            struct SubmitStats: Codable {
                let acSubmissionNum: [ACSubmission]
                
                struct ACSubmission: Codable {
                    let difficulty: String
                    let count: Int
                }
            }
        }
    }
}

struct LeetCodeStats {
    let totalSolved: Int
    let submissionCalendar: [Int: Int] // timestamp -> count
    
    static func from(_ response: LeetCodeResponse) -> LeetCodeStats? {
        guard let matchedUser = response.data.matchedUser else { return nil }
        
        let totalSolved = matchedUser.submitStats.acSubmissionNum.first?.count ?? 0
        
        // Parse submissionCalendar JSON string
        let calendarString = matchedUser.submissionCalendar
        guard let calendarData = calendarString.data(using: .utf8),
              let calendarDict = try? JSONDecoder().decode([String: Int].self, from: calendarData) else {
            return LeetCodeStats(totalSolved: totalSolved, submissionCalendar: [:])
        }
        
        // Convert string keys to Int timestamps and normalize to start of day
        var calendar: [Int: Int] = [:]
        let cal = Calendar.current
        
        for (key, value) in calendarDict {
            if let timestamp = Int(key) {
                // Normalize timestamp to start of day for easier matching
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                let startOfDay = cal.startOfDay(for: date)
                let normalizedTimestamp = Int(startOfDay.timeIntervalSince1970)
                
                // Sum up counts for the same day (in case there are multiple entries)
                calendar[normalizedTimestamp] = (calendar[normalizedTimestamp] ?? 0) + value
            }
        }
        
        return LeetCodeStats(totalSolved: totalSolved, submissionCalendar: calendar)
    }
}

