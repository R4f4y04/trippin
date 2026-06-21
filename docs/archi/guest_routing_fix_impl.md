# Guest Routing and Sync Ledger Fix

## Overview
Fixed a bug in the P2P connection flow where a guest device, after having its connection request accepted by the host device, was routed back to the Home Screen instead of the Trip Screen.

## Root Cause Analysis
The issue was caused by a chain of three linked failures in the synchronization pipeline:

### Failure 1: Guest Handshake Never Sent (Primary Cause)
In `_sendGuestHandshake()` inside [connection_provider.dart](file:///d:/Code/r4/trippin/lib/core/riverpod/connection_provider.dart), the code checked `if (owner == null || trip == null) return;`. The guest device has **no active trip** at connection time — the trip only gets created on the guest when the first `SYNC_LEDGER` arrives from the host. Since `trip` was always `null` for the guest at this point, the handshake was silently dropped and never sent.

### Failure 2: Missing Host Handshake Response
The host had no handler for `SyncMessageType.handshake` in `_applyIncomingEnvelope()` inside [sync_service.dart](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart). Even if the handshake had been sent, the host would not have responded with the initial `SYNC_LEDGER`.

### Failure 3: Missing Trip/Members State Refresh on Guest
In [connection_provider.dart](file:///d:/Code/r4/trippin/lib/core/riverpod/connection_provider.dart), the `_handleSyncEvent` handler for `SyncEventType.ledgerAppliedOnGuest` only refreshed `expensesControllerProvider`. It did not refresh `tripControllerProvider` or `membersControllerProvider`. So even if a ledger eventually arrived, the `AppShell` would never detect the new trip and switch from `HomeScreen` to `TripScreen`.

## Implementation Details

### 1. Fix Guest Handshake to Not Require Active Trip
Updated `_sendGuestHandshake()` in [connection_provider.dart](file:///d:/Code/r4/trippin/lib/core/riverpod/connection_provider.dart):
- Removed the `trip == null` early-return guard.
- The handshake now sends with device info and an empty `managedMemberIds` list when no local trip exists.
- Only requires `owner != null` (device owner must be set).
- Added `AppLogger.info` trace on successful send.

### 2. Handle Guest Handshake on Host
Added a handler in `_applyIncomingEnvelope()` inside [sync_service.dart](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart) for `SyncMessageType.handshake` when role is `host`:
- Fetches the active trip.
- If found, retrieves all associated expenses and immediately sends the canonical ledger to the guest via `sendSyncLedger`.
- Added `AppLogger` tracing for both success and missing-trip cases.

### 3. Refresh Trip and Members State on Guest
Updated `_handleSyncEvent` in [connection_provider.dart](file:///d:/Code/r4/trippin/lib/core/riverpod/connection_provider.dart) for the `SyncEventType.ledgerAppliedOnGuest` case:
- Imported `members_provider.dart`.
- Added `tripControllerProvider.refresh()` and `membersControllerProvider.refresh()` calls before the existing expenses refresh.
- Once `tripControllerProvider` updates with the new trip, `AppShell` in [main.dart](file:///d:/Code/r4/trippin/lib/main.dart) reactively switches from `HomeScreen` to `TripScreen`.

## Expected Flow After Fix
1. Guest connects to host → `connectionAccepted` event fires.
2. `JoinTripEntryScreen` pops (returns to `AppShell` showing `HomeScreen`).
3. `_sendGuestHandshake()` sends `HANDSHAKE` with device info (no trip required).
4. Host receives `HANDSHAKE` → sends `SYNC_LEDGER` with trip data + expenses + members.
5. Guest receives `SYNC_LEDGER` → `replaceTripExpensesFromSync` creates the trip in Hive.
6. `ledgerAppliedOnGuest` event fires → refreshes `tripControllerProvider`, `membersControllerProvider`, `expensesControllerProvider`.
7. `AppShell` detects non-null trip → switches from `HomeScreen` to `TripScreen`.

## Files Modified
- [lib/core/services/sync_service.dart](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart)
- [lib/core/riverpod/connection_provider.dart](file:///d:/Code/r4/trippin/lib/core/riverpod/connection_provider.dart)

## Gotchas
- The guest will briefly see the HomeScreen after `JoinTripEntryScreen` pops, until the `SYNC_LEDGER` round-trip completes and the trip provider refreshes. This is a cosmetic timing issue — the functional routing is correct.
- The `HandshakePayload.managedMemberIds` will be empty on first guest connection. This is correct because the guest has no locally managed members until the host assigns them.
- The `SyncMessageType.handshake` envelope must be processed cleanly to ensure initial synchronization succeeds immediately upon connection establishment.
