//
//  NewsTool.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/15/25.
//
import Foundation
import FoundationModels

/// Get current news headlines and summaries
struct NewsTool: Tool {
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient?) {
        self.httpClient = httpClient ?? HTTPClient()
    }
    
    let name = "getNews"
    let description = "Get current news headlines and summaries from various sources"
    
    @Generable
    struct Arguments {
        @Guide(description: "News category: general, technology, science, business, health, sports")
        let category: NewsCategory
        @Guide(description: "Number of articles to retrieve (1-10)")
        let count: Int
        @Guide(description: "Country code for local news (US, GB, CA, etc.) or 'global' for international")
        let country: String
        
        init(category: NewsCategory = .general, count: Int = 5, country: String = "US") {
            self.category = category
            self.count = min(max(count, 1), 10)
            self.country = country
        }
        
        @Generable
        enum NewsCategory: String, CaseIterable {
            case general
            case technology
            case science
            case business
            case health
            case sports
        }
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let category = arguments.category
        let count = arguments.count
        let country = arguments.country
        
        // Use NewsAPI.org (free tier available)
        let apiKey = "demo_key" // In production, use secure key management
        let countryParam = country.lowercased() == "global" ? "" : "&country=\(country.lowercased())"
        let categoryParam = category == .general ? "" : "&category=\(category.rawValue)"
        
        let urlString = "https://newsapi.org/v2/top-headlines?apiKey=\(apiKey)\(countryParam)\(categoryParam)&pageSize=\(count)"
        
        guard let url = URL(string: urlString) else {
            return ToolOutput(GeneratedContent(properties: [
                "error": "Invalid news request format",
                "operation_type": "news_retrieval",
                "category": category.rawValue,
                "country": country,
                "timestamp": DateFormatter.iso8601.string(from: Date())
            ]))
        }
        
        do {
            let newsData = try await httpClient.get(NewsResponse.self, from: url)
            
            let articles = newsData.articles.prefix(count).map { article in
                NewsArticle(
                    title: article.title,
                    description: article.description ?? "No description available",
                    source: article.source.name,
                    publishedAt: article.publishedAt,
                    url: article.url
                )
            }
            
            return ToolOutput(GeneratedContent(properties: [
                "success": true,
                "operation_type": "news_retrieval",
                "category": category.rawValue,
                "country": country,
                "articles_count": articles.count,
                "articles": GeneratedContent(
                  articles.map { article in
                    GeneratedContent(properties: [
                      "title": article.title,
                      "description": article.description,
                      "source": article.source,
                      "published_at": article.publishedAt,
                      "url": article.url
                    ])
                  }
                ),
                "timestamp": DateFormatter.iso8601.string(from: Date())
            ]))
            
        } catch {
            return ToolOutput(GeneratedContent(properties: [
                "error": "News fetch failed",
                "operation_type": "news_retrieval",
                "category": category.rawValue,
                "country": country,
                "message": error.localizedDescription,
                "timestamp": DateFormatter.iso8601.string(from: Date())
            ]))
        }
    }
    
    // NewsAPI response models
    private struct NewsResponse: Codable {
        let status: String
        let totalResults: Int
        let articles: [Article]
        
        struct Article: Codable {
            let source: Source
            let title: String
            let description: String?
            let url: String
            let publishedAt: String
            
            struct Source: Codable {
                let name: String
            }
        }
    }
    
    private struct NewsArticle {
        let title: String
        let description: String
        let source: String
        let publishedAt: String
        let url: String
    }
}
