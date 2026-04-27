# Green Development Handoff Step 2

## 2026-04-15

### Session Goal

- Start Step 2 of the MVP plan: `Growth record + PhotoKit timeline`.
- Build on the accepted Step 1 plant archive flow without reopening Step 1 scope.

### Starting Point

- Step 1 `Plant archive CRUD` is complete and manually accepted.
- The app already supports:
  - plant list
  - create plant
  - edit plant
  - delete plant
  - plant detail
  - plant cover photo selection and capture through PhotoKit
- Step 1 closeout is recorded in `Docs/Development-Handoff.md`.

### Step 2 Scope

- Add growth record creation tied to a plant.
- Support selecting or capturing photos for growth records.
- Show a plant-specific growth timeline using PhotoKit-backed media.
- Keep the implementation offline-first with Core Data as the source of truth.

### What Step 2 Should Reuse

- `AppContainer` for dependency wiring.
- `PlantRepository` / `CoreDataPlantRepository` patterns as the storage boundary reference.
- Existing PhotoKit service patterns from `PhotoLibraryService`.
- Existing plant detail flow as the likely entry point for growth record actions and timeline display.

### Initial Implementation Direction

#### 1. Define The Growth Record Feature Boundary

- Introduce domain-level models for growth records instead of binding SwiftUI directly to Core Data entities.
- Decide whether growth records need a dedicated repository abstraction now, or whether they should extend the current plant repository boundary.
- Keep the feature-layer state in dedicated view models, following the Step 1 pattern.

#### 2. Add A Basic Growth Record CRUD Slice

- Minimum target for the first Step 2 pass:
  - create a growth record for a plant
  - attach one photo to the record
  - persist the record date and note
  - list records in reverse chronological order on the plant detail flow
- Do not start animation generation or reminders in this slice.

#### 3. Connect PhotoKit For Record Media

- Reuse the established album / asset identifier approach where appropriate.
- Growth record media should persist stable asset identifiers rather than large binary blobs in Core Data.
- Limited-library and camera behavior should follow the same permission model already used for cover photos.

### Data Model Notes

- `lastWateredDate` is still a planned future migration item from Step 1 and should stay out of the first Step 2 slice unless the growth record design makes that migration unavoidable.
- If growth records include watering events later, that should be treated as a deliberate model expansion, not slipped into the first photo timeline pass by accident.

### Expected First Deliverable

- A plant detail experience that can:
  - add a growth record
  - show the saved growth record in a timeline section
  - render the associated photo from PhotoKit

### Progress So Far

- Added a dedicated Step 2 feature boundary instead of overloading `PlantRepository`:
  - `GrowthRecordEntry`
  - `GrowthRecordDraft`
  - `GrowthRecordRepository`
  - `CoreDataGrowthRecordRepository`
- Extended `AppContainer` to provide growth record dependencies separately from plant archive dependencies.
- Extended `PlantDetailViewModel` to load growth records alongside the selected plant.
- Added `GrowthRecordFormViewModel` and `GrowthRecordFormView` for creating a record with:
  - recorded date
  - optional note
  - one required PhotoKit-backed image
  - camera / photo-library flows matching the existing plant cover photo pattern
- Extended `PlantDetailView` with:
  - a `成长时间线` section
  - an empty state for plants with no records
  - a create-record entry point
  - record cards that render PhotoKit-backed images and record metadata
- Added a dedicated `查看全部成长记录` page with:
  - a stage-based growth hero
  - a lightweight full-history list
  - a compact recent timeline split back into `PlantDetailView`
  - a theme-ready hero renderer boundary
  - two built-in switchable themes for the first theme-system slice
- Added post-acceptance Step 2 enhancements:
  - growth theme selection persistence
  - growth record editing
  - growth record deletion
  - a first reminder-service integration that schedules and cancels watering reminders off the current `nextWateringDate` model
- Full project build succeeded after this Step 2 slice was added.

