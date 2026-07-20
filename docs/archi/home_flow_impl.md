# Home Flow Refresh Implementation

## Overview
Implemented a clean landing experience when no trip is active. The screen centers the Trippin brand, provides a primary Start Trip action, and exposes quick access to History, Settings, and About. A Sample Trip action creates demo data for quick exploration.

## UI
- **Empty Home**: brand text, welcome line, Start Trip button, Sample Trip link, and pill buttons for History/Settings/About.
- **Settings**: minimal placeholder with theme/info items.
- **About**: app summary and version label.

## Data
- Sample trip is created via `StorageService.createSampleTrip()`.
- Adds a device owner, two members, and three sample expenses.

## Navigation
- Home (no active trip) → History / Settings / About screens.
- Active trip now routes to a dedicated Trip screen under `lib/features/trip/`.

## Files
- [lib/features/home/empty_home_screen.dart](lib/features/home/empty_home_screen.dart)
- [lib/features/settings/settings_screen.dart](lib/features/settings/settings_screen.dart)
- [lib/features/about/about_screen.dart](lib/features/about/about_screen.dart)
- [lib/core/services/storage_service.dart](lib/core/services/storage_service.dart)
- [lib/core/riverpod/trip_provider.dart](lib/core/riverpod/trip_provider.dart)
- [lib/features/home/home_screen.dart](lib/features/home/home_screen.dart)
- [lib/features/trip/trip_screen.dart](lib/features/trip/trip_screen.dart)

## Gotchas
- Sample trip should only be used for onboarding; it does not replace existing data.
- All data is stored locally via Hive.

## Increment: Home Hub Host/Guest Split (In Progress)
- Replaced ambiguous single create action with explicit role entry points:
	- Start Trip as Host
	- Join Trip as Guest
- `HomeScreen` now routes to dedicated feature screens instead of inline trip creation dialog.
- `EmptyHomeScreen` now exposes both host and guest CTA paths while keeping History/Settings/About available.
- Added dedicated screens:
	- `lib/features/start_trip/start_trip_screen.dart`
	- `lib/features/join_trip/join_trip_entry_screen.dart`

Status:
- Home Hub upgrade: complete.
- Dedicated start/join entry screens: complete.
- Add-member options split in trip screen: pending next step.

Detailed implementation log for this increment:
- `docs/archi/home_hub_host_guest_flow_impl.md`
