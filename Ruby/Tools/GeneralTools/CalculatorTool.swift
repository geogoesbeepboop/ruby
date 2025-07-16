//
//  CalculatorTool.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/15/25.
//
import Foundation
import FoundationModels

/// Calculate mathematical expressions
struct CalculatorTool: Tool {
    let name = "calculator"
    let description = "Perform mathematical calculations and solve equations"
    
    @Generable
    struct Arguments {
        @Guide(description: "Mathematical expression to evaluate")
        let expression: String
        @Guide(description: "Number of decimal places for the result")
        let precision: Int
        
        init(expression: String, precision: Int = 2) {
            self.expression = expression
            self.precision = precision
        }
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let expression = arguments.expression
        let precision = arguments.precision
        
        // Basic expression evaluation using NSExpression
        let result = Self.evaluateExpression(expression)
        let formattedResult = String(format: "%.\(precision)f", result)
        
        return ToolOutput(GeneratedContent(properties: [
            "expression": expression,
            "result": formattedResult,
            "raw_result": result,
            "precision": precision,
            "operation_type": "mathematical_calculation",
            "timestamp": DateFormatter.iso8601.string(from: Date())
        ]))
    }
    
    private static func evaluateExpression(_ expression: String) -> Double {
        let expr = NSExpression(format: expression)
        if let result = expr.expressionValue(with: nil, context: nil) as? NSNumber {
            return result.doubleValue
        }
        return 0.0
    }
}
