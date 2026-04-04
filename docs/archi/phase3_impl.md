# Phase 3 Implementation Log — Data Synchronization

## Scope
- Android only.
- Single-guest only.
- JSON envelope transport.

## Progress

### Step 1: Sync Contracts + Transport Plumbing
Status: Complete

Implemented:
- Added sync envelope model and message type enum:
  - `lib/core/models/sync_envelope.dart`
- Added typed payload models for handshake/add-expense/sync-ledger/heartbeat:
  - `lib/core/models/sync_payloads.dart`
- Generated serializers:
  - `lib/core/models/sync_envelope.g.dart`
  - `lib/core/models/sync_payloads.g.dart`
- Extended P2P transport service with message payload events and sending:
  - Added event types `payloadReceived` and `payloadSent`
  - Added `payload` field to `P2PEvent`
  - Added `sendTextPayload` in `P2PService`
  - Wired `acceptConnection` callbacks to forward received bytes payloads as text events
- Updated connection provider switch to handle new payload event types:
  - `lib/core/riverpod/connection_provider.dart`

Notes:
- This step intentionally does not yet mutate ledger state from received payloads.
- This step is foundation-only to avoid mixing transport changes with sync business logic.

### Step 2: Sync Orchestration Service
Status: Complete (Scaffold)

Implemented:
- Added `lib/core/services/sync_service.dart` scaffold:
  - Sync role abstraction (`host`/`guest`).
  - Sync event stream (`envelopeReceived`, `envelopeSent`, `invalidEnvelope`).
  - Envelope sending helpers:
    - `sendHandshake`
    - `sendAddExpense`
    - `sendSyncLedger`
    - `sendHeartbeat`
  - Incoming payload parsing via `SyncEnvelope.tryDecode` with malformed payload safety path.
- Wired service lifecycle to connection lifecycle in `connection_provider.dart`:
  - Start sync service on connection accepted.
  - Stop sync service on disconnect/host stop/provider dispose.

Notes:
- Step 2 currently parses and emits sync envelopes but does not yet mutate ledger state.
- Role-based business routing (Host apply + Guest reconcile) is implemented in Step 3.

### Step 3: Host/Guest Ledger Loop
Status: Complete (Baseline)

Planned:
- Host: local write -> broadcast canonical `SYNC_LEDGER`.
- Guest: local write -> `ADD_EXPENSE` -> reconcile on `SYNC_LEDGER`.

Implemented (initial wiring):
- Updated `lib/core/riverpod/expenses_provider.dart` to trigger sync after local mutations while preserving local-first writes.
- Host behavior now sends `SYNC_LEDGER` after add/update/delete when connected.
- Guest behavior now sends `ADD_EXPENSE` after local add when connected.
- Added `StorageService.getExpense` helper for update/delete mutation sync routing.

Implemented (inbound handling):
- `SyncService` now applies inbound envelopes by role:
  - Host receives `ADD_EXPENSE` -> merges expense into storage -> emits canonical `SYNC_LEDGER`.
  - Guest receives `SYNC_LEDGER` -> replaces trip expense set from host ledger.
- `ConnectionController` now listens to `SyncService` events and triggers expense provider refresh when inbound sync mutations are applied.
- Guest now sends `HANDSHAKE` payload immediately after connection is accepted with device owner + managed member IDs.

Still deferred from this step:
- Add pending/synced visual markers for guest-created expenses.

### Step 4: Queue + Reconnection Flush
Status: Complete (Baseline)

Planned:
- Guest offline outbox queue and in-order resend.
- Reconnect-triggered flush.

Implemented:
- Added persistent sync queue storage in `StorageService` using Hive string box:
  - `enqueueSyncEnvelope`
  - `getQueuedSyncEnvelopes` (timestamp-ordered)
  - `removeQueuedSyncEnvelope`
  - queue reset integration in `resetAll`
- Added queue APIs in `SyncService`:
  - `queueAddExpense` for offline guest expense messages
  - `flushGuestQueue` for in-order resend on reconnect
- Added reconnect behavior:
  - `SyncService.start` auto-triggers queue flush for guest role.
- Updated `ExpensesController` behavior:
  - guest + disconnected + local add => queue `ADD_EXPENSE` instead of dropping it.

Still deferred from this step:
- Backoff/retry scheduling strategy beyond reconnect-triggered flush.

### Step 5: Provider/UI Wiring + Validation
Status: In Progress

Planned:
- Provider integration for sync-aware write paths.
- Pending/synced/retrying indicators.
- Two-device validation script and logs.

Implemented:
- Added `expense_sync_status_provider.dart` to track per-expense sync state in Riverpod (pending/retrying/synced).
- Integrated status transitions into `ExpensesController`:
  - guest connected add -> `pending`
  - guest disconnected add -> queued + `retrying`
- Integrated status transitions into `ConnectionController` sync event handling:
  - host merge + guest ledger apply -> mark related expense IDs as `synced`
- Added sync badges in trip expenses UI:
  - `ExpensesList` now renders compact status chips (Pending/Retrying/Synced)
  - `TripScreen` passes sync-status map into `ExpensesList`

Pending in this step:
- Run two-device manual validation and capture evidence logs.

## Validation Log
- `dart analyze` on changed Phase 3 files: no issues found.
- `flutter analyze` project-wide: no new errors from this increment; existing baseline warnings/infos remain in unrelated files.
- `dart analyze` after Step 3 inbound handling: no issues found.
- `dart analyze` after Step 4 queue + flush wiring: no issues found.
- `dart analyze` after Step 5 status provider + UI badges: no issues found.
