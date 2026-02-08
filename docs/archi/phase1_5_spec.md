# Phase 1.5 Plan (Single-Device Closure + History)

## Overview
Phase 1.5 completes the single-device experience by adding trip closure, editable expenses with revision history, trip history UI, and text-only export. All operations remain offline-first with Hive persistence and follow the three-tier architecture.

## Goals
- Allow users to finish a trip (read-only state) and optionally reopen it.
- Track a full edit history for expenses (previous amounts retained).
- Provide trip history UI and a trip detail view for past trips.
- Export a text summary of trip totals, balances, and history.

## Requirements
- Offline-first: all changes persisted to Hive immediately.
- No cloud backend.
- Providers contain no business logic (Services only).
- UUIDs for all new entities.
- Use `safeExecute` + `AppLogger` for I/O operations.

## Data Model Changes
### Trip
Add fields:
- `isClosed` (bool)
- `closedAt` (DateTime?)
- `lastModifiedAt` (DateTime)

### ExpenseRevision (NEW)
Tracks edits with full snapshot for audit.
- `id`
- `expenseId`
- `tripId`
- `editorId`
- `previousAmount`
- `previousName`
- `previousPayerId`
- `previousBeneficiaryIds`
- `previousNote`
- `createdAt`

### TripHistoryEvent (NEW)
Chronological event log for UI/export.
- `id`
- `tripId`
- `type` (enum: CREATE_TRIP, ADD_MEMBER, ADD_EXPENSE, EDIT_EXPENSE, DELETE_EXPENSE, CLOSE_TRIP, REOPEN_TRIP)
- `actorId` (optional)
- `summary` (string)
- `createdAt`

## Services
### StorageService
Add methods:
- `closeTrip(tripId)` / `reopenTrip(tripId)`
- `updateExpense(expenseId, updates)`
- `deleteExpense(expenseId)`
- `getTripHistory(tripId)`
- `appendHistoryEvent(event)`

Rules:
- Block add/edit/delete when trip is closed.
- On expense edits, create `ExpenseRevision` and `TripHistoryEvent`.

### ExportService (NEW)
Build text summary:
- Trip metadata
- Total spend
- Net balances
- Expense list
- History timeline

## Providers
- `TripController`: add close/reopen actions.
- `ExpensesController`: add update/delete actions.
- `HistoryController`: load trip history.
- `TripHistoryListController`: list all trips.

## UI/UX
### Finish Trip
- Button in trip view.
- Confirms close and sets trip read-only.

### Trip History
- List of all trips (title, date, total, member count, status).
- Tap to view trip details (expenses, balances, history).

### Expense Editing
- Edit and delete affordances on expense list.
- Edit flow captures previous values into history.

### Export
- Text-only summary shown in dialog and copyable.

## Gotchas
- Hive schema: append new `@HiveField` indexes only.
- Keep history immutable.
- Ensure UI reflects read-only state when trip is closed.

## Acceptance Criteria
- Closing a trip disables add/edit/delete.
- Expense edits preserve previous values in history.
- Trip history list shows all trips and detail view.
- Text export includes totals, balances, expenses, and history.
