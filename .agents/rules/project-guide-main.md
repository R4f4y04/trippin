---
trigger: always_on
---

🎯 Project Overview
Trippin is an offline-first, peer-to-peer (P2P) expense splitting application built with Flutter. It uses Hive for local persistence and Google Nearby Connections for offline data synchronization. This document provides comprehensive guidance for AI coding agents.

🏗️ Architecture & Code Organization
Three-Tier Offline Architecture (MANDATORY)
All data interactions must follow this strict pattern:

1. Providers Layer (lib/core/riverpod/)
Purpose: State management using Riverpod.

Pattern: Handle UI state and reactive data streams.

Example: trip_provider.dart, connection_provider.dart.

Rule: Providers should NOT contain business logic. They call Services.

2. Models Layer (lib/core/models/)
Purpose: Data structures and Hive Adapters.

Pattern: Pure Dart classes with:

freezed or json_serializable (for P2P payloads).

HiveField annotations (for local storage).

Rule: Models must handle UUID generation.

3. Services Layer (lib/core/services/)
Purpose: Business logic, Database I/O, and P2P Networking.

Pattern: Singleton or Static methods.

Key Services:

StorageService (Hive wrapper).

P2PService (Nearby Connections wrapper).

Rule: All data mutations happen here.

📚 Documentation Standards (MANDATORY)
Rule: Whenever a feature is planned or implemented, you must create or update a documentation file.

Location: Store files in docs/[feature_category]/.

Format: Markdown (.md).

Naming: [feature_name]_spec.md or [feature_name]_impl.md.

Content:

Planned: Overview, Requirements, Data Models.

Implemented: Implementation details, "Gotchas", and usage guide.

🛡️ Error Handling & Logging (SIMPLIFIED)
AppLogger (Console Only)
For this phase, use a simple static class wrapping debugPrint to keep the console readable. Do not use external crash reporting services yet.

Dart

// lib/core/services/logger_service.dart
class AppLogger {
  static void info(String message) => debugPrint('ℹ️ [INFO]: $message');
  static void warning(String message) => debugPrint('⚠️ [WARN]: $message');
  static void error(String message, [dynamic error, StackTrace? stack]) {
    debugPrint('🔴 [ERROR]: $message');
    if (error != null) debugPrint('Error: $error');
    if (stack != null) debugPrint('Stack: $stack');
  }
}
safeExecute Pattern (Minimal)
Wrap async operations to prevent crashes.

Dart

import '../core/utils/safe_execute.dart';

// Usage
await safeExecute(
  operation: () async {
    await StorageService.saveExpense(expense);
  },
  onError: (e) => AppLogger.error('Failed to save expense', e),
);
🎨 UI/UX Guidelines
Theme System
Color Scheme: Dark Mode First. Deep Blues, Purples, and high-contrast Neon accents.

Design Philosophy: Sleek, Futuristic, readable in bright sunlight.

Theme Access: Use Theme.of(context) strictly.

UI Component Hierarchy
Reuse: Use shared widgets from lib/ui_components/.

Feedback: ALWAYS show feedback for async actions (Spinners, Snackbars).

💾 Data & Networking Patterns
Local Persistence (Hive)
Box Management: Open boxes lazily.

Write Policy: Update UI state AND Disk simultaneously.

P2P Networking (Nearby Connections)
Payloads: Always wrap data in a standardized JSON envelope:

JSON

{ "type": "EXPENSE_ADD", "payload": { ... }, "timestamp": 123456789 }
Connection State: Handle Disconnected and Connected states explicitly in the UI.

⚠️ Critical Rules
NEVER DO
❌ Assume Internet Access: The app must work 100% offline.

❌ Hardcode IDs: Always use UUIDs.

❌ Skip Documentation: If you build it, you document it in docs/.

ALWAYS DO
✅ Three-Tier Arch: Provider → Service → Hive/P2P.

✅ Handle Permissions: Gracefully handle Bluetooth/Location permission denials.

✅ Log Everything: Use AppLogger to print P2P events to the console.

🎯 Code Generation Guidelines
When generating code:

Check Docs: Look for existing specs in docs/.

Follow Offline-First: Ensure data saves to Hive before trying to sync.

Safety: Wrap I/O in safeExecute.

Documentation: If this is a new feature, output the Code AND the Documentation file.