//
//  DateTimeTool.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/15/25.
//
import Foundation
import FoundationModels

struct DateTimeTool: Tool {
    let name = "getDateTime"
    let description = "Get current date, time, and timezone information"
    
    @Generable
    struct Arguments {
        @Guide(description: "Timezone identifier (e.g., 'America/New_York', 'UTC')")
        let timezone: String?
        @Guide(description: "Date format style: 'short', 'medium', 'long', 'full'")
        let format: String
        
        init(timezone: String? = nil, format: String = "medium") {
            self.timezone = timezone
            self.format = format
        }
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let timezone = arguments.timezone
        let format = arguments.format
        
        let formatter = DateFormatter()
        
        if let timezone = timezone, let tz = TimeZone(identifier: timezone) {
            formatter.timeZone = tz
        }
        
        switch format {
        case "short":
            formatter.dateStyle = .short
            formatter.timeStyle = .short
        case "long":
            formatter.dateStyle = .long
            formatter.timeStyle = .long
        case "full":
            formatter.dateStyle = .full
            formatter.timeStyle = .full
        default:
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
        }
        
        let currentDate = Date()
        let formattedDate = formatter.string(from: currentDate)
        
        return ToolOutput(GeneratedContent(properties: [
            "formatted_datetime": formattedDate,
            "iso_datetime": DateFormatter.iso8601.string(from: currentDate),
            "timestamp": currentDate.timeIntervalSince1970,
            "timezone": formatter.timeZone.identifier,
            "format_style": format,
            "operation_type": "datetime_retrieval"
        ]))
    }
}
