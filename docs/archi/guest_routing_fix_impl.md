# Guest Routing, Identity, and Role Gating Fix

## Overview
This document covers the implementation details for fixing guest routing, guest identity persistence, member distinction, and role-based interface gating. These changes ensure that guest devices are correctly routed to a guest-restricted version of the trip screen, their entered name is preserved, they are properly represented as trip members, and their guest role persists across sessions/rebuilds.

---

## 1. Guest Routing & Handshake Fix
Fixed a bug in the P2P connection flow where a guest device, after having its connection request accepted by the host device, was routed back to the Home Screen instead of the Trip Screen.

### Root Causes & Solutions:
- **Guest Handshake Never Sent**: In `_sendGuestHandshake()` inside [connection_provider.dart](file:///d:/Code/r4/trippin/lib/core/riverpod/connection_provider.dart), the code checked `if (owner == null || trip == null) return;`. The guest device has **no active trip** at connection time. Removed the `trip == null` check to allow handshakes to be sent prior to having a trip.
- **Missing Host Handshake Response**: Added a handler in `_applyIncomingEnvelope()` inside [sync_service.dart](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart) for `SyncMessageType.handshake` when the role is `host` to respond with `SYNC_LEDGER`.
- **Missing Trip/Members State Refresh on Guest**: Updated `_handleSyncEvent` in [connection_provider.dart](file:///d:/Code/r4/trippin/lib/core/riverpod/connection_provider.dart) for the `SyncEventType.ledgerAppliedOnGuest` case to refresh `tripControllerProvider` and `membersControllerProvider` so that the UI routes to the `TripScreen`.

---

## 2. Guest Identity, Role Gating, and Member Distinction Fix
Fixed the issue where guest devices behaved as hosts, had access to host-only features, and guest names were not displayed or synced as members.

### Implementation Details:

### A. Sanitize `isDeviceOwner` During Sync Ledger Application
- **Problem**: Synced member users sent by the host had `isDeviceOwner: true` for the host. When written to the guest's Hive box, it marked the host as the guest's device owner, confusing the role-detection logic.
- **Solution**: Modified `replaceTripExpensesFromSync` in [storage_service.dart](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart) to preserve the local `isDeviceOwner` state if it exists, or write `isDeviceOwner: false` for all synced members.

### B. Use `trip.deviceRole` as Fallback for Role Gating in TripScreen
- **Problem**: `TripScreen` determined host vs guest using only in-memory connection state (`connectionState.role == ConnectionRole.guest`). Since connection state is volatile and resets to `idle` on provider rebuild, guests were treated as hosts on rebuild/restart.
- **Solution**: Modified [trip_screen.dart](file:///d:/Code/r4/trippin/lib/features/trip/trip_screen.dart) to fall back to `trip.deviceRole == 'guest'` for role gating.

### C. Persist Guest Name as Device Owner on `JoinTripEntryScreen`
- **Problem**: The guest's entered name was never saved or used to create a device owner user, so the guest was never registered as a local user or sent with their real name in the handshake.
- **Solution**: Modified [join_trip_entry_screen.dart](file:///d:/Code/r4/trippin/lib/features/join_trip/join_trip_entry_screen.dart) to check and auto-fill the saved profile name, and write the guest name as the device owner in Hive before starting the scan.

### D. Auto-Add Guest as Trip Member on Host When Handshake Is Received
- **Problem**: The host received the handshake but never added the guest to the trip members list, meaning the guest was not distinguishable, couldn't split expenses, and wasn't in the members list.
- **Solution**: Modified the handshake handler in [sync_service.dart](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart) to parse the guest name from the payload, check if they are already in the trip members, and if not, add them as a managed member of the trip on the host.

### E. Persist Guest Device Role on Connection
- **Problem**: Unlike the host role which is persisted during trip creation, the guest role was never persisted in `ProfileService`, breaking session restoration if the guest restarted the app.
- **Solution**: Updated `connectionAccepted` event handling in [connection_provider.dart](file:///d:/Code/r4/trippin/lib/core/riverpod/connection_provider.dart) to call `ProfileService.instance.setDeviceRole('guest')` when the guest connects.

### F. Restore Connection Role from Persisted Profile on Provider Build
- **Problem**: When `ConnectionController` rebuilds, the role is set to `idle`.
- **Solution**: Updated `build()` in [connection_provider.dart](file:///d:/Code/r4/trippin/lib/core/riverpod/connection_provider.dart) to asynchronously retrieve and restore the persisted device role from `ProfileService`.

### G. Guest Name Communication via Nearby Connections (No "Trippin Guest")
- **Problem**: The guest name was hardcoded as `"Trippin Guest"` in `p2p_service.dart` during discovery/connection, causing the host to see `"Trippin Guest"` in connection alerts, connection banners, and auto-add the guest as `"Trippin Guest"`. Furthermore, a race condition existed between `HostLobbyScreen` immediately adding the guest under their Nearby display name vs `SyncService` adding them under their handshake payload name.
- **Solution**:
  1. Threaded the guest name from `ConnectionController` (by reading the local device owner name) through `P2PService.startDiscovery` and `P2PService.requestConnection`.
  2. Removed duplicate auto-add logic and listeners from [host_lobby_screen.dart](file:///d:/Code/r4/trippin/lib/features/connection/host_lobby_screen.dart), routing the flow purely through the `SyncService` handshake handler.
  3. Added a new `SyncEventType.guestMemberAddedOnHost` event emitted when `SyncService` successfully auto-adds the guest.
  4. Handled the event in `ConnectionController` to refresh `membersControllerProvider` and `tripControllerProvider` to automatically update the host UI avatar strip when the guest connects.

---

## Files Modified
- [lib/core/services/storage_service.dart](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart)
- [lib/features/trip/trip_screen.dart](file:///d:/Code/r4/trippin/lib/features/trip/trip_screen.dart)
- [lib/features/join_trip/join_trip_entry_screen.dart](file:///d:/Code/r4/trippin/lib/features/join_trip/join_trip_entry_screen.dart)
- [lib/core/services/sync_service.dart](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart)
- [lib/core/riverpod/connection_provider.dart](file:///d:/Code/r4/trippin/lib/core/riverpod/connection_provider.dart)
- [lib/core/services/p2p_service.dart](file:///d:/Code/r4/trippin/lib/core/services/p2p_service.dart)
- [lib/features/connection/host_lobby_screen.dart](file:///d:/Code/r4/trippin/lib/features/connection/host_lobby_screen.dart)

## Gotchas & Verification Notes
1. **Name Matching**: Auto-adding members matches guest names case-insensitively to avoid duplication.
2. **Persistence Timing**: The guest name is saved to Hive immediately when scanning starts.
3. **Restricted Actions on Guest UI**: Guests can add expenses but cannot see "Add Member", "Finish Trip", or edit/delete expenses they don't own.
4. **Race Condition Prevention**: Only the handshake handler in `SyncService` does the guest auto-addition, ensuring proper separation of concerns and matching of the device owner identity.
