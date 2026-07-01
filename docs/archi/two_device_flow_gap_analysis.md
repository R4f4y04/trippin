# Two-Device Test Flow — Gap Analysis & Follow-Up Plan

## 0. Purpose of this document

This is a **handoff document** for another agent (or future self) picking up
where the current investigation left off. It is written to be self-contained:
it assumes zero prior context beyond the codebase itself, cites file paths and
line numbers explicitly for every claim, and prescribes exact reproduction
steps and acceptance criteria.

- Do **not** treat any assertion here as gospel — re-verify anchors before
  editing. Line numbers shift.
- Do **not** implement fixes without first reproducing the corresponding
  behavior on a device or in a widget test. Some items in Section 5 are
  latent / conditional.

---

## 1. Prior context (what was already fixed before this session)

Before this session, two bugs from
[guest_balance_sync_issues_spec.md](file:///d:/Code/r4/trippin/docs/archi/guest_balance_sync_issues_spec.md)
had been fixed and are documented in
[guest_balance_sync_impl.md](file:///d:/Code/r4/trippin/docs/archi/guest_balance_sync_impl.md):

- **Fix 1** — Guest device's `deviceId` is threaded through the handshake so
  the host creates the guest trip member with the same UUID as the guest's
  local device owner. This makes `members.where((m) => m.isDeviceOwner)`
  succeed on the guest device, and the guest's personal balance stops being
  frozen at `₨ 0`.
- **Fix 2** — In [add_expense_sheet.dart:148-156, 278-283](file:///d:/Code/r4/trippin/lib/features/trip/sheets/add_expense_sheet.dart#L148-L156),
  when the current device is in guest mode
  (`connectionState.role == ConnectionRole.guest || widget.trip.deviceRole == 'guest'`),
  the "Who Paid?" horizontal chip list is filtered to the guest's device owner
  only and `onTap` is a no-op, so guests cannot attribute expenses to the host.

Both fixes landed in the last two commits on branch `func_touchups`
(`921cc8f` and `9ca0a51`).

---

## 2. Test run that was performed

Two physical devices. Host `r4`, guest `nomad`. Both members are the only two
trip members. Every expense used the default beneficiary selection, which the
Add Expense sheet initializes to **all members**
([add_expense_sheet.dart:48](file:///d:/Code/r4/trippin/lib/features/trip/sheets/add_expense_sheet.dart#L48)),
i.e. always 50/50 split between r4 and nomad.

Reported observations (as clarified in follow-up):

- The `total spent` shown at the top of the header **matched on both devices**.
- The single balance value shown next to each name = the **"Your balance"**
  value the header showed on **that person's own device**. i.e. `r4 +2500` is
  what r4's header displayed to r4; `nomad -2500` is what nomad's header
  displayed to nomad.

| # | Actor added | Payer | Amount | Total spent | r4 header shows | nomad header shows |
|---|-------------|-------|-------:|------------:|----------------:|-------------------:|
| 1 | r4          | r4    | 5,000  | 5,000       | +2,500          | −2,500             |
| 2 | nomad       | nomad | 2,560  | 7,560       | +1,220          | −1,220             |
| 3 | r4          | r4    | 1,270  | 8,830       | +1,855          | −1,855             |
| 4 | nomad       | nomad | 7,000  | 15,830      | −1,645          | +1,645             |
| 5 | r4          | nomad | 2,500  | 18,330      | −2,895          | +2,895             |

---

## 3. What the log confirms

### 3a. Balance math is correct at every step

Recompute independently: net = amount_paid − (total_spent / member_count).

Every row matches. The balance engine in
[expense_service.dart:11-49](file:///d:/Code/r4/trippin/lib/core/services/expense_service.dart#L11-L49)
is behaving correctly for the equal-split path.

### 3b. Fix 1 (guest balance sync) works end-to-end

Pre-fix, the guest's "Your balance" was hard-frozen at `₨ 0` because the guest
device could not find any member with `isDeviceOwner == true` in the trip's
member list (UUID mismatch — see
[guest_balance_sync_analysis.md](file:///d:/Code/r4/trippin/docs/archi/guest_balance_sync_analysis.md)).

The log shows nomad's header progressing `-2500 → -1220 → -1855 → +1645 →
+2895`, exactly the mathematically-correct values. That proves:

- The handshake is delivering `payload.deviceId` correctly.
- The host's `addMemberToTrip(..., id: payload.deviceId)` is using that ID.
- The guest's `replaceTripExpensesFromSync` sanitization is preserving
  `isDeviceOwner = true` on the guest's own row
  ([storage_service.dart:475-479](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart#L475-L479)).
- The `balancesProvider` lookup by that ID resolves to the correct net figure.

### 3c. Total spent syncs

Both devices agree on `total spent` at each step, which means
`SYNC_LEDGER` (host add) and `ADD_EXPENSE → SYNC_LEDGER` round-trip (guest
add) are propagating expenses to both boxes.

---

## 4. Gaps in the test evidence

These are things the current log does **not** answer. They are not necessarily
bugs — they are unverified areas.

### 4a. Sync timing / freshness

The log records the steady-state balance for each step. It does **not** record:

- How quickly the peer device's header updated after each add.
- Whether a manual pull-to-refresh or the AppBar refresh button
  ([trip_screen.dart:149-153](file:///d:/Code/r4/trippin/lib/features/trip/trip_screen.dart#L149-L153))
  was needed to make the number appear.

If either device silently required a refresh, that is a sync-freshness bug
hiding under a correct steady-state number. Follow-up test in Section 6a.

### 4b. Balances tab (not just header)

The header only ever shows `personalBalance` for the device owner
([trip_screen.dart:140-143](file:///d:/Code/r4/trippin/lib/features/trip/trip_screen.dart#L140-L143)).
The log confirms each device's *own* row. It does **not** confirm what the
device sees for the **peer's** row (visible only in the Balances tab and the
Settlement Summary screen). Follow-up test in Section 6b.

### 4c. Sign rendering for negative balances

At steps 4 and 5, r4's `personalBalance` is negative; at steps 1–3, nomad's
is negative. The tester wrote `-1645` / `-2895` / `-2500` in the log because
they knew the sign, not because they observed a `−` character on screen.

There is a real bug (Section 5a) that suppresses the `−` character in the
header text. Follow-up test in Section 6c is to eyeball whether the character
is actually rendered.

### 4d. Activity tab divergence

Never inspected. Suspected divergent per Section 5d.

### 4e. Payer-lock verification on the guest

Fix 2 restricts the guest's "Who Paid?" chip list to the guest themselves.
The log never opened the Add Expense sheet on the guest as a comparison. If
the fix silently regressed, expenses in step 2 and 4 would still work because
the *default* `_payerId` is the guest anyway, and the guest didn't try to
change it. Follow-up test in Section 6e.

### 4f. Total-spent latency vs. total-spent equality

The log reports "totals matched" as a single steady-state. Same freshness
gap as 4a — it does not tell us whether they were ever transiently different.

---

## 5. Bugs / latent issues identified from code review

Each item has: severity guess, exact anchor, why it's wrong, and a fix sketch.
Do not treat the fix sketches as instructions — reproduce first, then decide.

### 5a. Header drops the `−` for negative balances

- **Severity**: medium (visible, harmless calculation, but ambiguous).
- **Where**:
  [trip_header.dart:29](file:///d:/Code/r4/trippin/lib/features/trip/components/trip_header.dart#L29)
  and
  [trip_header.dart:114-141](file:///d:/Code/r4/trippin/lib/features/trip/components/trip_header.dart#L114-L141).
- **Symptom**: for positive `personalBalance`, header text is
  `Your balance: +₨ 2,500`. For negative, header text is
  `Your balance: ₨ 2,895` — the `−` is missing. Sign is only conveyed by
  the color (red) and the down-arrow icon.
- **Why**: the code splits sign handling into a `balancePrefix` that is `'+'`
  for non-negative and `''` for negative, then passes `personalBalance.abs()`
  into `formatPKR`, stripping the sign entirely. `formatPKR` itself emits the
  `-` when given a signed value ([currency_format.dart:8-13](file:///d:/Code/r4/trippin/lib/core/utils/currency_format.dart#L8-L13)),
  so this is a self-inflicted wound.
- **Fix sketch**: either
  1. Change `balancePrefix` to `personalBalance >= 0 ? '+' : '-'` and keep
     `.abs()`, or
  2. Drop `balancePrefix` entirely, use `formatPKR(personalBalance)` for
     negatives and prepend `+` only for non-negatives.
  Prefer option 2 — it matches how
  [settlement_summary_screen.dart:248](file:///d:/Code/r4/trippin/lib/features/trip/settlement_summary_screen.dart#L248)
  already does it.

### 5b. Balances tab drops the `−` too

- **Severity**: medium (same class of bug as 5a).
- **Where**:
  [balances_list.dart:146](file:///d:/Code/r4/trippin/lib/features/trip/components/balances_list.dart#L146).
- **Symptom / Why / Fix**: identical to 5a. `'${isPositive ? '+' : ''}${formatPKR(balance.abs())}'`
  yields `+₨ X` for creditors and `₨ X` (no sign) for debtors.

### 5c. Member colors and avatar order differ between host and guest

- **Severity**: medium (cross-device inconsistency; makes reconciliation
  confusing during use, but does not affect balances).
- **Where**:
  [storage_service.dart:223-227](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart#L223-L227)
  → [trip_screen.dart:121-126](file:///d:/Code/r4/trippin/lib/features/trip/trip_screen.dart#L121-L126)
  → color assignment via `getMemberColor(memberIndexMap[id])` throughout
  the trip UI.
- **Symptom**: the same member (say `nomad`) appears with a different color
  dot / avatar tint / order in the member strip on the host vs. on the guest.
- **Why**: `getUsersByIds` returns `box.values.where(...)`, which is Hive
  **insertion order**, not the order of the `ids` list passed in. Host box
  was populated `[hostOwner, guest]`; guest box was populated
  `[guestOwner, hostOwner]` (guest set up its device owner first, then
  received host's owner via `SYNC_LEDGER`). The `memberIndexMap` in
  `trip_screen.dart` therefore differs across devices.
- **Fix sketch**: sort the returned list to match `ids`' order:
  ```dart
  final byId = { for (final u in box.values) u.id: u };
  return [ for (final id in ids) if (byId.containsKey(id)) byId[id]! ];
  ```
  Then `trip.memberIds` becomes the canonical order both devices use.

### 5d. Activity/history timeline is device-local, not synced

- **Severity**: medium (advertised feature does not match implementation;
  each device sees only its own actions).
- **Where**:
  [storage_service.dart:_appendHistoryEvent](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart#L795-L809)
  is called from `createTripWithOwner`, `addMemberToTrip`, `addExpense`,
  `closeTrip`, `reopenTrip`, `deleteExpense`, `updateExpense`. It is **not**
  called from `mergeSyncedExpense`
  ([storage_service.dart:425-453](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart#L425-L453))
  or `replaceTripExpensesFromSync`
  ([storage_service.dart:455-518](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart#L455-L518)).
- **Symptom (with this test log)**: on r4's Activity tab, only the 3 r4-added
  expenses (steps 1, 3, 5) appear; on nomad's Activity tab, only the 2
  nomad-added expenses (steps 2, 4) appear. Add-member and create-trip events
  also only appear on the initiator device.
- **Fix sketch**: two options —
  1. Append history events on the receiving side too, in `mergeSyncedExpense`
     and `replaceTripExpensesFromSync`. Requires designing dedup so a
     receiver doesn't double-log for its own echoed events.
  2. Move history to a synced entity: include `List<TripHistoryEvent>` in
     `SyncLedgerPayload` and let the host be the canonical source, mirroring
     the expense-list replacement pattern.
  Option 2 is more consistent with the current "host is canonical" model.

### 5e. Race: manual "Add Connected Guest" button re-introduces the UUID-mismatch bug

- **Severity**: high (silently re-creates the exact class of bug Fix 1
  addressed).
- **Where**: the button flow is
  [trip_screen.dart:221-226](file:///d:/Code/r4/trippin/lib/features/trip/trip_screen.dart#L221-L226)
  → `_addConnectedGuestAsMember`
  [trip_screen.dart:431-474](file:///d:/Code/r4/trippin/lib/features/trip/trip_screen.dart#L431-L474)
  → `membersControllerProvider.addMember`
  [members_provider.dart:25-49](file:///d:/Code/r4/trippin/lib/core/riverpod/members_provider.dart#L25-L49)
  → `addMemberToTrip` **without** an `id`
  [storage_service.dart:323-346](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart#L323-L346).
  The `id: id` line at [storage_service.dart:342-346](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart#L342-L346)
  falls back to `Uuid().v4()` when null.
- **Symptom**: if the host taps this button before the guest's handshake
  arrives, or if the host manually pre-added a member with the same name
  before the guest even connected, the resulting member has a fresh random
  UUID. The subsequent handshake path dedup by name
  ([sync_service.dart:231-254](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart#L231-L254))
  sees "already a member" and skips creation. The guest's real `deviceId`
  is never registered → back to the pre-Fix-1 balance freeze.
- **Fix sketch**: either
  1. Remove the manual button — it is redundant with the handshake path.
  2. Dedup by `deviceId`, not by name, at all three touchpoints (see 5f).
  3. If both a manual "nomad" and a handshake "nomad" arrive, treat the
     handshake as authoritative and rewrite the local member's id.

### 5f. Member dedup keys by name, breaking legitimate namesakes

- **Severity**: medium (blocks a valid real-world scenario: two members
  named "Ali").
- **Where**:
  - handshake path:
    [sync_service.dart:231-235](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart#L231-L235)
  - manual "add connected guest as member" path:
    [trip_screen.dart:447-454](file:///d:/Code/r4/trippin/lib/features/trip/trip_screen.dart#L447-L454)
- **Symptom**: two different real people with the same casual name collapse
  onto one member row.
- **Fix sketch**: dedup by `deviceId`. For the manual add path, either
  disambiguate by prompting the host, or remove the button (see 5e fix 1).

### 5g. Guest sync overwrites guest-local user fields on every SYNC_LEDGER

- **Severity**: low-medium (invisible during this test; surfaces on rename).
- **Where**:
  [storage_service.dart:475-484](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart#L475-L484).
  Sanitization preserves only `isDeviceOwner`; `name`, `managedBy`, and
  `createdAt` all come from the host's payload.
- **Symptom**: if the guest renames themselves via Settings mid-trip, the
  next `SYNC_LEDGER` snaps their local name back to whatever the host has.
  Also, the guest's device-owner row ends up with `managedBy = hostOwnerId`,
  which is semantically incoherent for a device owner.
- **Fix sketch**: preserve `managedBy` too (device owner should keep
  `managedBy = null`), and either don't overwrite `name` when
  `existingLocal.isDeviceOwner == true`, or push renames back to the host
  via a `RENAME_MEMBER` message.

### 5h. Rapid guest add — brief expense disappearance on guest device

- **Severity**: low (transient UI flash; harder edge: possible loss on
  disconnect mid-flow).
- **Where**: the delete-then-write cycle in
  [storage_service.dart:499-509](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart#L499-L509).
- **Symptom / scenario**:
  1. Guest adds A → local box = `[A]` → sends `ADD_EXPENSE(A)`.
  2. Guest adds B before A's round-trip completes → local box = `[A, B]` →
     sends `ADD_EXPENSE(B)`.
  3. Host merges A, echoes `SYNC_LEDGER([A])`.
  4. Guest applies: **wipes local expenses**, writes `[A]`. B is gone from
     the guest UI momentarily.
  5. Host merges B, echoes `SYNC_LEDGER([A, B])`. B reappears.
  If the connection drops between 4 and 5, B is on host but no longer on
  guest until next successful sync.
- **Fix sketch**: change `replaceTripExpensesFromSync` from
  "delete all, rewrite from payload" to "compute set difference, delete
  removed, upsert incoming", so it becomes idempotent w.r.t. locally-added
  items that the host is still processing. Alternatively: on guest, don't
  apply an incoming ledger whose expense set is a strict subset of the local
  set — wait for the next one.

### 5i. `trip.memberIds` append lacks a duplicate guard

- **Severity**: low (currently guarded upstream by the name-based dedup;
  becomes a real bug the moment upstream changes).
- **Where**:
  [storage_service.dart:347-348](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart#L347-L348).
  Unconditionally appends `member.id` to `trip.memberIds`.
- **Fix sketch**: guard with `if (!trip.memberIds.contains(member.id))`.

---

## 6. Follow-up test plan

Every test below expects **two physical Android devices**, hive cleared on
both, and a fresh trip. Record actual observations against expectations —
"pass" is only the specific behavior described.

### 6a. Sync freshness

**Goal**: prove or disprove that the peer device updates without a manual
refresh.

**Setup**: host = `r4`, guest = `nomad`. Connect. Add nothing yet.

**Steps**:
1. Host adds expense of 1,000 paid by host, both as beneficiaries. Start a
   stopwatch the moment "Save Expense" is tapped on host.
2. Do **not** touch the guest device. Observe the guest's header.
3. Note the elapsed time when the guest's "Your balance" transitions from
   `+₨ 0` to `-₨ 500`.
4. If it does not update within 15 seconds without user input, tap the
   AppBar refresh icon on guest and note whether it updates immediately.
5. Repeat symmetrically: guest adds 1,000 paid by guest, watch host.

**Expected**: both directions update within a couple of seconds without
manual refresh.

**If fails**: capture logcat of both devices during the test. Look for
`SyncService started`, `envelopeSent`, `envelopeReceived`, and
`ledgerAppliedOnGuest` / `Host broadcasted SYNC_LEDGER` log lines to
determine whether the payload arrived but the UI didn't rebuild, or the
payload never arrived at all.

### 6b. Peer balance visible on Balances tab

**Goal**: confirm each device shows *both* rows on the Balances tab, not
just its own.

**Steps**: run the exact 5-step flow from Section 2. After step 5:
1. On r4, open the Balances tab. Expect two rows: `r4 −2,895` and
   `nomad +2,895`.
2. On nomad, open the Balances tab. Expect two rows with the same numbers.
3. On r4, open the "Simplified Settlements" section within the Balances
   tab. Expect one transfer: `r4 → nomad, ₨ 2,895`.
4. Repeat step 3 on nomad. Expect the same single transfer.

**If fails**: the peer's row is missing → `getUsersByIds` isn't returning
the peer. Check `trip.memberIds` and Hive `usersBox` on the failing device.

### 6c. Sign rendering for negative balances (verifies 5a and 5b)

**Goal**: check whether the physical screen renders `−`.

**Steps**: after step 4 of the Section-2 flow (r4 at `-1,645`, nomad at
`+1,645`):
1. On r4, screenshot the header. Zoom in to the `Your balance:` text.
2. Look at the exact characters. Expected once fixed: `Your balance: -₨ 1,645`.
   Currently expected buggy render: `Your balance: ₨ 1,645`.
3. On r4, tap Balances tab. Look at the r4 row's right-hand amount label.
   Same check.
4. On nomad, do the same after step 1 of the flow (nomad at `-2,500`).

**If confirms bug**: apply the fix in 5a and 5b, then re-run this test
looking for the `−` character.

### 6d. Activity tab divergence (verifies 5d)

**Goal**: show both devices' Activity tabs disagree.

**Steps**: after step 5 of the Section-2 flow:
1. On r4, open Activity. Enumerate events shown. Expected today:
   CREATE_TRIP, ADD_MEMBER (self), ADD_MEMBER (nomad via handshake),
   ADD_EXPENSE ×3 for steps 1, 3, 5. **Not** the two nomad-added
   expenses.
2. On nomad, open Activity. Expected today: local ADD_MEMBER (self) at
   join time, ADD_EXPENSE ×2 for steps 2, 4. **Not** any r4-added
   expenses or the trip creation.

**Note**: on the guest the exact set of local events depends on whether
`_appendHistoryEvent` fires during `setOrCreateDeviceOwner` (it does not —
only `createTripWithOwner` fires it). Adjust expectations based on the
actual codepaths the guest hit.

**If confirms bug**: pick a fix strategy from 5d.

### 6e. Payer-lock still enforced on guest (verifies Fix 2 didn't regress)

**Steps**: with one expense already in the ledger,
1. On nomad, tap the FAB. Open Add Expense sheet.
2. Look at the "Who Paid?" horizontal chip list. Expected: exactly **one**
   chip, showing `nomad`, in a "selected" state.
3. Tap the r4 area to the right of the chip list (empty region). Expected:
   nothing happens.
4. If more than one chip is shown, take a screenshot and check
   `connectionState.role` and `trip.deviceRole` — see Fix 2's condition at
   [add_expense_sheet.dart:148-156](file:///d:/Code/r4/trippin/lib/features/trip/sheets/add_expense_sheet.dart#L148-L156).

### 6f. Member color / order consistency (verifies 5c)

**Steps**: after step 1 of the Section-2 flow:
1. Screenshot the MemberAvatarStrip on r4 (upper area, under the header).
2. Screenshot the same strip on nomad.
3. Compare: is `r4` on the left in both? Same color dot?
4. Do the same for the Balances tab bar colors and the Expense card left
   color-bar (the `payerColor` in
   [expenses_list.dart:93-95](file:///d:/Code/r4/trippin/lib/features/trip/components/expenses_list.dart#L93-L95)).

**If mismatched**: fix in 5c.

### 6g. Rapid-guest-add flash (verifies 5h)

**Goal**: reproduce the transient disappearance of a second guest expense.

**Steps**: with host and guest connected,
1. On nomad, tap FAB → fill Add Expense (`Fuel, 500`) → Save.
2. Immediately (within ~1s) on nomad, tap FAB again → fill
   (`Chai, 200`) → Save.
3. Watch nomad's Expenses list. Note whether "Chai" briefly disappears
   and then reappears, or stays visible the whole time.
4. Also watch the total-spent header for a dip.

**If reproduced**: apply the idempotent-merge fix sketched in 5h.

### 6h. Host pre-add of same-named member breaks handshake (verifies 5e / 5f)

**Steps**:
1. Host creates trip. Before nomad joins, host manually adds a member
   named `nomad` via Add Member Options Sheet → Add Local Member.
2. Nomad joins (guest flow), same name.
3. After sync, check on nomad: is "Your balance" `+₨ 0` (pre-Fix-1
   symptom returned)?
4. On host, check trip.memberIds count. Expected buggy behavior: only the
   pre-added `nomad` (with random UUID) exists — handshake dedup by name
   skipped creation of the real guest.

**If reproduced**: pick a fix from 5e/5f.

### 6i. Manual "Add Connected Guest" race (verifies 5e)

**Steps**: harder to reproduce reliably. Best effort —
1. Two devices with `dart:developer` timeline running.
2. Guest sends connection request.
3. Host accepts. As soon as the connection banner turns "Connected",
   tap the "Add connected guest as member" button in the connection
   status banner as fast as possible.
4. Compare: which fires first, the handshake auto-add
   ([sync_service.dart:236-249](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart#L236-L249))
   or the manual button?
5. Inspect Hive's `usersBox` on host — is there **one** member with the
   guest's `deviceId`, or **one** with a random UUID + a name collision
   suppressing the handshake add?

**If reproduced**: fix as in 5e.

---

## 7. Suggested priority order

Roughly, high value : low effort first.

1. **5a + 5b** — sign rendering. Trivial text change, immediate visible
   improvement.
2. **5c** — member ordering. Small change to `getUsersByIds`, wide impact
   on cross-device visual consistency.
3. **5e + 5f** — dedup and manual-add race. Prevents Fix 1 from silently
   regressing. Same touchpoint, do them together.
4. **5i** — trivial guard next to 5e/5f.
5. **5d** — activity sync. Bigger design decision (option 1 vs. option 2
   in the fix sketch). Do only after aligning with product intent.
6. **5g** — guest-owner overwrite. Fix along with any rename UX work.
7. **5h** — rapid-add flash. Rare in practice; defer unless 6g reproduces
   easily.

---

## 8. Files that will most likely change

For quick orientation during implementation:

- [lib/features/trip/components/trip_header.dart](file:///d:/Code/r4/trippin/lib/features/trip/components/trip_header.dart) — 5a
- [lib/features/trip/components/balances_list.dart](file:///d:/Code/r4/trippin/lib/features/trip/components/balances_list.dart) — 5b
- [lib/core/services/storage_service.dart](file:///d:/Code/r4/trippin/lib/core/services/storage_service.dart) — 5c, 5g, 5h, 5i
- [lib/core/services/sync_service.dart](file:///d:/Code/r4/trippin/lib/core/services/sync_service.dart) — 5e, 5f
- [lib/features/trip/trip_screen.dart](file:///d:/Code/r4/trippin/lib/features/trip/trip_screen.dart) — 5e (delete or gate the button)
- [lib/core/riverpod/members_provider.dart](file:///d:/Code/r4/trippin/lib/core/riverpod/members_provider.dart) — 5e (if reworking `addMember` to accept an id)

---

## 9. Non-goals of this document

- Not a spec for **how** to fix. The fix sketches are directional; the
  implementing agent should read the surrounding code before deciding.
- Not a claim that any Section-5 item is **currently observed** in a
  running app except where the Section-2 flow already demonstrated it.
  Everything else is derived from static reading and should be
  reproduced first via Section 6 before being fixed.
- Not exhaustive on P2P-transport / connection-lifecycle bugs — the
  session focused on the ledger/balance path.
