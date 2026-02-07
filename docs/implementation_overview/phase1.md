Phase 1: The Core Foundation (Local Mode)
Objective
Build a fully functional, offline-first expense tracking application that runs on a single device. The goal is to perfect the Data Models, Local Persistence, and Expense Logic before introducing any peer-to-peer (P2P) connectivity.

1. Data Modeling (The "Squad" Architecture)
The application relies on a hierarchical user model to support the "Squad" feature (where one device manages multiple people).

A. The User / Entity
Concept: A User can be an Active Device Owner (the person holding the phone) or a Passive Member (a friend added manually to a squad).

Requirements:

Must have a unique ID (UUID recommended to prevent collision during future syncs).

Must track isDeviceOwner (Boolean).

Must track managedBy (ID of the Squad Leader).

B. The Trip
Concept: A container for all expenses and users.

Requirements:

Basic metadata: Title, Date, Cover Image (optional).

Members List: A list of all users involved (both Active and Passive).

Join Code: A 4-6 digit alphanumeric code generated locally (used later for P2P discovery).

C. The Expense
Concept: A record of a financial transaction.

Requirements:

Payer: Who paid? (Can be the Device Owner OR a Passive Member they manage).

Amount: The total cost.

Split Type:

EQUAL: Split evenly among selected members.

PERCENTAGE: Custom % for specific members.

SHARES: (e.g., "I had 2 slices, you had 1").

Beneficiaries: List of users involved in this expense.

2. Local Persistence (Offline-First)
Since the app may be used in remote areas (e.g., Northern Pakistan), data must be saved to the device immediately upon creation.

Recommendation: Use a lightweight NoSQL database (like Hive or Isar) or a robust key-value store.

Constraint: The data structure should be serializable (easily converted to JSON) to facilitate the future Bluetooth transfer in Phase 3.

3. Business Logic (The Math)
The core logic for splitting costs must be robust.

Validation: Ensure percentages add up to 100%. Ensure "Shares" result in a valid division of the total amount.

The "Net Balance" View:

Instead of just showing a list of transactions, the app should calculate a running total: Who is currently positive (owed money)? Who is negative (owes money)?

Note: Complex debt simplification (minimizing transactions) can be implemented in Phase 4, but the basic "You owe me X" calculation should happen here.

4. UI/UX Guidelines
Theme: Deep Dark Mode (High contrast Blue/Purple accents).

Input Flow:

Select "Add Expense".

Enter Amount.

Select Payer (Default to Device Owner, but allow selecting a Passive Member).

Select Beneficiaries (Multi-select list).

Save & Persist.