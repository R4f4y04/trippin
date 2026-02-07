# Phase 1 Implementation (Local Mode)

## Overview
Phase 1 establishes the offline-first, single-device experience. It introduces Squad-aware models, Hive-backed persistence, Riverpod-based state orchestration, and a minimal UI flow for creating a trip, adding members, logging equal-split expenses, and viewing net balances.

## Requirements Satisfied
- Offline-first local persistence using Hive (no cloud backend).
- Three-tier architecture: Providers → Services → Models.
- Squad concept: device owner manages passive members.
- Equal split only (future split modes deferred).

## Data Models
### User
- Fields: `id`, `name`, `isDeviceOwner`, `managedBy`, `createdAt`.
- UUID generation handled in model factories.

### Trip
- Fields: `id`, `title`, `createdAt`, `memberIds`, `expenseIds`, `joinCode`, `coverImagePath`.
- Join code generated locally.

### Expense
- Fields: `id`, `tripId`, `payerId`, `amount`, `beneficiaryIds`, `splitType`, `createdAt`, `note`.
- Split type limited to `equal`.

## Services
### StorageService
- Initializes Hive, registers adapters, and opens boxes lazily.
- Creates trips with a device owner.
- Adds members and expenses while updating trip references.

### ExpenseService
- Computes net balances for each member.
- Equal split logic: payer credited full amount, beneficiaries debited per-person share.

## Providers
- `TripController`: loads/creates active trip.
- `MembersController`: loads/updates members for active trip.
- `ExpensesController`: loads/updates expenses for active trip.
- `balancesProvider`: derives net balances from members and expenses.

## UI Flow
- Home screen provides:
  - Trip creation (title + owner name).
  - Member management (adds passive members).
  - Expense logging (amount, payer, beneficiaries, note).
  - Net balance list.

## Gotchas
- Hive adapters are manual for now; ensure type IDs remain stable.
- Split type is limited to equal; percentage/shares are deferred.

## Usage Guide
1. Launch app.
2. Create a trip and device owner.
3. Add members managed by the device owner.
4. Log expenses with equal split and view balances.
