# FlyGen iOS App

AI-powered flyer generation app built with SwiftUI.

## Requirements

- Xcode 15.0+
- iOS 17.0+
- OpenRouter API key

## Setup Instructions

### Option 1: Create Xcode Project Manually

1. Open Xcode
2. Create a new iOS App project:
   - Product Name: `FlyGen`
   - Team: (Your team)
   - Organization Identifier: `com.flygen`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: iOS 17.0

3. Delete the auto-generated files (ContentView.swift, FlyGenApp.swift, Assets.xcassets, Preview Content)

4. Drag the `FlyGen` folder from this directory into the Xcode project navigator

5. Make sure "Copy items if needed" is unchecked and "Create groups" is selected

6. Build and run!

### Option 2: Use XcodeGen (if installed)

```bash
cd FlyGen
xcodegen generate
open FlyGen.xcodeproj
```

### Option 3: Install XcodeGen first

```bash
brew install xcodegen
cd FlyGen
xcodegen generate
open FlyGen.xcodeproj
```

## Configuration

1. Get an API key from [OpenRouter](https://openrouter.ai/keys)
2. Launch the app
3. Go to Settings (gear icon)
4. Paste your API key

## Project Structure

```
FlyGen/
├── App/                    # App entry point
├── Models/                 # Data models and enums
│   └── Enums/             # All enum types
├── Services/              # Business logic
│   ├── PromptBuilder/     # Prompt engineering (the secret sauce)
│   └── ImageGeneration/   # OpenRouter API integration
├── ViewModels/            # MVVM view models
├── Views/                 # SwiftUI views
│   ├── Home/              # Home screen
│   ├── Creation/          # 7-step creation flow
│   ├── Generation/        # Loading/progress view
│   ├── Result/            # Result display and actions
│   ├── Settings/          # API key configuration
│   └── Components/        # Reusable UI components
├── Extensions/            # Swift extensions
└── Resources/             # Assets and configs
```

## Features

- 12 flyer categories (Event, Sale, Restaurant, etc.)
- 10 visual styles (Modern, Bold, Elegant, etc.)
- 10 moods (Urgent, Exciting, Calm, etc.)
- 8 color palettes
- 6 aspect ratios (Square, Portrait, Story, Landscape, Letter, A4)
- Logo upload support
- Refine with natural language feedback
- Reformat to different sizes
- Save to Photos

## API

Uses OpenRouter's Gemini Flash model for image generation.

## License

Private - All rights reserved.
