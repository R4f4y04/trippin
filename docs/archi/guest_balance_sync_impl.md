# Guest Balance Sync & Payer Gating Constraints Implementation

## 1. Overview
This document covers the implementation details for fixing the guest personal balance sync freeze and enforcing guest-role payer input constraints. These fixes ensure that:
- Guest devices correctly calculate and display their personal net balance.
- Guest devices can only log expenses paid by the guest device owner.

---

## 2. Implementation Details

### A. UUID Mismatch Fix (Guest Balance Sync)
- **Problem**: When a guest device joined a trip, it registered a local device owner user with a random UUID (`UUID-A`). However, when the host device received the connection handshake, it auto-added the guest to the trip members list using `User.createMember()` which generated a completely new UUID (`UUID-B`). When the host synced the ledger, the guest device could not find its local device owner user (`UUID-A`) in the trip's members list (`UUID-B`), causing the personal balance display to fall back to `₨ 0`.
- **Solution**: Thread the guest's actual local `deviceId` (UUID) from the guest handshake payload to the host, ensuring the host creates the guest member with the same UUID.
  1. **User Model Update**: Modified `User.createMember` in [user.dart](file:///d:/Code/r4/trippin/lib/core/models/user.dart) to accept an optional `id` parameter.
  2. **Storage Service Update**: Modified `addMemberToTrip` in [storage_service.dart](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart) to accept an optional `id` parameter and pass it to `User.createMember`.
  3. **Sync Service Update**: Updated the handshake handler in [sync_service.dart](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart) to extract the guest's `deviceId` from the `HandshakePayload` and pass it as the `id` argument to `addMemberToTrip`.
- **Result**: The guest user shares the exact same UUID (`UUID-A`) across both host and guest devices. When the guest device receives the ledger, the local `isDeviceOwner` flag matches, allowing the UI to find the device owner user and compute their balance correctly.

### B. Payer Input Locking (Payer Gating for Guest Role)
- **Problem**: Guest devices were previously shown all trip members as selectable options in the "Who Paid?" horizontal list within the "Add Expense" bottom sheet, allowing them to add expenses attributed to the host or other members.
- **Solution**: Lock payer selection to the guest device owner on guest devices.
  1. **Check Connection Status & persisted role**: In [add_expense_sheet.dart](file:///d:/Code/r4/trippin/lib/features/trip/sheets/add_expense_sheet.dart), we watch `connectionControllerProvider` and check `trip.deviceRole == 'guest'` to identify if the current device is in guest mode.
  2. **Filter & Disable Selector**:
     - If the device is in guest mode, the payer list is filtered to display only the guest device owner user (avoiding default fallbacks to host).
     - Tap interactions (`onTap`) on the payer chip are disabled (replaces selecting other payers with a no-op callback `() {}`).
- **Result**: Guests can only select themselves as the payer when creating an expense, protecting host-ledger authority.

---

## 3. Files Modified
- [lib/core/models/user.dart](file:///d:/Code/r4/trippin/lib/core/models/user.dart)
- [lib/core/services/storage_service.dart](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart)
- [lib/core/services/sync_service.dart](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart)
- [lib/features/trip/sheets/add_expense_sheet.dart](file:///d:/Code/r4/trippin/lib/features/trip/sheets/add_expense_sheet.dart)

---

## 4. Verification & Linting
- Project static analysis ran cleanly using `flutter analyze`.
- Checked callbacks and double-underscores (`__` -> `_`) in list separators to prevent warning flags.
