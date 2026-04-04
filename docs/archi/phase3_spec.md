# Phase 3 Spec — Data Synchronization (Android Single-Guest)

## Overview
Phase 3 adds expense data synchronization on top of the existing Phase 2 handshake connection.
Scope is intentionally limited to Android + single-guest to ship a reliable first sync loop.

## Decisions (Locked)
- Platform scope: Android only.
- Connection scope: single guest only.
- Payload format: JSON envelope over Nearby bytes payloads.
- Source of truth: Host authoritative ledger.
- Out of scope for this phase: iOS transport, multi-guest fan-out complexity, settlement algorithm (Phase 4), expanded diagnostics persistence.

## Goals
- Keep Host and Guest ledgers converged after expense create/edit/delete.
- Ensure Guest can create expenses while disconnected and retry on reconnect.
- Preserve local-first behavior and existing single-device flows.

## Architecture
Follow three-tier architecture:

1. Providers (`lib/core/riverpod/`)
- Keep state and reactive updates only.
- Route sync-aware mutations through services.

2. Models (`lib/core/models/`)
- Add serializable sync envelope and typed payload contracts.

3. Services (`lib/core/services/`)
- Extend `P2PService` transport to send/receive text payloads.
- Add sync orchestration service for role-based message routing.
- Keep Storage mutations centralized in services.

## Payload Contract
All payloads use this envelope:

```json
{
  "id": "uuid-v4",
  "type": "ADD_EXPENSE",
  "payload": { "...": "..." },
  "timestamp": 1712345678901
}
```

### Message Types
- `HANDSHAKE`
  - Guest -> Host immediately after connection.
  - Includes device/member context.
- `ADD_EXPENSE`
  - Guest -> Host when guest adds expense.
- `SYNC_LEDGER`
  - Host -> Guest canonical full ledger snapshot.
- `HEARTBEAT`
  - Optional keepalive.

## Sync Loop
### Scenario A: Host adds expense
1. Host writes to local storage.
2. Host emits canonical `SYNC_LEDGER` to Guest.
3. Guest applies canonical ledger and refreshes UI.

### Scenario B: Guest adds expense
1. Guest writes locally as pending.
2. Guest sends `ADD_EXPENSE` to Host.
3. Host validates and writes to canonical ledger.
4. Host emits `SYNC_LEDGER` back.
5. Guest reconciles and marks pending item synced.

## Resilience
- Guest keeps a local outbound sync queue while disconnected.
- Queue flushes in order on reconnection.
- Host authority wins for conflict resolution.

## Implementation Plan
1. Add sync envelope and typed payload models.
2. Extend P2P transport for send/receive text payload events.
3. Add SyncService orchestration layer with envelope parsing and role routing.
4. Wire providers to sync-aware write paths.
5. Add lightweight sync status UI cues.
6. Validate with two-device flows and disconnect/reconnect queue tests.

## Acceptance Criteria
- Connected Host/Guest reach same ledger after either side adds expense.
- Guest offline adds are retried and converge after reconnect.
- Malformed/unknown payloads do not crash connection state.
- Existing local-only features (close/reopen/history/export) continue to work.
