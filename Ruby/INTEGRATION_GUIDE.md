# Integration Guide for Ruby ChatBot Views

## Quick Integration Steps

### 1. Add Files to Xcode Project

1. Open `Ruby.xcodeproj` in Xcode
2. Right-click on the project navigator
3. Select "Add Files to 'Ruby'"
4. Navigate to the `Views/` folder and select all `.swift` files:
   - `PlaceholderStateView.swift`
   - `ActiveChatStateView.swift`
   - `VoiceListeningStateView.swift`
   - `AIThinkingStateView.swift`
   - `MainChatBotView.swift`
5. Ensure "Add to target: Ruby" is checked
6. Click "Add"

### 2. Update Build Settings

Ensure your project targets iOS 26.0 or later:

1. Select your project in the navigator
2. Go to "Deployment Target"
3. Set to iOS 26.0 or later

### 3. Add Required Frameworks

Add these frameworks to your project if not already present:

- **FoundationModels** (for AI integration)
- **AVFoundation** (for voice recording)
- **Speech** (for voice recognition)

### 4. Update Info.plist

Add permissions for voice features:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app uses the microphone to record voice messages for the AI assistant.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>This app uses speech recognition to convert voice input to text for better interaction with the AI assistant.</string>
```

### 5. Test the Integration

1. Build and run the project
2. Verify all views load correctly
3. Test state transitions
4. Check voice recording (on device)
5. Validate accessibility features

## File Dependencies

Make sure these files are already in your project:

### Required Files:
- `Components/GlassmorphicComponents.swift` ✓
- `Models/ChatModels.swift` ✓
- `Stores/ChatCoordinator.swift` ✓

### Updated Files:
- `Ruby/ContentView.swift` ✓ (Updated to use MainChatBotView)

## Build Troubleshooting

### Common Issues:

1. **FoundationModels Import Error**
   - Ensure you have the latest Xcode version
   - Check that FoundationModels framework is added

2. **@available iOS 26.0 Warnings**
   - Update deployment target to iOS 26.0
   - These annotations ensure forward compatibility

3. **Voice Permission Errors**
   - Add microphone and speech recognition permissions to Info.plist
   - Test on physical device (simulator has limited voice support)

4. **State Management Issues**
   - Ensure ChatCoordinator is properly initialized
   - Check that all @Environment declarations are correct

### Testing Checklist:

- [ ] App builds without errors
- [ ] PlaceholderStateView displays correctly
- [ ] Can transition to ActiveChatStateView
- [ ] Voice recording works (on device)
- [ ] AI thinking state shows properly
- [ ] Settings sheet opens and functions
- [ ] Error states display correctly
- [ ] Accessibility features work with VoiceOver

## Architecture Overview

```
MainChatBotView (Container)
├── PlaceholderStateView (Initial)
├── ActiveChatStateView (Chat)
├── VoiceListeningStateView (Voice)
├── AIThinkingStateView (Processing)
└── ErrorStateView (Errors)
```

## Next Steps

After integration, consider:

1. **AI Integration**: Connect to your preferred AI service
2. **Voice Processing**: Implement advanced voice features
3. **Persistence**: Add conversation history storage
4. **Customization**: Adapt colors and animations to your brand
5. **Testing**: Comprehensive testing across devices and iOS versions

## Support

If you encounter issues:

1. Check the console for error messages
2. Verify all dependencies are properly linked
3. Ensure proper iOS version targeting
4. Test on physical device for voice features

The views are designed to be modular and extensible, so you can modify individual components without affecting the overall architecture.