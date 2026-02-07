Data Synchronization (The Sync)
Objective
Ensure that the "Trip Ledger" is identical on every device, regardless of who logs the expense. The Host is the "Source of Truth."

1. Data Payload Structure
All data sent over Bluetooth must be serialized (converted to bytes/strings).

Payload Types:

HANDSHAKE: Initial user info exchange.

ADD_EXPENSE: A new transaction.

SYNC_LEDGER: The Host sending the full updated list to everyone.

HEARTBEAT (Optional): A ping to check if the connection is alive.

2. The Sync Logic (The Loop)
Scenario A: Host Logs an Expense
Host saves expense to local database.

Host broadcasts SYNC_LEDGER payload to all connected Guests.

Guests receive payload -> Update local database -> Update UI.

Scenario B: Guest Logs an Expense
Guest saves expense locally (marked as "Pending Sync").

Guest sends ADD_EXPENSE payload to Host.

Host Validation: Host receives it, adds it to the Master Ledger.

Host broadcasts the new Master Ledger to ALL Guests (including the sender).

Guest receives update -> Marks expense as "Synced" (Green Checkmark).

3. Resilience (The "Spotty Connection" Protocol)
The Queue: If a Guest is disconnected, they can still use the app. Any new expenses are stored in a local SyncQueue.

Reconnection: When the device reconnects to the Host, the app automatically flushes the SyncQueue (sends all pending items).

Conflict Resolution: If two people edit the same expense (rare), the Host's version always wins ("Server Authority").