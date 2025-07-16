//
//  ReminderTool.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/15/25.
//
import Foundation
import FoundationModels
import EventKit
/// Create and manage reminders
struct ReminderTool: Tool {
    let name = "createReminder"
    let description = "Create a reminder with title, notes, and optional due date"
    
    @Generable
    struct Arguments {
        @Guide(description: "Title of the reminder")
        let title: String
        @Guide(description: "Additional notes for the reminder")
        let notes: String
        @Guide(description: "Due date in ISO 8601 format (optional)")
        let dueDate: String?
        
        init(title: String, notes: String = "", dueDate: String? = nil) {
            self.title = title
            self.notes = notes
            self.dueDate = dueDate
        }
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let title = arguments.title
        let notes = arguments.notes
        let dueDate = arguments.dueDate
        
        // Use EventKit to create system reminders
        let eventStore = EKEventStore()
        
        // Request permission to access reminders
        let authStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        switch authStatus {
        case .notDetermined:
            // Request access
            let granted = try await eventStore.requestAccess(to: .reminder)
            if !granted {
                return ToolOutput(GeneratedContent(properties: [
                    "error": "Permission denied",
                    "operation_type": "reminder_creation",
                    "message": "Permission denied to access reminders. Please grant access in Settings.",
                    "timestamp": DateFormatter.iso8601.string(from: Date())
                ]))
            }
        case .denied, .restricted:
            return ToolOutput(GeneratedContent(properties: [
                "error": "Permission denied",
                "operation_type": "reminder_creation",
                "message": "Permission denied to access reminders. Please grant access in Settings.",
                "timestamp": DateFormatter.iso8601.string(from: Date())
            ]))
        case .authorized:
            break
        @unknown default:
            return ToolOutput(GeneratedContent(properties: [
                "error": "Unknown authorization status",
                "operation_type": "reminder_creation",
                "message": "Unknown authorization status for reminders.",
                "timestamp": DateFormatter.iso8601.string(from: Date())
            ]))
        }
        
        // Get default reminder calendar
        guard let defaultCalendar = eventStore.defaultCalendarForNewReminders() else {
            return ToolOutput(GeneratedContent(properties: [
                "error": "No default calendar",
                "operation_type": "reminder_creation",
                "message": "No default reminders calendar found.",
                "timestamp": DateFormatter.iso8601.string(from: Date())
            ]))
        }
        
        // Create reminder
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes.isEmpty ? nil : notes
        reminder.calendar = defaultCalendar
        
        // Set due date if provided
        if let dueDateString = dueDate {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let parsedDate = dateFormatter.date(from: dueDateString) {
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: parsedDate)
            } else {
                // Try simpler date format
                let simpleDateFormatter = DateFormatter()
                simpleDateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                if let parsedDate = simpleDateFormatter.date(from: dueDateString) {
                    reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: parsedDate)
                }
            }
        }
        
        // Save reminder
        do {
            try eventStore.save(reminder, commit: true)
            
            return ToolOutput(GeneratedContent(properties: [
                "success": true,
                "operation_type": "reminder_creation",
                "title": title,
                "notes": notes.isEmpty ? nil : notes,
                "due_date": dueDate,
                "reminder_id": reminder.calendarItemIdentifier,
                "calendar_name": defaultCalendar.title,
                "message": "Reminder successfully created and added to your default reminders list",
                "timestamp": DateFormatter.iso8601.string(from: Date())
            ]))
            
        } catch {
            return ToolOutput(GeneratedContent(properties: [
                "error": "Save failed",
                "operation_type": "reminder_creation",
                "title": title,
                "message": error.localizedDescription,
                "timestamp": DateFormatter.iso8601.string(from: Date())
            ]))
        }
    }
}
