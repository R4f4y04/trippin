# Home Hub + Host/Guest Flow Spec

## Overview
This spec defines the baseline user flow for Trippin before visual polish. The goal is a clear, role-driven experience:
- No active trip -> Home Hub with obvious primary actions.
- Host flow -> start trip, manage lobby, manage members/expenses.
- Guest flow -> join lobby, access trip with limited permissions.
- Trip History must be directly accessible from Home.

This document is implementation-focused and intentionally design-neutral.

## Product Goals
1. Make primary app actions obvious from first launch.
2. Move connection behavior into trip context instead of hiding it in settings.
3. Separate host vs guest responsibilities in both behavior and access.
4. Preserve Phase 3 sync constraints while improving usability.
5. Keep route and state architecture simple enough for incremental rollout.

## Scope
### In Scope
1. Home Hub when there is no active trip:
   - Start Trip as Host
   - Join Trip
   - Trip History
   - Settings
   - About
2. Dedicated Start Trip form (trip name + owner name).
3. Join Trip entry path that routes into current nearby lobby discovery flow.
4. In-trip connection management panel with clear status and actions.
5. Add-member options split: Local Member vs Connected Guest.
6. Host vs guest capability gating in trip screens.

### Out of Scope
1. Final visual system and branding polish.
2. Full join-code trip admission protocol.
3. Multi-guest fan-out support.
4. iOS P2P transport.

## User Flows
### Flow A: Launch App With No Active Trip
1. App opens to Home Hub.
2. User sees app logo/title and key actions.
3. User can choose:
   - Start Trip as Host
   - Join Trip
   - Trip History
   - Settings
   - About

### Flow B: Start Trip as Host
1. User taps Start Trip as Host.
2. Dedicated form opens.
3. User enters trip name and owner name.
4. Trip is created.
5. User lands in Host Trip screen.
6. Host can manage lobby via Connection section in trip.

### Flow C: Join Trip as Guest
1. User taps Join Trip.
2. Join screen explains how joining works.
3. User proceeds to nearby lobby discovery.
4. User selects available lobby and connects.
5. User lands in Guest Trip screen (same shell, role-limited actions).

### Flow D: Member Management In Host Trip
1. Host taps Add Member.
2. Host sees two choices:
   - Add Local Member: for people without app/device access.
   - Connect Guest: opens connection manager/lobby instructions.
3. Connected guest can be added into members list from trip context.

### Flow E: History Access
1. From Home Hub, user taps Trip History.
2. App opens trip history list.
3. User can open trip detail view.

## Role-Based Behavior Rules
### Host
1. Can add local members.
2. Can add connected guest as member.
3. Can edit/delete expenses.
4. Can finish/reopen trip.
5. Controls lobby and acts as sync authority.

### Guest
1. Can connect/join lobby.
2. Can create expenses (with sync queue fallback).
3. Cannot add members.
4. Cannot edit/delete expenses.
5. Cannot finish/reopen trip.
6. Sees connection/sync state and queue status.

## UX Structure Requirements
### Home Hub
1. Clear primary CTAs above secondary links.
2. Copy should describe host vs guest path in plain language.
3. Trip History must be one tap from Home.

### Trip Screen
1. Keep existing sections (summary, members, expenses, balances, actions).
2. Connection panel must show:
   - role
   - connection status
   - connected peer name
   - queued sync count
   - unsynced warning
3. Connection panel must provide:
   - manage connection action
   - host-only add-connected-guest action

### Add Member Interaction
1. Use an options sheet (or equivalent) rather than forcing one path.
2. Each option includes concise helper text:
   - Local Member: no app/device, host logs for them.
   - Connect Guest: invite someone to join digitally.

## Implementation Plan (Ordered)
### Phase 1: Home Hub Upgrade
1. Update empty-home experience to a clearer action hub.
2. Keep active-trip routing unchanged.
3. Ensure Trip History remains visible from Home.

### Phase 2: Start Trip Screen
1. Add dedicated start-trip form screen.
2. Route Start Trip action to this screen.
3. Keep provider/service logic unchanged where possible.

### Phase 3: Join Trip Entry
1. Add join-trip entry/instruction screen.
2. Route to existing guest discovery flow.
3. Improve empty/discovery guidance states.

### Phase 4: In-Trip Connection UX
1. Keep connection banner as canonical status surface.
2. Ensure queue count is refreshed and visible.
3. Ensure role restrictions are reflected in controls.

### Phase 5: Add Member Option Split
1. Replace direct Add Member trigger with option chooser.
2. Implement Local Member and Connect Guest paths.

### Phase 6: Validation Readiness
1. Verify role restrictions from UI and provider layers.
2. Verify host/guest route outcomes after start/join actions.
3. Verify history path from Home.

## Files To Modify/Add
### Existing Files
1. lib/features/home/home_screen.dart
2. lib/features/home/empty_home_screen.dart
3. lib/features/trip/trip_screen.dart
4. lib/features/trip/components/connection_status_banner.dart
5. lib/core/riverpod/trip_provider.dart
6. lib/core/riverpod/members_provider.dart
7. lib/core/riverpod/expenses_provider.dart
8. lib/features/history/trip_history_screen.dart
9. lib/features/history/trip_detail_screen.dart

### New Files
1. lib/features/start_trip/start_trip_screen.dart
2. lib/features/join_trip/join_trip_entry_screen.dart
3. lib/features/trip/components/add_member_options_sheet.dart

## Acceptance Criteria
1. Home Hub exposes Start Host, Join Trip, Trip History, Settings, About.
2. Start Trip form creates trip and routes correctly.
3. Join Trip path takes user to lobby discovery and then guest trip shell.
4. Host/Guest controls are correctly gated.
5. Add Member presents Local vs Connected options (host only).
6. Trip History is directly reachable from Home and detail pages work.
7. Connection/sync indicators remain visible and understandable in trip context.

## Risks and Mitigations
1. Join flow confusion if no lobbies are available:
   - Mitigation: explicit empty-state instructions and retry action.
2. Role mismatch between UI and provider behavior:
   - Mitigation: enforce restrictions in both layers.
3. Transition complexity from settings-based connection:
   - Mitigation: keep Settings entry temporarily while adding trip-context entry.

## Deferred Items (Linked)
See centralized backlog for postponed scope:
- docs/DEFERRED_BACKLOG.md

Deferred items relevant to this spec:
1. Full join-code based admission protocol.
2. Multi-guest support.
3. iOS transport.
4. Advanced retry/backoff beyond reconnect-triggered flush.
5. Phase 4 settlement workflow and export refinements.
