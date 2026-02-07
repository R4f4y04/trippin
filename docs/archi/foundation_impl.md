# Foundation Initialization (Phase 0)

## Overview
This document records the foundational scaffolding for Trippin. It establishes the core directory structure, logging utilities, safe execution wrapper, and the initial app theme. This is not a feature implementation.

## Requirements
- Offline-first architecture (local persistence via Hive; no cloud backend).
- Three-tier structure: Providers → Services → Models.
- Theme: Night Owl (deep navy/black background, electric purple/blue accents, high contrast text).
- Riverpod `ProviderScope` at root.

## Implementation Details
### Directory Structure
Created the following folders under `lib/`:
- `lib/core/riverpod/`
- `lib/core/models/`
- `lib/core/services/`
- `lib/core/utils/`
- `lib/core/theme/`
- `lib/ui_components/`
- `lib/features/`

### Logging and Safe Execute
- `AppLogger` wraps `debugPrint` for info, warning, and error messages.
- `safeExecute` and `safeExecuteSync` wrap operations to avoid crashes and centralize error logging.

### Theme
- Implemented `AppTheme.nightOwl()` with dark Material 3 theme and high-contrast text.
- Primary accent: electric purple; secondary accent: electric blue; highlights: neon cyan.

### App Entrypoint
- Root widget is wrapped in `ProviderScope`.
- Applies Night Owl theme.
- Home is a simple initialization scaffold.

## Gotchas
- This foundation does not add Hive or initialize any data stores.
- No feature logic is implemented yet.

## Usage
Start building features by following the three-tier architecture and documenting additions under `docs/`.
