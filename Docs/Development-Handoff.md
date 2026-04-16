# Green Development Handoff

## 2026-04-15

### Session Goal

- Start Step 1 of the MVP plan: `Plant archive CRUD`.
- Refactor the app away from `SwiftUI View -> Core Data direct binding` so later iterations can extend the codebase without making the feature layer heavier.

### What Was Completed

- Introduced a more maintainable app structure before continuing feature work:
  - `AppContainer` as a composition root
  - `PlantRepository` protocol + `CoreDataPlantRepository` implementation
  - `PlantRecord` and `PlantDraft` as domain-level feature models
  - feature-specific view models for dashboard, detail, and form flows
- Replaced the foundation-only dashboard with a real plant archive home flow.
- Implemented the main Step 1 CRUD chain:
  - plant list on the home screen
  - create plant form
  - edit plant form
  - delete plant flow
  - plant detail screen
- Connected plant cover photo handling to PhotoKit:
  - choose a photo from the system photo library
  - capture a photo in-app
  - save captured photos into the system album named `植物成长`
  - persist only the `PHAsset.localIdentifier`
- Fixed the plant edit save behavior for watering reminders:
  - editing a plant no longer resets `nextWateringDate` on every save
  - `nextWateringDate` is now recalculated only when `wateringIntervalDays` changes

### Key Architecture Changes Made Today

#### 1. Composition Root and Dependency Wiring

- Added `Green/App/AppContainer.swift`
- The app entry now creates dependencies once and passes feature view models from the container instead of having views construct storage-facing dependencies themselves.
- Result:
  - Later feature work can add services and repositories without scattering wiring logic through views.

#### 2. Repository Boundary Between UI and Core Data

- Added:
  - `Green/Data/Plants/PlantRepository.swift`
  - `Green/Data/Plants/CoreDataPlantRepository.swift`
- Views no longer depend directly on `NSManagedObject` fetches.
- Result:
  - The UI layer is now insulated from storage details.
  - CRUD behavior has a single write/read boundary for later reuse in more screens.

#### 3. Feature Models and State Layer

- Added:
  - `Green/Domain/Plants/PlantRecord.swift`
  - `Green/Domain/Plants/PlantDraft.swift`
  - `Green/Features/Plants/PlantDashboardViewModel.swift`
  - `Green/Features/Plants/PlantDetailViewModel.swift`
  - `Green/Features/Plants/PlantFormViewModel.swift`
- Result:
  - `PlantDashboardView` no longer uses `@FetchRequest`.
  - Feature state is centralized in view models instead of being spread across SwiftUI view code and Core Data bindings.

### Feature Work Completed Today

#### 1. Plant Home / List Screen

- `Green/Features/Plants/PlantDashboardView.swift` now shows:
  - hero section
  - plant count summary
  - "due today" summary
  - real plant card list
  - empty state
  - error state
  - add-plant entry points
- Tapping a plant opens a detail page.

#### 2. Plant Detail Screen

- Added `Green/Features/Plants/PlantDetailView.swift`
- Added `Green/Features/Plants/PlantDetailViewModel.swift`
- Current detail page supports:
  - cover photo display
  - plant metadata display
  - notes display
  - edit action
  - delete action with confirmation

#### 3. Plant Form Screen

- Added `Green/Features/Plants/PlantFormView.swift`
- Added `Green/Features/Plants/PlantFormViewModel.swift`
- Current form supports:
  - name
  - species
  - location
  - planted date
  - watering interval in days
  - notes
  - cover photo selection from system photos
  - cover photo capture from camera
  - cover photo removal

#### 4. PhotoKit Cover Photo Flow

- Extended `Green/Services/PhotoLibraryService.swift`
- Added:
  - permission gating for read/write access
  - saving a captured `UIImage` into the system photo library
  - creating/fetching the custom album `植物成长`
  - adding the created asset into that album
- Added `Green/Features/Plants/PhotoAssetImageView.swift` to render stored asset identifiers in SwiftUI.

### Current Product Status

- The project has moved beyond the foundation dashboard.
- Step 1 `Plant archive CRUD` is now functionally started and the main archive flow exists.
- Current implemented Step 1 scope:
  - list plants
  - create plant
  - edit plant
  - delete plant
  - view plant detail
  - attach a cover photo

