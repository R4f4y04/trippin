Phase 2: Device Discovery & Connectivity (The Handshake)
Objective
Enable offline devices to discover each other, establish a secure connection, and define their roles (Host vs. Guest) within the trip.

1. Network Topology (Star Architecture)
The app uses a Star Topology to manage connections efficiently.

The Host (Central Node): One device acts as the server. It holds the "Master Ledger."

The Guests (Peripheral Nodes): All other devices connect only to the Host. They do not connect to each other directly.

Protocol Recommendation: Use a high-level P2P framework (like Google Nearby Connections API with P2P_STAR strategy) that automatically switches between Bluetooth, BLE, and Wi-Fi Direct.

2. Connection Workflow
A. Advertising (The Host)
The Host device starts "Advertising" a service ID (e.g., com.trippin.app).

Payload: The Host broadcasts a unique Trip Code or Device Name (e.g., "Rafay's Trip").

Security: Generate a 4-digit Auth Token to display on the screen.

B. Discovery (The Guest)
Guest devices scan for nearby advertisers.

UI: Display a list of found devices (e.g., "Found: Rafay's Trip").

Action: User taps to request a connection.

C. The Handshake (Verification)
Visual Check: Both devices must display the same Auth Token on screen.

User Confirmation: Both Host and Guest must tap "Accept" to finalize the link.

Squad Info Exchange: Crucial Step. Immediately upon connection, the Guest sends a "Hello" payload containing:

Their Device ID.

Their Name.

The List of Passive Members (Squad) they are managing.

3. Error Handling
Permissions: The app must gracefully request Location, Bluetooth, and Wi-Fi permissions. If denied, guide the user to settings.

Timeout: If a connection hangs for >10 seconds, reset the state and notify the user.