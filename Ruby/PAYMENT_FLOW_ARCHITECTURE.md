# Payment Flow Architecture: Step-by-Step Documentation

## Overview
This document provides a comprehensive step-by-step walkthrough of how the Send Payment feature works, detailing the interaction between LanguageModelSession objects, StateObjects, and SwiftUI views using Apple Foundation Models framework patterns.

## Architecture Components

### Core Classes
- **PaymentFlow** (ObservableObject): Manages payment workflow state and LanguageModelSession
- **PaymentTool** (Tool): Provides payment validation and processing logic
- **ActionsView** (SwiftUI View): User interface that orchestrates the payment flow

### Data Models
- **Payment** (@Generable): Structured payment details with guided generation
- **PaymentResult** (@Generable): Payment confirmation and result data

## Complete Payment Workflow: Step-by-Step

### Phase 1: Initialization
```
🚀 App Launch
├── ActionsView created with @StateObject paymentFlow = PaymentFlow()
├── PaymentFlow.init() executes:
│   ├── Creates PaymentTool instance
│   ├── Initializes LanguageModelSession with:
│   │   ├── tools: [PaymentTool]
│   │   └── instructions: PaymentInstructions.sendZelle
│   └── Sets @Published properties to initial state
└── UI displays payment button (ready state)
```

### Phase 2: User Interaction
```
👆 User Taps "Send Payment" Button
├── ActionsView button closure executes:
│   ├── Logs: "USER INTERACTION: PAYMENT BUTTON TAPPED"
│   └── Sets triggerPayment = true
├── SwiftUI .task(id: triggerPayment) activates:
│   ├── Logs: "Payment .task triggered"
│   └── Calls await paymentFlow.handlePaymentFlow()
└── UI immediately shows loading state via paymentFlow.isProcessing
```

### Phase 3: Payment Workflow Execution

#### 3.1 Workflow Initialization
```
💳 PaymentFlow.handlePaymentFlow() starts
├── Calls startProcessing():
│   ├── Sets isProcessing = true (triggers UI loading state)
│   ├── Clears previous payment data
│   └── Clears any error messages
└── Creates payment prompt for LanguageModelSession
```

#### 3.2 Phase 1 - Payment Details Generation
```
🔄 PHASE 1: Payment Details Streaming
├── Creates Prompt: "Initiate Zelle payment: Send $50.00 to john@example.com..."
├── Calls session.streamResponse():
│   ├── generating: Payment.self (@Generable struct)
│   ├── includeSchemaInPrompt: true
│   └── temperature: 0.1 (low for consistent payment data)
├── LanguageModelSession processes prompt:
│   ├── May invoke PaymentTool if needed for validation
│   └── Generates structured Payment data
├── Streaming loop executes:
│   ├── For each partialPayment received:
│   │   ├── Updates currentPayment via @Published
│   │   └── SwiftUI automatically re-renders PaymentDetailsView
│   └── Continues until complete Payment object generated
└── Phase 1 completion logged
```

#### 3.3 PaymentTool Integration (if invoked)
```
🔧 PaymentTool.call() may execute during Phase 1
├── Receives @Generable Arguments:
│   ├── amount: Double
│   ├── recipient: String
│   ├── method: String
│   └── memo: String?
├── Executes validation logic:
│   ├── validateRecipient() - email/phone format check
│   ├── calculateFees() - based on payment method
│   ├── getProcessingTime() - estimated completion
│   ├── checkAccountStatus() - account verification
│   └── getRemainingDailyLimit() - spending limits
├── Returns ToolOutput with validation results
└── LanguageModelSession incorporates tool data into Payment generation
```

