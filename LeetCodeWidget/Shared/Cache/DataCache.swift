//
//  DataCache.swift
//  LeetCodeWidget
//
//  Created by Suraj Van Verma
//

import Foundation

class DataCache {
    static let shared = DataCache()
    static let appGroupIdentifier = "group.com.leetcode.widget"
    static let cacheFileName = "leetcode_stats.json"
    static let cacheDateKey = "cache_date"
    
    private var fileURL: URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: DataCache.appGroupIdentifier) else {
            return nil
        }
        return containerURL.appendingPathComponent(DataCache.cacheFileName)
    }
    
    private init() {}
    
    func save(_ stats: LeetCodeStats) {
        guard let fileURL = fileURL else { return }
        
        // Convert Int keys to String keys for JSON serialization
        var calendarDict: [String: Int] = [:]
        for (key, value) in stats.submissionCalendar {
            calendarDict[String(key)] = value
        }
        
        let cacheData: [String: Any] = [
            "totalSolved": stats.totalSolved,
            "submissionCalendar": calendarDict,
            DataCache.cacheDateKey: Date().timeIntervalSince1970
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: cacheData, options: []) {
            try? jsonData.write(to: fileURL)
        }
    }
    
    func load() -> LeetCodeStats? {
        guard let fileURL = fileURL,
              let jsonData = try? Data(contentsOf: fileURL),
              let cacheData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let totalSolved = cacheData["totalSolved"] as? Int,
              let calendarDict = cacheData["submissionCalendar"] as? [String: Int] else {
            return nil
        }
        
        // Convert string keys to Int timestamps
        var calendar: [Int: Int] = [:]
        for (key, value) in calendarDict {
            if let timestamp = Int(key) {
                calendar[timestamp] = value
            }
        }
        
        return LeetCodeStats(totalSolved: totalSolved, submissionCalendar: calendar)
    }
    
    func shouldRefresh() -> Bool {
        guard let fileURL = fileURL,
              let jsonData = try? Data(contentsOf: fileURL),
              let cacheData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let cacheTimestamp = cacheData[DataCache.cacheDateKey] as? TimeInterval else {
            return true // No cache, should refresh
        }
        
        let cacheDate = Date(timeIntervalSince1970: cacheTimestamp)
        return WidgetConfiguration.shared.shouldRefresh(lastRefresh: cacheDate)
    }
    
    func getLastRefreshDate() -> Date? {
        guard let fileURL = fileURL,
              let jsonData = try? Data(contentsOf: fileURL),
              let cacheData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let cacheTimestamp = cacheData[DataCache.cacheDateKey] as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: cacheTimestamp)
    }
}

