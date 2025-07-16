//
//  QuotesTool.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/15/25.
//
import Foundation
import FoundationModels

/// Get inspirational quotes and famous sayings
struct QuotesTool: Tool {
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient?) {
        self.httpClient = httpClient ?? HTTPClient()
    }
    
    let name = "getQuotes"
    let description = "Get inspirational quotes and famous sayings from various authors and categories"
    
    @Generable
    struct Arguments {
        @Guide(description: "Quote category: inspirational, motivational, wisdom, success, life, happiness")
        let category: QuoteCategory
        @Guide(description: "Number of quotes to retrieve (1-5)")
        let count: Int
        @Guide(description: "Specific author name (optional)")
        let author: String?
        
        init(category: QuoteCategory = .inspirational, count: Int = 1, author: String? = nil) {
            self.category = category
            self.count = min(max(count, 1), 5)
            self.author = author
        }
        
        @Generable
        enum QuoteCategory: String, CaseIterable {
            case inspirational
            case motivational
            case wisdom
            case success
            case life
            case happiness
        }
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let category = arguments.category
        let count = arguments.count
        let author = arguments.author
        
        // For demonstration, using a curated local database
        // In production, you could use APIs like:
        // - Quotable API (quotable.io)
        // - They Said So Quotes API
        // - Famous Quotes API
        
//        let quotes = getQuotesFromDatabase(category: category, count: count, author: author)
//        
//        return ToolOutput(GeneratedContent(properties: [
//            "success": true,
//            "operation_type": "quotes_retrieval",
//            "category": category.rawValue,
//            "author_filter": author,
//            "quotes_count": quotes.count,
//            "quotes": quotes.map { [
//                "text": $0.text,
//                "author": $0.author,
//                "category": $0.category
//            ]},
//            "timestamp": DateFormatter.iso8601.string(from: Date())
//        ]))
        return ToolOutput("none")
    }
    
    private struct Quote {
        let text: String
        let author: String
        let category: String
    }
}