### Verification Status

#### Step 2 Core Acceptance

- The core Step 2 scope should be accepted against these items:
  - create a growth record from plant detail
  - photo-library / camera-backed record creation flow
  - compact recent timeline on plant detail
  - full-history growth page
  - stage-based growth hero tied to record count
- Manual acceptance passed for the current core Step 2 slice.

#### Step 2 Enhancements

- These are enhancements beyond the minimum acceptance bar for Step 2:
  - built-in theme switching on the growth page
  - theme selection persistence across launches
  - growth record editing / deletion
  - first-pass reminder service integration
- Still not implemented:
  - premium / paid theme packs
  - richer growth record metadata editing for height / health / vision summary
  - a formal `lastWateredDate` migration
  - a full Step 3 reminder product flow

### Updated Product Direction

- The plant detail screen should not become a full-height photo feed as growth records accumulate.
- Keep `PlantDetailView` focused on the most recent, most relevant growth activity:
  - show only a limited recent slice of records
  - use lighter-weight cards with thumbnail, date, and short note preview
- Move the full history into a dedicated `查看全部成长记录` experience.
- That full-history page should not be a plain admin-style list.
- New direction for the full-history page:
  - a stage-based visual growth hero at the top
  - a progress bar showing how many more records are needed to reach the next stage
  - a lightweight record list below, not a dense gallery wall
- The visual growth hero should feel like a tree / flower gradually maturing from seedling to a fuller plant as the record count increases.
- Growth progression should be driven primarily by growth record count, with time-span messaging used as supporting context rather than the primary progression mechanic.

### Stage UI Notes

- Use a small number of discrete stages instead of a continuous simulation.
- Initial target: 5 stages
  - seedling
  - sprout
  - young plant
  - leafy / branching stage
  - mature bloom / mature tree
- The progress bar should communicate:
  - current stage
  - next stage
  - how many more records are needed to level up the plant visual
- The full-history page should remain lightweight:
  - compact thumbnail rows
  - concise date + note summary
  - no giant full-width image stack

### Theme System Follow-Up

- The growth hero should not stay hard-wired to one built-in illustration implementation.
- A theme abstraction should exist even if only one default theme ships now.
- Target follow-up direction:
  - support multiple visual growth themes
  - allow users to switch their preferred growth style
  - leave room for premium / paid theme packs later
- The current implementation should therefore prefer:
  - `theme + stage -> hero rendering`
  - a swappable renderer boundary
  - no page-level assumptions that the hero must always be the current built-in tree / flower drawing
- Future asset pipelines may include:
  - bundled static stage assets
  - vector-based theme packs
  - Rive-backed animated premium themes
- This theme system is now structurally ready for follow-up work, but premium packs and richer asset delivery are not part of the current Step 2 closeout.

### Reminder Follow-Up

- A first reminder-service integration now exists and is wired into plant create / edit / delete flows.
- This does not mean Step 3 is complete.
- The current reminder behavior still relies on the temporary `nextWateringDate` model.
- Step 3 should treat this as a bootstrap layer and continue with:
  - reminder UX
  - permission handling polish
  - reminder state visibility
  - any future migration toward `lastWateredDate`

### Recommended Next Step

Step 2 is complete. Keep this document as the Step 2 closeout record.

1. Do not keep expanding this handoff with Step 3 execution details.
2. Start Step 3 in a new handoff focused on `浇水提醒 + 通知`.
3. Carry forward these known follow-ups into Step 3 planning:
   - the current reminder service is only a first-pass integration
   - `lastWateredDate` is still not implemented
   - premium growth themes remain a later product increment

### Resume Prompt

If resuming later, start from this instruction:

`Step 2 for Green is complete and accepted. Use Docs/Development-Handoff-Step2.md only as the Step 2 closeout record. Start Step 3 in a new handoff focused on watering reminders, notifications, permission UX, and any required model decisions such as the future lastWateredDate migration.`