### Current Functional State

- The app is no longer only a placeholder architecture shell.
- The current primary user flow is:
  1. Open the home screen
  2. Add a plant
  3. Fill in basic profile information
  4. Optionally choose or capture a cover photo
  5. Save the plant
  6. Reopen it through the list
  7. Edit or delete it from the detail page

### Known Issues / Decisions Still Pending

#### 1. Watering Data Model Is Not Fully Aligned With The PRD Yet

- The current data model still uses `nextWateringDate`.
- The PRD data model expects `wateringInterval` plus `lastWateredDate`.
- Current temporary behavior:
  - create flow recalculates `nextWateringDate` when saving a plant
  - edit flow preserves the existing `nextWateringDate` unless `wateringIntervalDays` changes
- Why this matters:
  - this is acceptable for Step 1 display work
  - but reminder logic in Step 3 will be cleaner and more correct if the model is migrated to `lastWateredDate -> nextWateringDate`
- Recommended fix before notification work:
  - add `lastWateredDate`
  - compute `nextWateringDate` from business logic rather than storing only a precomputed value

#### 2. Current Verification Status

- `PlantFormViewModel.swift` was checked for live Xcode diagnostics and had no issues.
- A full project build succeeded through the Xcode toolchain in this session.
- The watering-date fix was verified at the code-path level:
  - `PlantFormViewModel` now decides whether to preserve or recalculate `nextWateringDate`
  - `CoreDataPlantRepository` writes the computed `draft.nextWateringDate` directly without overriding it
- Remaining gap:
  - end-to-end UI interaction for the edit flow still needs manual verification in Simulator or on device

#### 3. Step 1 Is Feature-Complete In Core Flow, But Still Needs Product Polish

- No automated tests were added yet.
- No user-facing success feedback was added after save/delete.
- The form currently focuses on correctness and architecture, not polish or validation richness.
- The dashboard and detail UI still need final visual refinement if the PRD design language is to be matched more closely.

#### 4. Photo Flow Is Good Enough For Step 1, But Not Finished As A General Media Layer

- Cover photos are handled.
- Growth record photo ingestion is not implemented yet.
- EXIF-based record date extraction is not implemented yet.
- Limited photo-library management UI is still minimal.
- Camera capture behavior still needs real-device validation in Xcode.

### Files Changed Today

- `Green.xcodeproj/project.pbxproj`
- `Green/GreenApp.swift`
- `Green/App/AppContainer.swift`
- `Green/Domain/Plants/PlantRecord.swift`
- `Green/Domain/Plants/PlantDraft.swift`
- `Green/Data/Plants/PlantRepository.swift`
- `Green/Data/Plants/CoreDataPlantRepository.swift`
- `Green/Features/Plants/PlantDashboardView.swift`
- `Green/Features/Plants/PlantDashboardViewModel.swift`
- `Green/Features/Plants/PlantDetailView.swift`
- `Green/Features/Plants/PlantDetailViewModel.swift`
- `Green/Features/Plants/PlantFormView.swift`
- `Green/Features/Plants/PlantFormViewModel.swift`
- `Green/Features/Plants/PhotoAssetImageView.swift`
- `Green/Features/Plants/CameraCaptureView.swift`
- `Green/Services/PhotoLibraryService.swift`

### Recommended Next Step

Verify the plant edit flow manually in Xcode, specifically the watering-date behavior:

1. Edit a plant without changing `wateringIntervalDays` and confirm `nextWateringDate` is preserved.
2. Edit the same plant with a different `wateringIntervalDays` value and confirm `nextWateringDate` is recalculated from the new interval.
3. If both checks pass, decide whether to keep the temporary `nextWateringDate` model for Step 1 polish or migrate to `lastWateredDate` before reminder work.

### Resume Prompt

If resuming later, start from this instruction:

`Continue Green from Docs/Development-Handoff.md. Step 1 plant archive CRUD is implemented, and PlantFormViewModel now preserves nextWateringDate during edit unless wateringIntervalDays changes. Manually verify that edit behavior in Xcode, then decide whether to keep the temporary watering model or migrate to lastWateredDate before reminder work.`

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
