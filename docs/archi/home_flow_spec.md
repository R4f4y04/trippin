# Home Flow Refresh (No Active Trip)

## Overview
Introduce a clean, modern home flow when no trip is active. The screen focuses on a centered brand identity, clear primary action, and quick access to history, settings, and about. Optional demo data (sample trip) helps first-time users explore the app.

## Goals
- Provide a polished landing experience when there is no active trip.
- Keep the user’s next action obvious: start a trip.
- Allow quick access to history, settings, and about.
- Optional “Sample Trip” for onboarding without data entry.

## UI/UX Layout
### Empty Home Screen (No Active Trip)
- Centered brand text: “Trippin”
- Welcome line: “Offline-first expense splitting.”
- Primary CTA button: “Start a Trip”
- Secondary actions (pill buttons):
  - Trip History
  - Settings
  - About
- Optional:
  - “How it works” link
  - Offline badge
  - Quick tips carousel (1–2 lines)
  - “Create sample trip” button

### Navigation
- Start a Trip → existing trip creation dialog or new flow.
- Trip History → history list screen.
- Settings → minimal settings screen (theme toggle placeholder, data reset warning later).
- About → app version + offline-first note.

## Data & Services
- Sample trip generation:
  - Create a trip with a device owner.
  - Add 2–3 members.
  - Add 2–3 expenses with equal split.
- All data is stored in Hive via `StorageService`.

## Providers
- `TripController` continues to determine active trip.
- `TripListController` used to load latest trip for “Resume” (optional).

## Implementation Steps
1. Create `EmptyHomeScreen` widget in `lib/features/home/`.
2. Route home based on active trip:
   - Active trip → current trip view.
   - No active trip → empty home screen.
3. Add navigation targets:
   - Trip History screen (existing).
   - Settings screen (new, minimal).
   - About screen (new, minimal).
4. Add “Sample Trip” action in `StorageService`.
5. Update docs with this flow.

## Acceptance Criteria
- When no active trip exists, user sees the new empty home screen.
- Primary CTA starts trip creation.
- History/Settings/About navigation works.
- Sample trip populates members and expenses locally.

## Gotchas
- Ensure “Sample Trip” does not overwrite existing trips.
- Keep UI consistent with Night Owl theme.
