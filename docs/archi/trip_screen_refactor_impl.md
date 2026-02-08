# Trip Screen Refactor Implementation

## Overview
Refactored the large home screen into a dedicated Trip feature with reusable UI components. This isolates active-trip behavior from the empty home flow and improves maintainability.

## Implementation Details
- Active trip UI now lives in `TripScreen` under `lib/features/trip/`.
- Home screen only decides whether to show `EmptyHomeScreen` or `TripScreen`.
- Shared UI sections (members, expenses, balances, summary, closed banner) are split into `lib/features/trip/components/`.

## Files
- [lib/features/trip/trip_screen.dart](lib/features/trip/trip_screen.dart)
- [lib/features/trip/components/closed_banner.dart](lib/features/trip/components/closed_banner.dart)
- [lib/features/trip/components/trip_summary_card.dart](lib/features/trip/components/trip_summary_card.dart)
- [lib/features/trip/components/section_card.dart](lib/features/trip/components/section_card.dart)
- [lib/features/trip/components/members_list.dart](lib/features/trip/components/members_list.dart)
- [lib/features/trip/components/expenses_list.dart](lib/features/trip/components/expenses_list.dart)
- [lib/features/trip/components/balances_list.dart](lib/features/trip/components/balances_list.dart)
- [lib/features/trip/components/error_state.dart](lib/features/trip/components/error_state.dart)
- [lib/features/home/home_screen.dart](lib/features/home/home_screen.dart)

## Gotchas
- `TripScreen` owns the add/edit dialogs and refresh flow.
- Components are UI-only and do not contain business logic.

## Usage
When a trip is active, the home flow routes directly to `TripScreen`. All trip actions (add member, add/edit expense, finish trip) are handled there.
