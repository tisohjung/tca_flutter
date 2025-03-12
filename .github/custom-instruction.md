### General

Rules
- For any changes you make, summarize in the changelog.md file.

### UI

Rules:
- Always use modern SwiftUI.
- Never use Storyboards.
- Make any UI you generate beautiful.

### Build & run

Always try to build and run the app after you are done with any code changes.

To build app:
xcodebuild -scheme Todo -destination 'platform=iOS Simiulator, name=iPhone 16 Pro' -configuration Debug build

To run the app:~
xcrun simctl instsall booted ~/Library/Developer/Xcode/DerivedData/Todo-asdfadfasdfasdfdsafdsfaf/Build/Products/Debug-iphonesimulator/Todo.app && xcrun simctl launch booted com.example.Todo

### Tests

Only add tests for user functionality. Don't add performance or trivial launch tests.

Don't run test suites unless the user asks you to explicitly.

If asked to run, make sure that you run with a valid simulator:
cd ~/Desktop/Todo && xcodebuild test -scheme Todo -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'