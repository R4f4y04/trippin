# Phase 2 Implementation (Step 1) — Handshake Bootstrap

## Overview
Started Phase 2 with a modular handshake foundation for nearby device discovery and single-guest confirmation flow. This step establishes models, services, provider state management, and UI entry points while keeping data sync deferred to Phase 3.

## Implemented Scope
- Locked Phase 2 decisions:
  - Verification: confirmation dialog.
  - Scope: single guest only.
- Added connection domain models.
- Added modular P2P and permissions services.
- Added Riverpod connection provider for lifecycle state transitions.
- Added connection feature screens and navigation entry from Settings.

## Architecture Mapping
### Providers
- `connection_provider.dart`
  - Owns role/status state (`idle`, `advertising`, `discovering`, `connected`, etc.).
  - Subscribes to P2P events and maps them to UI state.

### Services
- `p2p_service.dart`
  - Encapsulates handshake operations and emits typed events.
  - Includes mock bootstrap behavior for discovery/testing before native Nearby wiring.
- `permissions_service.dart`
  - Centralizes permission checks and denial messages.

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

## Gotchas
- This step uses a mock P2P bootstrap flow for UI/provider validation.
- Native Nearby plugin integration is intentionally deferred to the next Phase 2 step.
- Web path returns unsupported in permissions service.

## Next Step
- Replace mock internals in `P2PService` with actual Nearby Connections integration and platform permission wiring, while keeping provider and UI APIs unchanged.
