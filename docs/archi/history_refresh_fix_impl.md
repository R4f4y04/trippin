# Trip History Refresh Fix

## Overview
Fixed the issue where a finished trip did not appear in History until app restart. The trip list provider is now refreshed immediately after closing a trip.

## Implementation Details
- After closing a trip, `tripListControllerProvider.refresh()` is called.
- This ensures the Trip History screen reflects the latest completed trip without restart.

## Files
- [lib/features/trip/trip_screen.dart](lib/features/trip/trip_screen.dart)

## Gotchas
- Keep provider refreshes lightweight to avoid unnecessary UI stalls.

## Usage
Finish a trip and open History — the closed trip should appear instantly.
