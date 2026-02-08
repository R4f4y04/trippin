Implementation Summary & Roadmap
Development Philosophy: Offline-First
The core principle of Trippin is that connectivity is a bonus, not a requirement for basic function. The app must fully work on a single device first. Networking is added as a layer on top to synchronize that local data with others.

Phase 1: The Core Foundation (Local Mode)
Goal: Build a fully functional expense tracker that works perfectly on a single device.

Data Structure: Define the "Trip," "User," and "Expense" models. Crucially, the "User" model must support the "Squad" concept—where one device owner (the Squad Leader) manages multiple passive members (e.g., "Rafay" managing "Rafay," "Ali," and "Saad").

Expense Logic: Implement the interface to log costs.

Inputs: Who paid? (Select from Squad). Who was it for? (Select form all Trip members). How is it split? (Equal, Shares, Exact Amounts).

Local Storage: Save all data persistently on the device so it survives app restarts.

Outcome: A user can create a trip, add dummy members, log expenses, and see a running total, all without internet or Bluetooth.

Phase 2: The Handshake (Device Discovery)
Goal: Enable two devices to find and trust each other without the internet.

Discovery Mechanism: Implement a "Host" and "Guest" workflow.

Host: Starts a "Lobby" and broadcasts a signal.

Guest: Scans for nearby Lobbies.

Security & Verification: A manual verification step (like a PIN code or QR scan) to ensure the Guest is connecting to the right Host, not a random person nearby.

Permissions Handling: Gracefully handle the complex permissions required for peer-to-peer connectivity (Location, Bluetooth, Wi-Fi, Nearby Devices) on both Android and iOS.

Phase 3: The Sync (Data Transfer)
Goal: Synchronize the "Local Mode" data across the connected mesh.

Payload Transfer: Convert the data (Expenses, Members) into a format that can be sent over the air.

The "Squad" Sync: When a Guest joins, they must send their "Squad List" to the Host so the Host knows which passive members are now active.

Real-Time Updates: When an expense is added on a Guest device, it sends the data to the Host. The Host then validates it and broadcasts the update to all other connected Guests.

Resilience: Handle disconnections gracefully. If a user drops off, queue their data and try sending it again when they reconnect.

Phase 4: The Settlement (Math & Closure)
Goal: Calculate who owes whom and finalize the trip.

Verification: A "Lock Trip" feature where the Host freezes edits and asks all connected devices to confirm the final total.

The Algorithm: Implement a "Debt Simplification" algorithm.

Standard: A owes B, B owes C.

Optimized: A pays C directly to minimize the number of transactions.

Export: Generate a readable summary (Text or Image) that lists the final settlements clearly.

Recent Updates (2026-02-08)
- Split the active trip UI into a dedicated feature folder and components.
- Home screen now routes to the trip feature when a trip is active.
- Trip history refreshes immediately after finishing a trip.