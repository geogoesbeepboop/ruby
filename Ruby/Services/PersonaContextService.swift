import Foundation
import Combine

/// Service that fetches contextual information for different AI personas using external APIs
@MainActor
final class PersonaContextService: ObservableObject {
    private let httpClient: HTTPClient
    
    @Published var isLoading = false
    @Published var lastError: HTTPError?
    
    // Cache for context data
    private var contextCache: [AIPersona: [ContextItem]] = [:]
    private let cacheExpiry: TimeInterval = 3600 // 1 hour
    
    init(httpClient: HTTPClient? = nil) {
        self.httpClient = httpClient ?? HTTPClient()
    }
    
    func getContextForPersona(_ persona: AIPersona, count: Int = 3, userInput: String? = nil) async -> [ContextItem] {
        // Check cache first
        if let cached = contextCache[persona],
           !cached.isEmpty,
           cached.first?.isExpired == false {
            return Array(cached.prefix(count))
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let contextItems = try await fetchContextForPersona(persona, count: count, userInput: userInput)
            contextCache[persona] = contextItems
            return contextItems
        } catch let error as HTTPError {
            lastError = error
            print("❌ [PersonaContextService] Failed to fetch context for \(persona): \(error)")
            return getFallbackContext(for: persona, count: count)
        } catch {
            print("❌ [PersonaContextService] Unexpected error: \(error)")
            return getFallbackContext(for: persona, count: count)
        }
    }
    
    private func fetchContextForPersona(_ persona: AIPersona, count: Int, userInput: String? = nil) async throws -> [ContextItem] {
        switch persona {
        case .none: return []
        case .therapist:
            return try await fetchTherapistContext(count: count)
        case .techLead:
            return try await fetchTechLeadContext(count: count)
        case .comedian:
            return try await fetchComedianContext(count: count)
        case .professor:
            return try await fetchProfessorContext(count: count, userInput: userInput)
        case .musician:
            return try await fetchMusicianContext(count: count)
        }
    }
    
