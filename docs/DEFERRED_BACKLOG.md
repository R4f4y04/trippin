# Deferred Backlog

Centralized deferred items across phases. This file is the single source of truth for postponed work.

## Phase 3 Deferred

### 1. Advanced Queue Retry Strategy
- Scope: Add backoff/retry scheduling beyond reconnect-triggered flush.
- Reason deferred: Baseline reconnect flush already implemented for Phase 3 closure.
- Revisit trigger: After two-device validation confirms baseline stability.
- Priority: Medium.

### 2. Guest Update/Delete Dedicated Payloads
- Scope: Add payload types and role handling for guest edit/delete operations.
- Reason deferred: Current phase keeps host-authority canonical correction via `SYNC_LEDGER`.
- Revisit trigger: If product requires direct guest mutation parity before Phase 4.
- Priority: Medium.

### 3. Handshake Context Persistence
- Scope: Persist and expose host-side handshake metadata for diagnostics and future multi-guest mapping.
- Reason deferred: Not blocking single-guest baseline sync.
- Revisit trigger: Multi-guest planning kickoff.
- Priority: Low.

## Phase 4 Planned (Not Started)

### 1. Settlement Protocol + Read-Only Finalization
- Scope: End-trip verify flow, final sync confirmation, and closure UX.
- Reason deferred: Requires stable Phase 3 sign-off first.
- Revisit trigger: Phase 3 closure completion.
- Priority: High.

### 2. Min-Cash-Flow Debt Simplification
- Scope: Settlement algorithm to minimize transfer count.
- Reason deferred: Phase 4 core scope.
- Revisit trigger: Phase 4 implementation start.
- Priority: High.

### 3. Export/Share Settlement Summary
- Scope: Generate and share settlement output.
- Reason deferred: Depends on settlement protocol and algorithm outputs.
- Revisit trigger: After Phase 4 calculation logic lands.
- Priority: Medium.

## Future Deferred

### 1. Multi-Guest Support
- Scope: Host fan-out sync for more than one guest.
- Reason deferred: Current connection mode is intentionally single-guest.
- Revisit trigger: Product scope expansion after Phase 4.
- Priority: Medium.

### 2. iOS P2P Transport
- Scope: iOS-compatible offline transport implementation.
- Reason deferred: Current P2P stack is Android-focused.
- Revisit trigger: Platform expansion milestone.
- Priority: Medium.

### 3. Sync Diagnostics & Session Analytics
- Scope: Persisted sync telemetry, diagnostics dashboard, error drill-down.
- Reason deferred: Not required for baseline shipping loop.
- Revisit trigger: Post-Phase 4 quality/stability cycle.
- Priority: Low.

### 4. Full Join-Code Trip Admission Protocol
- Scope: Join-trip by code/QR and trip-level admission independent of nearby scan-only launcher flow.
- Reason deferred: Current increment uses structured join entry that routes into existing nearby lobby discovery.
- Revisit trigger: After baseline Home Hub + Host/Guest flow rollout stabilizes.
- Priority: Medium.

### 5. Final Visual Design System Pass
- Scope: Final look/feel, refined spacing, motion, typography, icon polish, and copy tuning after flow stabilization.
- Reason deferred: Product team requested functional flow lock before exact visual touchups.
- Revisit trigger: Once core host/guest navigation and role access flows are accepted.
- Priority: Medium.
