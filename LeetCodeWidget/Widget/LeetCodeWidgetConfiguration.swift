//
//  LeetCodeWidgetConfiguration.swift
//  LeetCodeWidget
//
//  Created by Suraj Van Verma
//

import AppIntents
import WidgetKit

struct LeetCodeWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "LeetCode Widget Configuration"
    static var description = IntentDescription("Configure your LeetCode username and sync frequency")
    
    @Parameter(title: "LeetCode Username", description: "Your LeetCode username", inputOptions: String.IntentInputOptions(capitalizationType: .none, autocorrect: false, smartQuotes: false, smartDashes: false))
    var username: String?
    
    @Parameter(title: "Sync Frequency", description: "How often to sync data")
    var syncFrequency: SyncFrequencyAppEnum?
    
    init(username: String?, syncFrequency: SyncFrequencyAppEnum?) {
        self.username = username
        self.syncFrequency = syncFrequency
    }
    
    init() {
        let config = WidgetConfiguration.shared
        self.username = config.username
        self.syncFrequency = SyncFrequencyAppEnum(rawValue: config.syncFrequency.rawValue) ?? .daily
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("LeetCode Widget: \(\.$username) - \(\.$syncFrequency)")
    }
}

enum SyncFrequencyAppEnum: String, AppEnum {
    case live
    case hourly
    case daily
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Sync Frequency"
    
    static var caseDisplayRepresentations: [SyncFrequencyAppEnum: DisplayRepresentation] = [
        .live: "Live",
        .hourly: "Every Hour",
        .daily: "Every Day"
    ]
}

