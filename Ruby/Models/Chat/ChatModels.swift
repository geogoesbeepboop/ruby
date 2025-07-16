import Foundation
import FoundationModels

// MARK: - Core Chat Models

struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    var reactions: [String] = []
    var metadata: MessageMetadata?
    
    struct MessageMetadata: Codable {
        let processingTime: TimeInterval?
        let tokens: Int?
        let confidence: Double?
    }
}

enum ChatState {
    case activeChat
    case voiceListening
    case aiThinking
    case streaming
    case error(String)
}

extension ChatState: Equatable {
    static func == (lhs: ChatState, rhs: ChatState) -> Bool {
      switch (lhs, rhs) {
      case (.activeChat, .activeChat):
        return true
      case (.voiceListening, .voiceListening):
        return true
      case (.aiThinking, .aiThinking):
        return true
      case (.streaming, .streaming):
        return true
      case (.error(let lhsError), .error(let rhsError)):
          return lhsError.isEqual(rhsError)
      default:
        return false
      }
    }
}

enum AIPersona: String, CaseIterable, Codable {
    case therapist = "Welcoming Therapist"
    case professor = "Distinguished Professor"
    case techLead = "Tech Lead"
    case musician = "World-Class Musician"
    case comedian = "Wise Comedian"
    
    var systemPrompt: String {        
        switch self {
        case .therapist:
            return """
        You are a world-renowned therapist with decades of experience helping people through their feelings and personal challenges. Your approach is compassionate, validating, and empowering. You:

        - Listen actively and validate emotions without judgment
        - Help people process their feelings and gain insights
        - Offer gentle guidance and coping strategies when appropriate
        - Create a safe, supportive space for vulnerability
        - Use therapeutic techniques like active listening, reflection, and reframing
        - Encourage self-discovery and personal growth
        - Are trauma-informed and culturally sensitive

        Remember: You provide emotional support and guidance, but always encourage users to seek professional help for serious mental health concerns.
        """
        case .professor:
            return """
            You are a distinguished professor with deep expertise in your academic field. Your role is to inspire curiosity, encourage critical thinking, and support personal and intellectual development. You:
            - Break down complex ideas into digestible concepts
            - Encourage questions, independent thought, and deeper reflection
            - Offer historical and contextual insight to ideas
            - Provide structured, logical reasoning in responses
            - Use analogies, case studies, and Socratic questioning to guide learning
            - Support users in building long-term understanding and academic confidence
            - Promote intellectual humility and lifelong learning
            Remember: Your goal is to cultivate understanding and inspire growth, not just deliver answers.
            """
        case .techLead:
            return """
            You are a seasoned software engineer and team tech lead with a passion for clean architecture, mentorship, and building scalable systems. You:
            - Translate technical concepts into clear, actionable steps
            - Guide users through problem-solving and debugging with curiosity
            - Suggest best practices in software engineering and development tools
            - Foster good engineering habits, like documentation and testing
            - Support learning in languages like Swift, Python, and JS
            - Help define goals and scope in technical projects
            - Emphasize collaboration, communication, and continuous learning
            Remember: Your role is both a guide and a mentor—encouraging clarity, precision, and self-improvement.
            """
        case .musician:
            return """
            You are a world-class musician with a deep understanding of music theory, emotion, and performance. You inspire others to find their own voice through creative expression. You:
            - Help users connect emotionally with music and sound
            - Provide guidance on practicing, songwriting, or performance technique
            - Offer insights on flow, timing, rhythm, and musical storytelling
            - Encourage creative confidence and consistent exploration
            - Reference genres, history, and cultural context in relevant ways
            - Invite improvisation and mindfulness through musical practice
            - Use a poetic, expressive tone without losing clarity
            Remember: Music is both technical and emotional—help users explore both dimensions.
            """
        case .comedian:
            return """
            You are a wise and observant comedian, known for blending sharp humor with insight. Your role is to help people see the lighter side of life while still offering thoughtful reflection. You:
            - Use humor to highlight truth, irony, and human behavior
            - Listen closely and respond with wit and empathy
            - Encourage users to laugh at challenges while growing through them
            - Avoid cruelty or sarcasm that could feel judgmental
            - Use metaphor, timing, and comedic rhythm to entertain and uplift
            - Offer deep truths through playful dialogue
            - Know when to be light and when to hold space seriously
            Remember: Your humor disarms and connects—it's a path to meaning, not distraction.
            """

        }
    }
}

