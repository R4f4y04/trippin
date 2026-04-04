# Phase 2 Implementation (Step 1-2) — Handshake Bootstrap + Native Nearby

## Overview
Started Phase 2 with a modular handshake foundation for nearby device discovery and single-guest confirmation flow. Then upgraded the internals to real Nearby Connections on Android while preserving provider/UI contracts. Data sync remains deferred to Phase 3.

## Implemented Scope
- Locked Phase 2 decisions:
  - Verification: confirmation dialog.
  - Scope: single guest only.
- Added connection domain models.
- Added modular P2P and permissions services.
- Added Riverpod connection provider for lifecycle state transitions.
- Added connection feature screens and navigation entry from Settings.
- Integrated `nearby_connections` into `P2PService` for advertise/discover/request/accept/reject/disconnect.
- Integrated `permission_handler` in `PermissionsService` for runtime Bluetooth/location checks.
- Added required Android manifest permissions for Nearby.
- Added device-lost event handling from discovery callbacks.
- Added permission recovery actions (`Open App Settings`) in Host and Guest screens.
- Added guest re-scan action to improve discovery retry UX.
- Added explicit `Request Permissions Again` actions on Host/Guest permission-denied states.
- Made Android permission requests SDK-aware to avoid unsupported permission prompts.
- Fixed Android manifest permission declarations (removed invalid `minSdkVersion` usage on `uses-permission`).
- Updated location permission request policy: request location only on Android SDK `<= 32`.
- Fixed Nearby host start failure on Android 13+ by declaring `ACCESS_WIFI_STATE` and `CHANGE_WIFI_STATE` without SDK caps.
- Fixed guest discovery failure (`MISSING_PERMISSION_ACCESS_COARSE_LOCATION`) by declaring coarse/fine location permissions without SDK caps and requesting location permission explicitly.
- Mitigated host startup timeouts by making advertising start non-blocking and tolerant of delayed Nearby plugin responses.

## Architecture Mapping
### Providers
- `connection_provider.dart`
  - Owns role/status state (`idle`, `advertising`, `discovering`, `connected`, etc.).
  - Subscribes to P2P events and maps them to UI state.

### Services
- `p2p_service.dart`
  - Encapsulates handshake operations and emits typed events.
  - Uses native Nearby Connections API on Android.
  - Enforces single-guest mode by rejecting additional requests when one endpoint is connected.
- `permissions_service.dart`
  - Centralizes runtime permission checks and denial messaging.
  - Verifies location service is enabled.

### Models
- `connection_state.dart`
  - Defines role/status enums and immutable state model.
- `discovered_device.dart`
  - Device metadata + JSON helpers + UUID generation.

## UI
- `ConnectScreen`: mode chooser (Host vs Guest).
- `HostLobbyScreen`:
  - Starts advertising.
  - Handles incoming request with confirmation dialog.
  - Supports disconnect/stop lobby.
- `GuestScanScreen`:
  - Starts discovery.
  - Shows nearby hosts.
  - Uses confirmation dialog before sending request.

## Files
- [lib/core/models/connection_state.dart](lib/core/models/connection_state.dart)
- [lib/core/models/discovered_device.dart](lib/core/models/discovered_device.dart)
- [lib/core/services/p2p_service.dart](lib/core/services/p2p_service.dart)
- [lib/core/services/permissions_service.dart](lib/core/services/permissions_service.dart)
- [lib/core/riverpod/connection_provider.dart](lib/core/riverpod/connection_provider.dart)
- [lib/features/connection/connect_screen.dart](lib/features/connection/connect_screen.dart)
- [lib/features/connection/host_lobby_screen.dart](lib/features/connection/host_lobby_screen.dart)
- [lib/features/connection/guest_scan_screen.dart](lib/features/connection/guest_scan_screen.dart)
- [lib/features/settings/settings_screen.dart](lib/features/settings/settings_screen.dart)
- [docs/archi/phase2_spec.md](docs/archi/phase2_spec.md)
- [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
- [pubspec.yaml](pubspec.yaml)

## Gotchas
- Nearby handshake currently supports Android only in this phase.
- Location service must be enabled for stable Nearby discovery/connection.
- Confirmation dialogs are implemented at UI level for both Host and Guest flow.
- If a discovered host disappears, Guest UI now removes it and updates status.

## Next Step
- Improve endpoint-lost UX on Guest scan screen.
- Persist minimal connection session metadata for diagnostics.
- Phase 3 started: payload envelope contracts and sync service scaffolding are documented in:
  - [docs/archi/phase3_spec.md](docs/archi/phase3_spec.md)
  - [docs/archi/phase3_impl.md](docs/archi/phase3_impl.md)
