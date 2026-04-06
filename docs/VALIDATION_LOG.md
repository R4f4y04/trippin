# Validation Log

## Phase 3 - Data Sync Validation

### Session 1
- Date: 2026-04-06
- Scope: Android two-device sync baseline
- Host Device: TODO
- Guest Device: TODO
- App Build/Commit: TODO
- Tester: TODO

## Scenario A - Host Add While Connected
- Steps:
  1. Connect host and guest.
  2. Create one expense on host.
  3. Refresh guest trip screen.
- Expected:
  - Guest receives canonical ledger update.
  - Expense appears once on both devices.
  - Totals match.
- Result: TODO (PASS/FAIL)
- Evidence:
  - Host screenshot: TODO
  - Guest screenshot: TODO
  - Notes: TODO

## Scenario B - Guest Add While Connected
- Steps:
  1. Keep host and guest connected.
  2. Create one expense on guest.
  3. Wait for host ingest and rebroadcast.
- Expected:
  - Guest status transitions pending -> synced.
  - Host receives expense.
  - Totals match on both devices.
- Result: TODO (PASS/FAIL)
- Evidence:
  - Host screenshot: TODO
  - Guest screenshot: TODO
  - Notes: TODO

## Scenario C - Guest Offline Queue + Reconnect
- Steps:
  1. Disconnect guest.
  2. Create 2-3 expenses on guest while offline.
  3. Verify queued count increases.
  4. Reconnect guest.
- Expected:
  - Queue flushes on reconnect.
  - Host receives queued expenses.
  - Guest and host ledgers converge.
  - No duplicate expenses.
- Result: TODO (PASS/FAIL)
- Evidence:
  - Offline guest screenshot: TODO
  - Reconnected host screenshot: TODO
  - Reconnected guest screenshot: TODO
  - Notes: TODO

## Scenario D - Mid-Flush Instability
- Steps:
  1. Queue multiple guest expenses while offline.
  2. Reconnect and interrupt connection mid-flush.
  3. Reconnect again.
- Expected:
  - Unsent queued items remain queued.
  - Subsequent reconnect attempts continue flushing remaining items.
  - No data loss and no duplicates after eventual convergence.
- Result: TODO (PASS/FAIL)
- Evidence:
  - Queue before interruption: TODO
  - Queue after interruption: TODO
  - Final converged state: TODO
  - Notes: TODO

## Regression - Local-Only Flows
- Checks:
  1. Create trip/member/expense without connection.
  2. Edit/delete expense.
  3. Close/reopen trip.
  4. Export behavior unchanged.
- Result: TODO (PASS/FAIL)
- Notes: TODO

## Analyzer/Quality Snapshot
- `dart analyze` (changed files): PASS on 2026-04-06
- `flutter analyze` (project-wide): TODO
- Known non-blocking lints: trip_screen deprecation/context lints pending cleanup
