//
//  SystemLogsView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 31/08/2025.
//

import SwiftUI

struct SystemLogsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        List {
            ForEach(dataManager.systemLogs) { log in
                VStack(alignment: .leading) {
                    Text(log.message)
                        .font(.body)
                    Text(log.date.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("System Logs")
    }
}
