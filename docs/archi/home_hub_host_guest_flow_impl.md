# Home Hub + Host/Guest Flow Implementation Log

## Scope
- Android + single-guest only.
- Reuse existing providers/services where possible.
- Prioritize functional flow over visual polish.

## Progress

### Phase 1: Home Hub Upgrade
Status: Complete

Implemented:
- Updated empty-home UX to show role-first actions:
  - Start Trip as Host
  - Join Trip as Guest
- Kept secondary navigation visible:
  - Trip History
  - Settings
  - About
- Preserved active-trip routing behavior in `HomeScreen`.

Files:
- `lib/features/home/home_screen.dart`
- `lib/features/home/empty_home_screen.dart`

### Phase 2: Dedicated Start Trip Screen
Status: Complete

Implemented:
- Added dedicated start-trip form:
  - Trip Name
  - Host Name
- Calls existing trip creation provider flow (`tripControllerProvider.createTrip`).
- Refreshes members and expenses providers after creation to keep trip state coherent.

Files:
- `lib/features/start_trip/start_trip_screen.dart`

Notes:
- This phase intentionally avoids business-logic changes in services.
- It focuses on route clarity and flow separation.

### Phase 3: Join Trip Entry
Status: Complete (Baseline)

Implemented:
- Added dedicated join entry screen with nearby host discovery list.
- Wired to existing connection provider APIs:
  - `startGuestScan`
  - `stopGuestScan`
  - `requestConnection`
- Added empty-state guidance for no discovered hosts.

Files:
- `lib/features/join_trip/join_trip_entry_screen.dart`

Notes:
- Join-code admission remains deferred.
- Current behavior follows existing nearby discovery/connection approach.

Increment update (UX hardening):
- Join screen now uses provider status as source of truth for discovery state.
- Added explicit status/error visibility using provider messages.
- Added permission-denied recovery action to open app settings.
- Improved empty-state copy for active scanning vs idle retry state.
- Start Trip creation now guarantees loading state reset on failure and surfaces an error snackbar.

### Phase 5: Add Member Option Split
Status: Complete

Implemented:
- Replaced direct Add Member action with a bottom-sheet option chooser.
- Added explicit host paths:
  - Add Local Member
  - Connect Guest as Member
- Wired Connect Guest option to current connected peer display name.
- Kept host-only restrictions and closed-trip guards intact.

Files:
- `lib/features/trip/components/add_member_options_sheet.dart`
- `lib/features/trip/trip_screen.dart`

Remaining follow-up:
- Add member option helper copy refinement and UX polish.

## Validation
- Edited files compile with no file-level errors in VS Code Problems checks.
- Project still contains baseline unrelated warnings in untouched files.

## Gotchas
- Connection terminology must stay consistent across Home and Trip screens.
- Discovery can return empty results for extended periods; guidance text is required.
- Guest join path should not imply join-code flow until protocol is implemented.
