//
//  WebSearchTool.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/15/25.
//
import Foundation
import FoundationModels
/// Search and retrieve information from the web
struct WebSearchTool: Tool {
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient?) {
        self.httpClient = httpClient ?? HTTPClient()
    }
    let name = "webSearch"
    let description = "Search the web for current information on any topic"
    
    @Generable
    struct Arguments {
        @Guide(description: "Search query terms")
        let query: String
        @Guide(description: "Maximum number of results to return")
        let maxResults: Int
        
        init(query: String, maxResults: Int = 5) {
            self.query = query
            self.maxResults = maxResults
        }
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let query = arguments.query
        let maxResults = arguments.maxResults
        
        // Use DuckDuckGo Instant Answer API (free, no API key required)
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://api.duckduckgo.com/?q=\(encodedQuery)&format=json&no_html=1&skip_disambig=1"
        
        guard let url = URL(string: urlString) else {
            return ToolOutput(GeneratedContent(properties: [
                "error": "Invalid query format",
                "operation_type": "web_search",
                "query": query,
                "timestamp": DateFormatter.iso8601.string(from: Date())
            ]))
        }
        
        do {
            let searchData = try await httpClient.get(DuckDuckGoResponse.self, from: url)
            
            var results: [String] = []
            
            // Add abstract if available
            if !searchData.abstract.isEmpty {
                results.append("📄 \(searchData.abstract)")
                if !searchData.abstractSource.isEmpty {
                    results.append("Source: \(searchData.abstractSource)")
                }
            }
            
            // Add definition if available
            if !searchData.definition.isEmpty {
                results.append("📖 Definition: \(searchData.definition)")
                if !searchData.definitionSource.isEmpty {
                    results.append("Source: \(searchData.definitionSource)")
                }
            }
            
            // Add instant answer if available
            if !searchData.answer.isEmpty {
                results.append("💡 \(searchData.answer)")
                if !searchData.answerType.isEmpty {
                    results.append("Type: \(searchData.answerType)")
                }
            }
            
            // Add related topics (limited by maxResults)
            let topicsToShow = Array(searchData.relatedTopics.prefix(maxResults))
            for topic in topicsToShow {
                if !topic.text.isEmpty {
                    results.append("🔗 \(topic.text)")
                }
            }
            
            if results.isEmpty {
                return ToolOutput(GeneratedContent(properties: [
                    "success": false,
                    "operation_type": "web_search",
                    "query": query,
                    "results_count": 0,
                    "message": "No immediate results found. Try rephrasing your search query.",
                    "timestamp": DateFormatter.iso8601.string(from: Date())
                ]))
            }
            
            return ToolOutput(GeneratedContent(properties: [
                "success": true,
                "operation_type": "web_search",
                "query": query,
                "results_count": results.count,
                "results": results,
                "abstract": searchData.abstract.isEmpty ? nil : searchData.abstract,
                "definition": searchData.definition.isEmpty ? nil : searchData.definition,
                "instant_answer": searchData.answer.isEmpty ? nil : searchData.answer,
                "sources": [searchData.abstractSource, searchData.definitionSource].filter { !$0.isEmpty },
                "timestamp": DateFormatter.iso8601.string(from: Date())
            ]))
            
        } catch {
            return ToolOutput(GeneratedContent(properties: [
                "error": "Search failed",
                "operation_type": "web_search",
                "query": query,
                "message": error.localizedDescription,
                "timestamp": DateFormatter.iso8601.string(from: Date())
            ]))
        }
    }
    
    // DuckDuckGo API response models
    private struct DuckDuckGoResponse: Codable {
        let abstract: String
        let abstractSource: String
        let definition: String
        let definitionSource: String
        let answer: String
        let answerType: String
        let relatedTopics: [RelatedTopic]
        
        struct RelatedTopic: Codable {
            let text: String
        }
        
        enum CodingKeys: String, CodingKey {
            case abstract = "Abstract"
            case abstractSource = "AbstractSource"
            case definition = "Definition"
            case definitionSource = "DefinitionSource"
            case answer = "Answer"
            case answerType = "AnswerType"
            case relatedTopics = "RelatedTopics"
        }
    }
}
