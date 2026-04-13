# Green Development Handoff

## 2026-04-13

### Session Goal

- Make the project compile and run in Xcode Simulator.
- Stabilize the MVP foundation so later feature work can continue on top of a working app.

### What Was Completed

- Verified the project structure and got the app building in Xcode Simulator.
- Confirmed the current app launches and the main dashboard can be viewed in Simulator.
- Kept the project aligned with the existing MVP order in [MVP-Foundation.md](./MVP-Foundation.md).

### Key Fixes Made Today

#### 1. Xcode Build Configuration

- Removed the forced `iphoneos` SDK path from the project so the target is no longer locked to device builds.
- Added simulator-specific signing overrides in `Green.xcodeproj/project.pbxproj`:
  - `CODE_SIGNING_ALLOWED[sdk=iphonesimulator*] = NO`
  - `CODE_SIGNING_REQUIRED[sdk=iphonesimulator*] = NO`
  - `CODE_SIGN_IDENTITY[sdk=iphonesimulator*] = ""`
- Result:
  - Simulator builds should not require a development team.
  - Real device builds still require a valid Apple team and signing setup.

#### 2. Core Data Model and Generated Types

- The project originally relied on Core Data code generation for `Plant` and `GrowthRecord`, but the generated files were not being compiled into the Swift build, which caused:
  - `Cannot find type 'Plant' in scope`
  - `Cannot find type 'GrowthRecord' in scope`
- Tried moving the model to manual generation, but on Xcode `26.4` the value `codeGenerationType="manual/none"` caused Xcode and `momc` to abort while parsing the data model.
- Final working solution:
  - Set `codeGenerationType="none"` in `Green/GreenModel.xcdatamodeld/GreenModel.xcdatamodel/contents`
  - Hand-write the `NSManagedObject` classes and properties in:
    - `Green/Persistence/Plant+CoreDataClass.swift`
    - `Green/Persistence/Plant+CoreDataProperties.swift`
    - `Green/Persistence/GrowthRecord+CoreDataClass.swift`
    - `Green/Persistence/GrowthRecord+CoreDataProperties.swift`
- Result:
  - Xcode no longer crashes when opening the project.
  - Core Data entity types are visible to Swift at compile time.

#### 3. PhotosUI API Visibility

- `PhotoLibraryService.swift` used `presentLimitedLibraryPicker`, but only imported `Photos`.
- The limited library picker API comes from `PhotosUI`, not `Photos` alone.
- Fix:
  - Added `import PhotosUI` to `Green/Services/PhotoLibraryService.swift`
- Result:
  - The project compiles with the limited photo library picker call intact.

### Current Product Status

- The app compiles successfully in Xcode.
- The app runs in iPhone Simulator.
- The current screen is still the MVP foundation dashboard, not the full product flow.
- Current implemented foundation:
  - SwiftUI app shell
  - App theme
  - Core Data model and persistence container
  - Photo library permission service
  - Notification permission service
  - Growth animation service placeholder
  - Plant health analysis service placeholder

### Current Functional State

- `PlantDashboardView` is a foundation screen that shows:
  - Hero header
  - Foundation capability summary
  - Development roadmap
  - Plant snapshot section
- The project is not yet at full `Plant CRUD`.
- The app is currently at:
  - Foundation complete
  - Step 1 "Plant archive CRUD" not yet implemented beyond model and placeholder UI

### Files Changed Today

- `Green.xcodeproj/project.pbxproj`
- `Green/GreenModel.xcdatamodeld/GreenModel.xcdatamodel/contents`
- `Green/Persistence/Plant+CoreDataClass.swift`
- `Green/Persistence/Plant+CoreDataProperties.swift`
- `Green/Persistence/GrowthRecord+CoreDataClass.swift`
- `Green/Persistence/GrowthRecord+CoreDataProperties.swift`
- `Green/Services/PhotoLibraryService.swift`

### Important Notes For Next Session

- If building for Simulator:
  - Select an iPhone Simulator target.
  - Use `Product > Clean Build Folder` first if Xcode shows stale build errors.
- If building for a real device:
  - A development team is still required.
  - A unique bundle identifier may also be required.
- If using Codex command execution:
  - `xcodebuild` inside the sandbox may fail when accessing `CoreSimulatorService`.
  - Xcode GUI build/run is the reliable path unless out-of-sandbox execution is allowed.

### Recommended Next Step

Resume with Step 1 of the MVP plan: `Plant archive CRUD`.

Suggested implementation order:

1. Replace the snapshot-only plant section with a real plant list.
2. Add a create-plant form.
3. Add edit and delete flows.
4. Add a plant detail screen.

### Resume Prompt

If resuming later, start from this instruction:

`Continue Green from Docs/Development-Handoff.md. The foundation build is stable. Start implementing Step 1: Plant archive CRUD.`
