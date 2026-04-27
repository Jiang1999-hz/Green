# Green Development Handoff Step 3

## 2026-04-16

### Session Goal

- Start Step 3 of the MVP plan: `浇水提醒 + 通知`.
- Turn the existing first-pass reminder scheduling into a visible, user-facing product flow.

### Starting Point

- Step 1 `Plant archive CRUD` is complete and accepted.
- Step 2 `Growth record + PhotoKit timeline` is complete and accepted.
- A bootstrap reminder service already exists, but it is still infrastructure-first:
  - plant create / edit schedules a reminder
  - plant delete cancels a reminder
  - the app does not yet clearly show reminder permission state or reminder scheduling state in the UI

### Step 3 Scope

- Make reminder state visible in the app.
- Add notification-permission UX instead of leaving reminder behavior implicit.
- Keep the current `nextWateringDate` model working while Step 3 is being built out.
- Defer any risky Core Data migration unless the current model blocks product behavior.

### Step 3 First Increment

- Add a dedicated reminder-status representation that can answer:
  - whether notifications are allowed
  - whether this plant currently has a pending reminder
  - when the pending reminder is expected to fire
- Surface reminder state in:
  - plant dashboard summary
  - plant detail page
- Add first-pass user actions for reminder UX:
  - request notification permission when appropriate
  - reschedule the current plant reminder when permission already exists
  - guide the user to system settings when notifications are denied

### Data Model Decision For This Increment

- Do not force the `lastWateredDate` migration in the first Step 3 increment.
- Reason:
  - the current model can still support visible reminder UX
  - a Core Data migration should be treated as a deliberate follow-up, not mixed into the first reminder UI pass
- Carry-forward decision:
  - if later reminder logic requires user-confirmed “I watered it today” behavior, migrate to `lastWateredDate -> nextWateringDate` in a dedicated Step 3 follow-up slice

### Acceptance Criteria For This Increment

- The dashboard no longer shows Step-3 placeholder copy for reminders.
- The user can see whether reminders are effectively available or blocked.
- The plant detail page shows the reminder state for the current plant.
- The user can trigger the first reminder-permission flow from inside the app.
- If permission is denied, the UI makes that state explicit instead of silently failing.

### Planned Follow-Ups Inside Step 3

- add a true “mark as watered” action
- decide and implement `lastWateredDate` migration if needed
- expose reminder state more broadly across the list
- polish notification timing strategy and copy
- consider reminder state debugging / visibility for development builds if validation becomes painful

### Progress So Far

- Added a dedicated Step 3 handoff instead of continuing to overload the Step 2 closeout.
- Added reminder-state visibility to the dashboard and plant detail flows.
- Added first-pass permission-aware reminder actions on the plant detail page:
  - enable reminders
  - refresh reminders
  - jump to system settings when notifications are denied
- Added a lightweight `lastWateredDate` Core Data model migration as an optional field.
- Introduced a shared watering-schedule helper so reminder date calculation no longer lives only inside the plant form flow.
- Added `markPlantWatered` at the repository boundary.
- Added a user-facing `今天已浇水` action on plant detail that:
  - writes `lastWateredDate`
  - recomputes `nextWateringDate`
  - reschedules the reminder
- Refined the dashboard reminder entry to a compact top-left notification control:
  - green when notifications are enabled
  - red when notifications are unavailable
  - first-tap permission request when not determined
  - system settings jump when denied
  - lightweight confirmation menu when already enabled
- Synced the new watering state model back to the dashboard:
  - `今日已浇水` status on plant cards
  - `上次浇水` surfaced alongside next watering info
  - dashboard summary now reflects watering completion state instead of only reminder plumbing
- Full project build succeeded after this Step 3 increment.

### Verification Status

- Manual acceptance passed for the Step 3 reminder slice, including:
  - notification permission entry from the dashboard
  - reminder state visibility on plant detail
  - `今天已浇水` action
  - `lastWateredDate -> nextWateringDate -> reminder reschedule` flow
  - dashboard feedback after watering actions

### Closeout Status

Step 3 is complete for the MVP reminder scope.

This handoff should now be treated as the Step 3 closeout record.

### Recommended Next Step

1. Do not keep expanding this handoff with Step 4 execution details.
2. Start Step 4 in a new handoff focused on `成长动画生成`.
3. Carry forward only optional reminder polish items if they become necessary:
   - minor notification copy refinement
   - additional reminder debug visibility for development
