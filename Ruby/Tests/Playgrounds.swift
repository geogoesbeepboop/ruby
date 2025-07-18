//
//  Playgrounds.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/15/25.
//
import Playgrounds
import FoundationModels

#Playground {
//    let languageSession = LanguageModelSession()
    let httpClient = HTTPClient()
    var settings = ChatSettings.default

    let languageSession = LanguageModelSession(tools: [
        WeatherTool()
//        WebSearchTool(httpClient: httpClient),
//        CalculatorTool(),
//        ReminderTool(),
//        DateTimeTool(),
//                ScienceFactsTool(httpClient: httpClient),
//        NewsTool(httpClient: httpClient),
//                QuotesTool(httpClient: httpClient)
    ]
//    ,instructions: settings.selectedPersona.systemPrompt
    )
    
    do {
        let response = try await languageSession.respond(
            to: "Create an itinerary to San Fransisco for 1 week?TT"
        )
    } catch {
        
    }
    
//    // Prewarm the language model session for better performance
//    print("🔥 [ChatStore] Prewarming language model session...")
//    languageSession?.prewarm()
}