// MARK: - Foundation Models Integration Types

@Generable
struct ChatResponse {
    @Guide(description: "The main response content to the user's message")
    let content: String
    
    @Guide(description: "Emotional tone of the response")
    let tone: String
    
    @Guide(description:"Confidence level in the response accuracy with a range of 0.0 to 1.0")
    let confidence: Double
}

@Generable
struct VoiceTranscription {
    @Guide(description: "The transcribed text from voice input")
    let text: String
    
    @Guide(description: "Confidence level of transcription accuracy", .range(0.0...1.0))
    let confidence: Double
    
    @Guide(description: "Detected language code (e.g., 'en-US')")
    let languageCode: String
}

@Generable
struct MessageAnalysis {
    @Guide(description: "The intent category of the message such as question, request, conversation, command, and greeting")
    let intent: String
    
    @Guide(description: "Emotional sentiment such as positive, neutral, negative")
    let sentiment: String
    
    @Guide(description: "Required response length such as brief, detailed or comprehensive")
    let responseLength: String
    
    @Guide(description: "Whether the message requires tool usage")
    let requiresTools: Bool
}

@Generable
struct UserFriendlyErrorMessage {
    @Guide(description: "A warm, conversational message explaining why the AI can't fulfill the request, written as if the AI is speaking directly to the user")
    let message: String
    
    @Guide(description: "A helpful suggestion for what the user could try instead, if applicable")
    let suggestion: String?
    
    @Guide(description: "The tone of the message: apologetic, helpful, encouraging, or informative")
    let tone: String
}

@Generable
struct SessionTitle {
    @Guide(description: "A concise, descriptive title that captures the main topic or theme of the conversation (3-6 words max)")
    let title: String
    
    @Guide(description: "Confidence level in the title relevance with a range of 0.0 to 1.0")
    let confidence: Double
}

// MARK: - Error Types

enum ChatError: LocalizedError {
    case sessionInitializationFailed
    case contextWindowExceeded
    case modelUnavailable
    case voiceRecognitionFailed
    case networkUnavailable
    case permissionDenied
    case saveFailed
    case loadFailed
    
    // New LanguageModelSession.GenerationError specific cases
    case assetsUnavailable
    case decodingFailure
    case guardrailViolation
    case unsupportedGuide
    
    var errorDescription: String? {
        switch self {
        case .sessionInitializationFailed:
            return "Failed to initialize AI session"
        case .contextWindowExceeded:
            return "Conversation too long, starting new session"
        case .modelUnavailable:
            return "AI model temporarily unavailable"
        case .voiceRecognitionFailed:
            return "Voice recognition failed"
        case .networkUnavailable:
            return "Network connection required for some features"
        case .permissionDenied:
            return "Permission required for this feature"
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        case .assetsUnavailable:
            return "Required AI assets are currently unavailable"
        case .decodingFailure:
            return "Failed to process AI response format"
        case .guardrailViolation:
            return "Content detected likely to be unsafe"
        case .unsupportedGuide:
            return "Unsupported response format requested"
        }
    }
    
    var isUserFacingError: Bool {
        switch self {
        case .guardrailViolation, .contextWindowExceeded:
            return true
        default:
            return false
        }
    }
}

// MARK: - Settings Models

struct ChatSettings: Codable {
    var selectedPersona: AIPersona = .therapist
    var voiceEnabled: Bool = true
    var streamingEnabled: Bool = true
    var maxContextLength: Int = 8000
    var autoSaveConversations: Bool = true
    
    static let `default` = ChatSettings()
}

// MARK: - Conversation Session

struct ConversationSession: Identifiable, Codable {
    let id: UUID
    var title: String
    let createdAt: Date
    var lastModified: Date
    var messages: [ChatMessage]
    let persona: AIPersona
    
    init(id: UUID = UUID(), title: String, createdAt: Date, lastModified: Date, messages: [ChatMessage], persona: AIPersona) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.messages = messages
        self.persona = persona
    }
    
    var messageCount: Int {
        messages.count
    }
    
    var lastMessage: ChatMessage? {
        messages.last
    }
}
