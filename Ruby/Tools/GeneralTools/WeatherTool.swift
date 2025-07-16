//
//  WeatherTool.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/15/25.
//
import Foundation
import FoundationModels
import WeatherKit
import MapKit

@available(iOS 17.0, *)
struct WeatherTool: Tool {
    let name = "getWeather"
    let description = "Get current weather information for a specific location"

    @Generable
    enum WeatherUnit: String, CaseIterable {
        case celsius
        case fahrenheit
    }

    @Generable
    struct Arguments {
        @Guide(description: "The city and state, or city and country, for the weather lookup.")
        let location: String

        @Guide(description: "The units to use for the temperature, either celsius or fahrenheit.")
        let units: WeatherUnit
    }

    private let weatherService = WeatherService()

    func call(arguments: Arguments) async throws -> ToolOutput {
        let locationString = arguments.location
        let units = arguments.units

        // Use MKLocalSearch for geocoding
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = locationString

        do {
            let search = MKLocalSearch(request: searchRequest)
            let response = try await search.start()

            guard let mapItem = response.mapItems.first else {
                return ToolOutput(GeneratedContent(properties: [
                    "error": "Unable to resolve location",
                    "location": locationString,
                ]))
            }
            let location = mapItem.location

            // Fetch current weather
            let weather = try await weatherService.weather(for: location)
            let current = weather.currentWeather

            let temperature = units == .celsius
                ? current.temperature.converted(to: .celsius).value
                : current.temperature.converted(to: .fahrenheit).value

            let feelsLike = units == .celsius
                ? current.apparentTemperature.converted(to: .celsius).value
                : current.apparentTemperature.converted(to: .fahrenheit).value

            let windSpeed = units == .celsius
                ? current.wind.speed.converted(to: .metersPerSecond).value
                : current.wind.speed.converted(to: .milesPerHour).value

            let tempSymbol = units == .celsius ? "°C" : "°F"
            let windUnit = units == .celsius ? "m/s" : "mph"

            return ToolOutput(GeneratedContent(properties: [
                "location": mapItem.name ?? locationString,
                "temperature": "\(Int(temperature))\(tempSymbol)",
                "feels_like": "\(Int(feelsLike))\(tempSymbol)",
                "conditions": current.condition.description,
                "humidity": "\(Int(current.humidity * 100))%",
                "wind_speed": "\(String(format: "%.1f", windSpeed)) \(windUnit)",
                "pressure": "\(Int(current.pressure.value)) hPa", // Using the raw value which is in millibars (hPa)
                "units": units.rawValue,
                "timestamp": DateFormatter.iso8601.string(from: Date())
            ]))

        } catch {
            return ToolOutput(GeneratedContent(properties: [
                "error": "Failed to retrieve weather data",
                "message": error.localizedDescription,
                "location": locationString,
                "timestamp": DateFormatter.iso8601.string(from: Date())
            ]))
        }
    }
}
