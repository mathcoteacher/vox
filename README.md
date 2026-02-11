# Vox (local Voxtral dictation)

This is a macOS SwiftUI app that records audio, sends it to Mistral Voxtral for transcription, then copies the text to your clipboard and pastes into the currently focused app.

## What it does
- `Option + Space` (or the big mic button) toggles recording. The hotkey is configurable in Settings.
- When you stop, it sends the recording to Mistral, then:
  - writes the transcript to the app UI
  - copies to clipboard
  - pastes into the frontmost app (requires Accessibility permission)
- Optional streaming transcription updates the text live as it comes back from the API.
- Optional menu bar only mode hides the dock icon and keeps Vox in the menu bar.

## Setup (MacBook Air M1)
1. Install Xcode from the Mac App Store.
2. Create a new **macOS App** project named `Vox` inside this repo folder.
   - Interface: `SwiftUI`
   - Language: `Swift`
3. Replace the generated source files with the files in `Vox/`.
4. Add `Vox/Info.plist` values:
   - In the target’s **Info** tab add `NSMicrophoneUsageDescription` with the provided string.
5. Enable permissions:
   - If App Sandbox is on, add entitlements from `Vox/Vox.entitlements` (Audio Input + Network Client).
6. Build and run.
7. Open **Settings** in the app and paste your Mistral API key.
8. (Optional) Enable streaming transcription, menu bar mode, and customize the hotkey in Settings.

## Required macOS permissions
- **Microphone**: prompted on first record.
- **Accessibility**: prompted on first launch; required for auto-paste into other apps.

## Notes
- The app uses Mistral’s audio transcription endpoint and the `voxtral-mini-latest` model.
- You can change the hotkey in Settings (or edit `Vox/HotKeyDefinitions.swift` to add/remove keys).
