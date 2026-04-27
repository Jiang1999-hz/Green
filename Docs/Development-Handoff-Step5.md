# Green Development Handoff Step 5

## 2026-04-16

### Session Goal

- Start Step 5 of the MVP plan: `FAB 快捷入口`.
- Turn the already-finished core flows into faster high-frequency actions from the dashboard.

### Starting Point

- Step 1 `Plant archive CRUD` is complete and accepted.
- Step 2 `Growth record + PhotoKit timeline` is complete and accepted.
- Step 3 `浇水提醒 + 通知` is complete and accepted.
- Step 4 `成长动画生成` is complete for MVP scope and closed out separately.
- The dashboard already supports:
  - plant list browsing
  - notification permission entry
  - add-plant flow
  - navigation into plant detail

### Step 5 Scope

- Add a floating action button on the dashboard.
- Use it as a quick-entry hub instead of another passive decoration.
- Keep the first slice focused on the three highest-frequency actions:
  - `添加植物`
  - `记录成长`
  - `今天已浇水`

### Step 5 First Increment

- Deliver an expandable floating quick-action entry from the dashboard.
- Reuse existing create flows instead of inventing parallel forms.
- Handle both single-plant and multi-plant cases cleanly:
  - direct jump when only one target plant is available
  - lightweight chooser when multiple plants are available

### Acceptance Criteria For This Increment

- A floating action button is visible on the dashboard.
- Tapping it expands quick actions for add plant, growth record, and mark watered.
- `添加植物` opens the existing plant creation flow.
- `记录成长` opens the existing growth record creation flow for a chosen plant.
- `今天已浇水` updates the selected plant and refreshes dashboard state.

### Planned Follow-Ups Inside Step 5

- context-aware FAB suggestions based on due-today plants
- richer motion polish for expand / collapse behavior
- optional direct camera shortcut for growth recording
- deeper shortcut routing into animation export or reminder flows if product direction requires it

### Known UX Follow-Up

- The current multi-plant chooser for `记录成长` is only a transitional routing solution.
- A pure text-based lightweight chooser is acceptable for the first slice, but it is not the long-term interaction model.
- The long-term replacement should be a dedicated plant selection experience for quick actions, with richer plant context instead of only names.