#### 3.4 Phase 2 - Payment Result Generation
```
🔄 PHASE 2: Payment Result Streaming
├── Creates result prompt: "Complete the payment processing..."
├── Calls session.streamResponse():
│   ├── generating: PaymentResult.self (@Generable struct)
│   ├── includeSchemaInPrompt: true
│   └── temperature: 0.0 (deterministic for confirmation data)
├── LanguageModelSession generates confirmation data:
│   ├── confirmationNumber: String
│   ├── newBalance: Double
│   ├── estimatedCompletion: String
│   └── payment: Payment (nested completed payment)
├── Streaming loop executes:
│   ├── For each partialPaymentResult received:
│   │   ├── Updates paymentResult via @Published
│   │   └── SwiftUI automatically renders PaymentResultView
│   └── Continues until complete PaymentResult generated
└── Phase 2 completion logged
```

### Phase 4: Workflow Completion
```
✅ Payment Workflow Finalization
├── Calls completeProcessing():
│   └── Sets isProcessing = false (removes loading UI)
├── ActionsView .task completes:
│   └── Sets triggerPayment = false (resets trigger)
└── Final UI state shows:
    ├── PaymentDetailsView (from currentPayment)
    └── PaymentResultView (from paymentResult)
```

## UI State Management Flow

### @Published Property Triggers
```
ObservableObject Changes → SwiftUI Re-rendering
├── paymentFlow.isProcessing: true/false
│   └── Shows/hides PaymentProgressView
├── paymentFlow.currentPayment: nil → PartiallyGenerated → Complete
│   └── Conditionally renders PaymentDetailsView with safe unwrapping
├── paymentFlow.paymentResult: nil → PartiallyGenerated → Complete
│   └── Conditionally renders PaymentResultView with safe unwrapping
└── paymentFlow.errorMessage: nil → String
    └── Shows ErrorView if payment fails
```

### Conditional Rendering Pattern
```swift
// Safe unwrapping of PartiallyGenerated properties
if let payment = paymentFlow.currentPayment {
    PaymentDetailsView(payment: payment)
        .onAppear { print("UI UPDATE: Displaying PaymentDetailsView") }
}

// Inside PaymentDetailsView - conditional rendering
if let amount = payment.amount {
    DetailRow(label: "Amount", value: "$\\(amount, specifier: "%.2f")")
}
```

## Apple Foundation Models Integration Points

### 1. LanguageModelSession Configuration
- **Tools**: PaymentTool provides external validation capabilities
- **Instructions**: PaymentInstructions.sendZelle defines AI behavior
- **Options**: Temperature and token limits control generation style

### 2. Guided Generation (@Generable)
- **Payment struct**: Structured output with @Guide constraints
- **PaymentResult struct**: Confirmation data with proper typing
- **Streaming**: PartiallyGenerated types enable real-time UI updates

### 3. Tool Protocol Implementation
- **Custom logic**: PaymentTool amplifies AI with validation algorithms
- **Async processing**: Tool.call() provides additional context to AI
- **Structured arguments**: @Generable Arguments ensure type safety

## Error Handling & Recovery

### Error Flow
```
❌ Error Scenarios
├── LanguageModelSession errors:
│   ├── Network connectivity issues
│   ├── Model availability problems
│   └── Prompt processing failures
├── PaymentTool errors:
│   ├── Validation failures
│   └── Mock data generation issues
└── Error handling:
    ├── Caught in handlePaymentFlow() try-catch
    ├── Calls setError() to update UI state
    └── Shows ErrorView with user-friendly message
```

## Performance Characteristics

### Streaming Benefits
- **Progressive disclosure**: UI updates as data becomes available
- **Perceived performance**: Users see immediate feedback
- **Memory efficiency**: Partial data reduces memory footprint

### StateObject Lifecycle
- **Initialization**: PaymentFlow created once when ActionsView appears
- **Persistence**: Maintains state across multiple payment attempts
- **Memory management**: SwiftUI handles ObservableObject lifecycle

## Logging & Debugging

### Comprehensive Logging Strategy
```
Workflow Logging Pattern:
🚀 Initialization logs
🔘 User interaction logs  
🔄 State change logs
🔧 Tool execution logs
📊 Data streaming logs
✅ Completion logs
❌ Error logs
```

This architecture demonstrates proper Apple Foundation Models framework integration with SwiftUI's reactive patterns, providing a robust, observable, and debuggable payment processing system.