//
//  ScienceFactsTool.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/15/25.
//
import Foundation
import FoundationModels

/// Get interesting science facts and information
struct ScienceFactsTool: Tool {
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient?) {
        self.httpClient = httpClient ?? HTTPClient()
    }
    
    let name = "getScienceFacts"
    let description = "Get interesting science facts and information on various scientific topics"
    
    @Generable
    struct Arguments {
        @Guide(description: "Science category: astronomy, biology, chemistry, physics, earth, general")
        let category: ScienceCategory
        @Guide(description: "Number of facts to retrieve (1-5)")
        let count: Int
        
        init(category: ScienceCategory = .general, count: Int = 1) {
            self.category = category
            self.count = min(max(count, 1), 5)
        }
        
        @Generable
        enum ScienceCategory: String, CaseIterable {
            case astronomy
            case biology
            case chemistry
            case physics
            case earth
            case general
        }
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let category = arguments.category
        let count = arguments.count
        
        // Use Numbers API for math facts as a fallback, but primarily generate science facts
        // For a real implementation, you'd use APIs like:
        // - NASA API for astronomy facts
        // - Science Museum APIs
        // - Educational APIs
        
//        let facts = generateScienceFacts(category: category, count: count)
        
//        return ToolOutput(GeneratedContent(properties: [
//            "success": true,
//            "operation_type": "science_facts",
//            "category": category.rawValue,
//            "facts_count": facts.count,
//            "facts": facts,
//            "source": "Educational Science Database",
//            "timestamp": DateFormatter.iso8601.string(from: Date())
//        ]))
        return ToolOutput("none")
    }
}
