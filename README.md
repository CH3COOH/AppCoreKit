# AppCoreKit

A Swift Package Manager library that consolidates shared code across iOS apps (HealthTakeout, FourCropper, NSEasyConnect).

## Requirements

- iOS 16.0+
- Swift 5.9+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/CH3COOH/AppCoreKit", from: "1.2.0")
]
```

Or add via Xcode: **File > Add Package Dependencies** and enter the repository URL.

## Features

### UseCases

| Class | Description |
|-------|-------------|
| `CheckVersionUseCase` | Detects the first launch after an app update and returns `.showVersionInformation` |
| `CheckForceUpdateUseCase` | Fetches a remote config JSON and determines whether a forced update is required |
| `CheckNetworkAccessUseCase` | Verifies network connectivity by sending a request to a specified URL |
| `CheckPurchaseUseCase` | Checks the current purchase/subscription status via RevenueCat |
| `RestorePurchaseUseCase` | Restores previous purchases via RevenueCat |

All use cases conform to `UseCaseProtocol` and provide a consistent async interface:

```swift
func execute(_ input: Input) async -> Result<Output, any Error>
```

### SwiftUI Views

#### Feedback (iOS only)

| View | Description |
|------|-------------|
| `FeedbackScreen` | In-app feedback form that sends an email via `MFMailComposeViewController`. Device model and OS version are automatically detected using [DeviceKit](https://github.com/devicekit/DeviceKit). |

#### Settings

| View | Description |
|------|-------------|
| `SettingsAboutScreen` | Standard about screen with app info, privacy policy, terms, and optional version history |
| `SettingsLinkRowView` | Row with optional system image icon and external link |
| `SettingsListItemView` | Simple list item row for settings |

#### Version Information

| View | Description |
|------|-------------|
| `VersionInformationScreen` | What's new screen shown after an update; footer buttons (subscribe/close) are optional |
| `VersionInformationHeaderView` | Header component for version information |
| `VersionInformationFooterView` | Footer component with action buttons |

#### Launch

| View | Description |
|------|-------------|
| `UpdateRequirementScreen` | Screen shown when a forced update is required |

#### Common

| View | Description |
|------|-------------|
| `SafariView` | In-app browser using `SFSafariViewController` |
| `AccentCapsuleButton` | Capsule-shaped button with accent color |
| `TextAccentButton` | Text button with accent color |
| `LoadingView` | Loading indicator |
| `ContentUnavailableViewCompat` | Backport of `ContentUnavailableView` for iOS 16 |
| `SafeAreaBarCompat` | Safe area bar compatible with iOS 16 |

## License

AppCoreKit is released under the MIT License. See [LICENSE](LICENSE) for details.