    private func fetchTherapistContext(count: Int) async throws -> [ContextItem] {
        var items: [ContextItem] = []
        
        // Fetch advice from Advice Slip API
        for _ in 0..<count {
            let adviceUrl = URL(string: "https://api.adviceslip.com/advice")!
            let adviceResponse = try await httpClient.get(AdviceResponse.self, from: adviceUrl)
            
            items.append(ContextItem(
                type: .advice,
                content: adviceResponse.slip.advice,
                source: "Advice Slip",
                timestamp: Date()
            ))
            
            // Small delay to respect rate limits
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        return items
    }
    
    private func fetchTechLeadContext(count: Int) async throws -> [ContextItem] {
        var items: [ContextItem] = []
        
        // Fetch programming quotes
        for _ in 0..<count {
            let quoteUrl = URL(string: "http://programming-quotes-api.herokuapp.com/quotes/random")!
            let quote = try await httpClient.get(ProgrammingQuote.self, from: quoteUrl)
            
            items.append(ContextItem(
                type: .quote,
                content: quote.en,
                source: quote.author,
                timestamp: Date()
            ))
            
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        return items
    }
    
    private func fetchComedianContext(count: Int) async throws -> [ContextItem] {
        var items: [ContextItem] = []
        
        for _ in 0..<count {
            let jokeUrl = URL(string: "https://api.chucknorris.io/jokes/random")!
            let joke = try await httpClient.get(ChuckNorrisJoke.self, from: jokeUrl)
            
            items.append(ContextItem(
                type: .joke,
                content: joke.value,
                source: "Chuck Norris API",
                timestamp: Date()
            ))
            
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        return items
    }
    
    private func fetchProfessorContext(count: Int, userInput: String? = nil) async throws -> [ContextItem] {
        print("📚 [PersonaContextService] Fetching professor context, requested count: \(count)")
        
        // Provide topic-relevant academic content based on user input
        let input = userInput?.lowercased() ?? ""
        
        var relevantFacts: [ContextItem] = []
        
        if input.contains("economics") || input.contains("economic") || input.contains("market") || input.contains("money") {
            relevantFacts = [
                ContextItem(type: .fact, content: "Economics studies how societies allocate scarce resources among competing uses and unlimited wants.", source: "Economic Fundamentals", timestamp: Date()),
                ContextItem(type: .fact, content: "The concept of opportunity cost - what you give up to get something else - is central to all economic decisions.", source: "Economic Theory", timestamp: Date()),
                ContextItem(type: .fact, content: "Adam Smith's 'invisible hand' describes how individual self-interest can lead to positive social outcomes in markets.", source: "Classical Economics", timestamp: Date())
            ]
        } else if input.contains("science") || input.contains("physics") || input.contains("chemistry") {
            relevantFacts = [
                ContextItem(type: .fact, content: "The scientific method involves observation, hypothesis formation, experimentation, and peer review.", source: "Scientific Method", timestamp: Date()),
                ContextItem(type: .fact, content: "Einstein's E=mc² shows the relationship between mass and energy, revolutionizing our understanding of the universe.", source: "Physics", timestamp: Date()),
                ContextItem(type: .fact, content: "The periodic table organizes elements by atomic number, revealing patterns in chemical properties.", source: "Chemistry", timestamp: Date())
            ]
        } else if input.contains("history") || input.contains("historical") {
            relevantFacts = [
                ContextItem(type: .fact, content: "History teaches us patterns of human behavior and helps us understand current events in context.", source: "Historical Analysis", timestamp: Date()),
                ContextItem(type: .fact, content: "Primary sources provide direct evidence from the time period being studied, while secondary sources interpret that evidence.", source: "Historical Method", timestamp: Date()),
                ContextItem(type: .fact, content: "The rise and fall of civilizations often follow patterns of growth, prosperity, decline, and renewal.", source: "Historical Patterns", timestamp: Date())
            ]
        } else {
            // General academic/educational facts
            relevantFacts = [
                ContextItem(type: .fact, content: "Critical thinking involves analyzing arguments, evaluating evidence, and drawing logical conclusions.", source: "Academic Skills", timestamp: Date()),
                ContextItem(type: .fact, content: "The Socratic method uses questions to encourage deeper thinking and uncover assumptions.", source: "Educational Philosophy", timestamp: Date()),
                ContextItem(type: .fact, content: "Interdisciplinary learning connects knowledge across different fields to solve complex problems.", source: "Learning Theory", timestamp: Date())
            ]
        }
        
        return Array(relevantFacts.prefix(count))
    }
    
    private func fetchMusicianContext(count: Int) async throws -> [ContextItem] {
        // For musician, we can use general inspirational quotes
        var items: [ContextItem] = []
        
        for _ in 0..<count {
            let quoteUrl = URL(string: "https://api.quotable.io/random?tags=wisdom,inspirational")!
            let quote = try await httpClient.get(QuotableQuote.self, from: quoteUrl)
            
            items.append(ContextItem(
                type: .inspiration,
                content: quote.content,
                source: quote.author,
                timestamp: Date()
            ))
            
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        
        return items
    }
    
    private func getFallbackContext(for persona: AIPersona, count: Int) -> [ContextItem] {
        let fallbackContent = PersonaFallbacks.getContent(for: persona)
        return Array(fallbackContent.prefix(count))
    }
}

// MARK: - Response Models
struct AdviceResponse: Codable {
    let slip: AdviceSlip
}

struct AdviceSlip: Codable {
    let id: Int
    let advice: String
}

struct ProgrammingQuote: Codable {
    let en: String
    let author: String
    let id: String?
    
    enum CodingKeys: String, CodingKey {
        case en, author, id = "_id"
    }
}

struct ChuckNorrisJoke: Codable {
    let value: String
    let url: String
}

struct RandomFact: Codable {
    let text: String
    let source: String
    let sourceUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case text, source
        case sourceUrl = "source_url"
    }
}

struct QuotableQuote: Codable {
    let content: String
    let author: String
    let tags: [String]
}

// MARK: - Context Item Model
struct ContextItem: Identifiable {
    let id = UUID()
    let type: ContextType
    let content: String
    let source: String
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 3600 // 1 hour
    }
}

enum ContextType {
    case advice
    case quote
    case joke
    case fact
    case inspiration
}

// MARK: - Fallback Content
struct PersonaFallbacks {
    static func getContent(for persona: AIPersona) -> [ContextItem] {
        switch persona {
        case .none: return []
        case .therapist:
            return [
                ContextItem(type: .advice, content: "Take time to breathe and reflect on your feelings.", source: "Built-in", timestamp: Date()),
                ContextItem(type: .advice, content: "Remember that it's okay to not be okay sometimes.", source: "Built-in", timestamp: Date()),
                ContextItem(type: .advice, content: "Progress, not perfection, is the goal.", source: "Built-in", timestamp: Date())
            ]
        case .techLead:
            return [
                ContextItem(type: .quote, content: "Code is read more often than it is written.", source: "Guido van Rossum", timestamp: Date()),
                ContextItem(type: .quote, content: "Premature optimization is the root of all evil.", source: "Donald Knuth", timestamp: Date()),
                ContextItem(type: .quote, content: "The best code is no code at all.", source: "Jeff Atwood", timestamp: Date())
            ]
        case .comedian:
            return [
                ContextItem(type: .joke, content: "Why do programmers prefer dark mode? Because light attracts bugs!", source: "Built-in", timestamp: Date()),
                ContextItem(type: .joke, content: "How many programmers does it take to change a light bulb? None, that's a hardware problem!", source: "Built-in", timestamp: Date())
            ]
        case .professor:
            return [
                ContextItem(type: .fact, content: "The human brain contains approximately 86 billion neurons.", source: "Built-in", timestamp: Date()),
                ContextItem(type: .fact, content: "Octopuses have three hearts and blue blood.", source: "Built-in", timestamp: Date())
            ]
        case .musician:
            return [
                ContextItem(type: .inspiration, content: "Music is the universal language of mankind.", source: "Henry Wadsworth Longfellow", timestamp: Date()),
                ContextItem(type: .inspiration, content: "Where words fail, music speaks.", source: "Hans Christian Andersen", timestamp: Date())
            ]
        }
    }
}
