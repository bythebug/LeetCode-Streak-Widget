//
//  WidgetConfiguration.swift
//  LeetCodeWidget
//
//  Created by Suraj Van Verma
//

import Foundation

enum SyncFrequency: String, Codable, CaseIterable {
    case live = "live"
    case hourly = "hourly"
    case daily = "daily"
    
    var displayName: String {
        switch self {
        case .live: return "Live"
        case .hourly: return "Every Hour"
        case .daily: return "Every Day"
        }
    }
    
    var refreshInterval: TimeInterval {
        switch self {
        case .live: return 60 // 1 minute
        case .hourly: return 3600 // 1 hour
        case .daily: return 86400 // 1 day
        }
    }
}

class WidgetConfiguration {
    static let shared = WidgetConfiguration()
    static let appGroupIdentifier = "group.com.leetcode.widget"
    static let usernameKey = "leetcode_username"
    static let syncFrequencyKey = "sync_frequency"
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: WidgetConfiguration.appGroupIdentifier)
    }
    
    private init() {}
    
    var username: String {
        get {
            userDefaults?.string(forKey: WidgetConfiguration.usernameKey) ?? ""
        }
        set {
            userDefaults?.set(newValue, forKey: WidgetConfiguration.usernameKey)
        }
    }
    
    var syncFrequency: SyncFrequency {
        get {
            if let rawValue = userDefaults?.string(forKey: WidgetConfiguration.syncFrequencyKey),
               let frequency = SyncFrequency(rawValue: rawValue) {
                return frequency
            }
            return .daily // Default
        }
        set {
            userDefaults?.set(newValue.rawValue, forKey: WidgetConfiguration.syncFrequencyKey)
        }
    }
    
    func shouldRefresh(lastRefresh: Date?) -> Bool {
        guard let lastRefresh = lastRefresh else { return true }
        
        let now = Date()
        let timeSinceRefresh = now.timeIntervalSince(lastRefresh)
        return timeSinceRefresh >= syncFrequency.refreshInterval
    }
}

