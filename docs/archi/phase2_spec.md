# Phase 2 Spec — Handshake (Device Discovery)

## Overview
Phase 2 introduces offline peer discovery so nearby devices can find each other and establish a trusted connection without internet. This phase focuses on device discovery, connection initiation, and permission handling, but not data sync yet.

## Goals
- Allow a Host device to advertise a lobby.
- Allow a Guest device to discover nearby lobbies.
- Provide a manual verification step to prevent accidental connections.
- Handle permission denials gracefully and keep the app usable.

## Non-Goals (Deferred to Phase 3)
- Real-time data synchronization.
- Conflict resolution.
- Multi-device expense updates.

## User Stories
1. As a Host, I can start a lobby and see when a Guest requests to join.
2. As a Guest, I can scan nearby lobbies and request a connection.
3. As both Host and Guest, I must confirm a verification step before connection is finalized.
4. If permissions are denied, I should see a clear message and recovery action.

## Requirements
### Discovery & Connection
- Use Nearby Connections (offline) for discovery and connection setup.
- Host advertises a lobby with a readable name (trip title or device name).
- Guest displays a list of nearby lobbies with signal strength if available.

### Verification
- Manual verification uses a simple confirmation dialog on both devices.
- Connection only finalizes after both devices confirm.

### Permissions
- Handle Bluetooth + Location permissions explicitly.
- If denied, show a clear UI with steps to grant permissions.
- Do not block the rest of the app if permissions are missing.

## Architecture
Follow three-tier pattern strictly:

1. Providers (lib/core/riverpod/)
- `connection_provider.dart` (new): state for discovery, connecting, connected, error.

2. Services (lib/core/services/)
- `p2p_service.dart` (new): wrapper around Nearby Connections APIs.
- `permissions_service.dart` (new): centralized permission checks and prompts.

3. Models (lib/core/models/)
- `connection_state.dart` (new): enums / sealed classes for connection lifecycle.
- `discovered_device.dart` (new): device metadata for UI list.

## UI/UX
- Add a new “Connect Devices” entry in Settings or Home.
- Host flow:
  - Start Lobby → waiting screen with status and cancel.
- Guest flow:
  - Scan Nearby → list lobbies → tap to request connection.
- Verification dialog visible on both devices.

## Data Flow
1. Guest scans → Provider calls `P2PService.startDiscovery()`.
2. Host advertises → Provider calls `P2PService.startAdvertising()`.
3. On device found → UI list updates.
4. On connection request → show verification.
5. On approval → update state to `connected`.

## Logging
- Use `AppLogger` for all P2P events: discovery start/stop, device found, request, accepted/denied.

## Error Handling
- Use `safeExecute` to wrap async calls for discovery and connection.
- Provide user-facing error messages when discovery fails.

## Acceptance Criteria
- Host and Guest can discover each other offline.
- Both must confirm to finalize a connection.
- Permission denials are surfaced with a recovery action.
- UI remains responsive and app stays usable offline.

## Files (Planned)
- lib/core/riverpod/connection_provider.dart
- lib/core/services/p2p_service.dart
- lib/core/services/permissions_service.dart
- lib/core/models/connection_state.dart
- lib/core/models/discovered_device.dart
- lib/features/connection/
  - connect_screen.dart
  - host_lobby_screen.dart
  - guest_scan_screen.dart

## Open Questions
- Multi-guest support timing (deferred): this phase supports a single Guest only.
- Should Host advertise trip name or device name by default?

## Decisions (Locked for Phase 2)
- Verification method: confirmation dialog.
- Connection scope: single Guest only.
