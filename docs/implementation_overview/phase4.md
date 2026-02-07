Phase 4: Settlement & Closure (The Math)
Objective
Finalize the trip, lock the data to prevent changes, and calculate the most efficient way for everyone to pay each other back.

1. The "End Trip" Protocol
Host Action: Host taps "End Trip."

Lock State: The app enters "Read-Only Mode." No new expenses can be added.

Consensus (Optional but Recommended): Host sends a VERIFY_TOTAL request. All Guests get a popup: "Final Trip Total is 50,000 PKR. Confirm?"

Final Sync: Once confirmed, the Host ensures all devices have the exact final dataset.

2. The Simplification Algorithm
Do not just sum up debts. Minimize the number of bank transfers required.

Step 1: Calculate Net Balances

Calculate what everyone paid vs. what everyone consumed.

Result: User A: +500, User B: -200, User C: -300.

Step 2: Min-Cash-Flow Algorithm

Sort users by balance.

Take the biggest Debtor (owes most) and biggest Creditor (owed most).

Settle the smaller of the two amounts between them.

Repeat until all balances are zero.

Result: Instead of B paying A and C paying A separately, the algorithm might find a simpler path if multiple people are involved.

3. Export & Share
Generation: Create a clean textual summary or a generated image receipt.

Header: Trip Name & Total Cost.

Breakdown: "Ali owes Rafay: 2000", "Saad owes Rafay: 500".

Action: Share via system share sheet (WhatsApp, etc.) once internet connectivity returns.