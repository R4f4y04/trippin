# Guest Balance & Payer Gating — Root Cause Analysis

This document contains the deep code analysis for the two problems reported in
[guest_balance_sync_issues_spec.md](file:///d:/Code/r4/trippin/docs/archi/guest_balance_sync_issues_spec.md).

---

## Problem A: Guest "Your Balance" is Frozen at ₨ 0

### Symptom

On the guest device, the "Your balance" field in the trip header always displays
`+₨ 0`, regardless of how many expenses exist or who paid. The host device's
balance updates correctly.

### How the Balance is Displayed

The chain is:

1. [trip_screen.dart:140-143](file:///d:/Code/r4/trippin/lib/features/trip/trip_screen.dart#L140-L143):
   ```dart
   final owner = members.where((m) => m.isDeviceOwner).toList();
   final personalBalance = owner.isNotEmpty
       ? (balances[owner.first.id] ?? 0.0)
       : 0.0;
   ```
2. `members` comes from `membersControllerProvider`, which loads users by
   `trip.memberIds` — i.e. only trip members.
3. `balances` comes from [balancesProvider](file:///d:/Code/r4/trippin/lib/core/riverpod/balances_provider.dart#L13-L29),
   which calls `ExpenseService.calculateNetBalances(members, expenses)`.
4. [expense_service.dart:11-12](file:///d:/Code/r4/trippin/lib/core/services/expense_service.dart#L11-L12)
   initializes the balance map using `member.id` keys from the **members list**.

### Root Cause: UUID Mismatch Between Guest Device Owner and Trip Member

This is the central finding. Two completely different `User` objects represent the
guest — with **different UUIDs**:

| Entity | Where Created | UUID | `isDeviceOwner` | In `trip.memberIds`? |
|--------|---------------|------|-----------------|---------------------|
| Guest's local device owner | Guest device via `setOrCreateDeviceOwner` in [join_trip_entry_screen.dart:244](file:///d:/Code/r4/trippin/lib/features/join_trip/join_trip_entry_screen.dart#L244) | UUID-A (e.g. `abc-111`) | `true` | **No** |
| Guest trip member on host | Host device via `addMemberToTrip` in [sync_service.dart:239](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart#L239) → [storage_service.dart:341](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart#L341) | UUID-B (e.g. `xyz-999`) | `false` | **Yes** |

#### What happens step by step:

1. **Guest joins**: On the guest device, `setOrCreateDeviceOwner(name: "r4")` creates
   a `User` with `id = UUID-A`, `isDeviceOwner = true`. This user is stored in
   the guest's local Hive `usersBox`.

2. **Host receives handshake**: The host's `SyncService` auto-adds a **new** member
   via `addMemberToTrip(name: "r4", managedBy: hostOwnerId)`. This calls
   `User.createMember(name: "r4")` which generates `id = UUID-B` — a completely
   new UUID. This user is added to `trip.memberIds` on the host.

3. **Host sends SYNC_LEDGER**: The ledger payload includes the members list. The
   member representing the guest has `id = UUID-B`, `isDeviceOwner = false`.

4. **Guest receives SYNC_LEDGER**: In `replaceTripExpensesFromSync`:
   - The member with `id = UUID-B` is written to the guest's Hive `usersBox`. Since
     it is a new ID (not matching the existing `UUID-A`), the sanitization check
     `usersBox.get(member.id)` returns `null`, so `isDeviceOwner` is set to `false`.
   - `trip.memberIds` is set to `[hostOwnerId, UUID-B]`.

5. **Balance lookup on guest**: `members.where((m) => m.isDeviceOwner)` searches
   through the trip members list (loaded by `trip.memberIds`). The trip members
   are the host owner (`isDeviceOwner = false` after sanitization) and the guest
   member (`UUID-B`, `isDeviceOwner = false`). **Neither has `isDeviceOwner = true`**.

6. The guest's actual device owner (`UUID-A`, `isDeviceOwner = true`) exists in
   Hive but is **not** in `trip.memberIds`, so it's never loaded by
   `membersControllerProvider`.

7. **Result**: `owner.isNotEmpty` evaluates to `false`, so `personalBalance = 0.0`.

#### Why the host works correctly:

On the host, the device owner was created via `createTripWithOwner` which stores
the owner in Hive AND adds their ID to `trip.memberIds`. So the host's device
owner IS a trip member, `isDeviceOwner = true` is preserved, and the balance
lookup succeeds.

### The Deeper Design Flaw

The fundamental issue is that the guest's device owner identity (`UUID-A`) and the
trip member identity for that guest (`UUID-B`) are created independently on
different devices and never linked. Expenses use `UUID-B` as `payerId` and
`beneficiaryIds` (since that's the member the host knows about), but the guest
device looks up balance by `UUID-A` (its local device owner) — which doesn't
appear in any expense records.

---

## Problem B: Guest Can Select Any Member as Payer

### Symptom

When the guest opens the "Add Expense" sheet, the "Who Paid?" section shows all
trip members as selectable options, allowing the guest to create expenses where
the host or other members are marked as the payer.

### Root Cause: No Role Gating in AddExpenseSheet

In [add_expense_sheet.dart:252-273](file:///d:/Code/r4/trippin/lib/features/trip/sheets/add_expense_sheet.dart#L252-L273),
the payer selection is a horizontal `ListView` iterating over `widget.members`
with no filtering or restrictions:

```dart
itemCount: widget.members.length,
// ...
onTap: () {
    setState(() => _payerId = member.id);
},
```

There is no check for `isGuestRole` to restrict the payer to only the device
owner. The default payer is correctly set to the device owner in `initState`
(line 42-43), but the guest is free to change it.

### Additional Sub-Issue: Default Payer May Be Wrong on Guest

Even the default payer logic has a latent issue:

```dart
final owner = widget.members.where((m) => m.isDeviceOwner).toList();
_payerId = owner.isNotEmpty ? owner.first.id : widget.members.first.id;
```

As established in Problem A, **no member in the guest's trip members list has
`isDeviceOwner = true`**. So `owner` is empty, and the fallback
`widget.members.first.id` is used — which is typically the host's device owner
(since members are ordered by creation time, and the host owner was created
first).

This means the guest's default payer is actually the **host**, not the guest
themselves. Combined with the unrestricted payer selection, this creates a
situation where expenses added by the guest may be attributed to the wrong person.

---

## Impact Summary

| Issue | Severity | Scope |
|-------|----------|-------|
| Guest balance always shows ₨ 0 | **Critical** | Core feature broken — guest cannot see their financial position |
| Guest can pick any payer | **High** | Violates host-authority model; creates ledger inconsistencies |
| Guest default payer is the host, not themselves | **High** | Silently attributes guest expenses to the host |

---

## Proposed Fix Strategy

### Fix 1: Resolve UUID Mismatch (Problem A Core Fix)

The guest device owner (`UUID-A`) and the guest trip member (`UUID-B`) must be
reconciled so the guest device can find itself in the trip members list.

**Two approaches:**

#### Option A: Host-Side — Use Guest's Device ID from Handshake

Instead of creating a brand-new user via `User.createMember()`, the host could
use the `deviceId` from `HandshakePayload` as the member's ID. This way
`UUID-A == UUID-B`.

**Pros**: Clean — single source of identity.
**Cons**: The host would need to store a User with an externally-sourced ID,
breaking the pattern of always generating UUIDs locally. Also requires ensuring
the guest's `deviceId` doesn't collide with existing host users.

**Changes needed**:
- [sync_service.dart:239](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart#L239):
  Instead of `addMemberToTrip(name: ...)`, create the User with the guest's
  `payload.deviceId` as the ID.
- [storage_service.dart](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart):
  Add a method like `addMemberToTripWithId` that accepts a pre-set ID.

#### Option B: Guest-Side — Map Local Device Owner to Synced Trip Member

After the guest receives the `SYNC_LEDGER`, find the synced member that matches
the device owner by name, and mark it as `isDeviceOwner = true` (or remap the
local device owner's ID to match the synced member's ID).

**Pros**: No change to host side.
**Cons**: Name matching is fragile (case sensitivity, duplicates).

**Changes needed**:
- [storage_service.dart:464-479](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart#L464-L479):
  After writing synced members, find the member whose name matches the local
  device owner, and set `isDeviceOwner = true` on that synced member.

#### Recommended: Option A (Host-Side ID Threading)

Option A is more architecturally sound because it establishes a single canonical
identity for the guest across both devices. The `HandshakePayload` already sends
`deviceId`, so it's a matter of using it when creating the member.

### Fix 2: Restrict Payer Selection for Guest Role (Problem B)

**Changes needed**:
- [add_expense_sheet.dart](file:///d:/Code/r4/trippin/lib/features/trip/sheets/add_expense_sheet.dart):
  Accept an `isGuestRole` parameter. When `true`:
  - Lock the payer to the device owner (don't render the selectable list, or
    render it as disabled/single-item).
  - The "Who Paid?" section should show only the guest's own member chip as
    a non-interactive, pre-selected element.
- [trip_screen.dart](file:///d:/Code/r4/trippin/lib/features/trip/trip_screen.dart):
  Pass `isGuestRole` to `AddExpenseSheet`.

### Fix 3: Correct Default Payer on Guest (Depends on Fix 1)

Once Fix 1 is applied and the guest's synced member has `isDeviceOwner = true`,
the existing default payer logic in `initState` (`members.where((m) => m.isDeviceOwner)`)
will automatically work correctly.

---

## Files Requiring Changes

| File | Fix | What Changes |
|------|-----|-------------|
| [sync_service.dart](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart) | Fix 1 | Use `payload.deviceId` when auto-adding guest member |
| [storage_service.dart](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart) | Fix 1 | Add method to create member with pre-set ID; update `replaceTripExpensesFromSync` to mark matching synced member as device owner |
| [add_expense_sheet.dart](file:///d:/Code/r4/trippin/lib/features/trip/sheets/add_expense_sheet.dart) | Fix 2 | Accept `isGuestRole`, lock payer to device owner for guests |
| [trip_screen.dart](file:///d:/Code/r4/trippin/lib/features/trip/trip_screen.dart) | Fix 2 | Pass `isGuestRole` to `AddExpenseSheet` |

---

## Verification Plan

After implementation, re-run the exact test scenario from the spec:

1. Host (`wasay`) creates trip → Guest (`r4`) joins.
2. Host adds ₨ 1,000 expense split equally → **verify** host shows `+₨ 500`,
   guest shows `-₨ 500`.
3. Guest adds ₨ 2,500 expense → **verify** host shows `-₨ 750`, guest shows
   `+₨ 750`.
4. Verify the "Who Paid?" selector on guest device only shows the guest's own
   member chip (non-selectable / locked).
5. Verify the default payer on guest is the guest, not the host.
