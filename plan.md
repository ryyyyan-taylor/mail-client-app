# Mail Client Android App — MVP Plan

## Overview

A minimal, dark-themed Android email client for Gmail. Serverless architecture — all
processing happens on-device. Background polling with local notifications for new mail.

**Tech Stack:** Kotlin · Jetpack Compose · MVVM · Room · Retrofit · WorkManager · Koin
**AGP:** 8.9.1 (AGP 9.x incompatible with KSP/Kotlin toolchain as of project start)

**MVP Scope:** View inbox as threads, read emails, take actions (archive, delete, spam,
move, mark read/unread). No compose or reply.

---

## ✅ Section 1: Dev Environment, Project Scaffold & Build Setup

Install Android development tools on Linux, then set up the project structure and
dependencies.

### 1a: Linux Dev Environment Setup

- [ ] Install Android Studio (official IDE — includes SDK, emulator, and build tools):
  - Download from https://developer.android.com/studio
  - Extract to `/opt/android-studio` (or `~/android-studio`)
  - Run `bin/studio.sh` to launch the setup wizard
  - The wizard will install: Android SDK, SDK Platform-Tools, Emulator, and a default
    system image
- [ ] During setup wizard, accept SDK licenses and install recommended components
- [ ] Ensure KVM is available for emulator acceleration:
  - Check: `lc /dev/kvm` — if it exists, you're good
  - If missing on Arch: `sudo modprobe kvm_intel` (or `kvm_amd`) and add your user to
    the `kvm` group: `sudo usermod -aG kvm $USER` (re-login after)
- [ ] Create an Android Virtual Device (AVD) in Android Studio:
  - Tools → Device Manager → Create Device
  - Pick a Pixel device (e.g., Pixel 7)
  - Select a recent system image (API 34 / Android 14 recommended)
  - Finish — launch the emulator to verify it boots
- [ ] (Optional) Add to your shell profile for CLI access:
  ```bash
  export ANDROID_HOME="$HOME/Android/Sdk"
  export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"
  ```

### 1b: Project Scaffold

- [ ] Initialize Android project with Kotlin + Jetpack Compose template
- [ ] Configure Gradle dependencies (Compose, Room, Retrofit, WorkManager, Hilt, etc.)
- [ ] Set up base package structure:
  ```
  com.mail.client/
  ├── data/           # Repository, Room DB, API clients
  │   ├── local/      # Room entities, DAOs, database
  │   ├── remote/     # Gmail API service, Retrofit setup
  │   └── repository/ # Single source of truth
  ├── di/             # Hilt dependency injection modules
  ├── ui/             # Compose screens and components
  │   ├── theme/      # Dark theme, colors, typography
  │   ├── inbox/      # Thread list screen
  │   ├── thread/     # Thread detail / message view
  │   └── components/ # Shared UI components
  ├── worker/         # WorkManager sync & notification workers
  └── util/           # Extensions, helpers
  ```
- [ ] Create `AndroidManifest.xml` with required permissions (INTERNET, notifications)
- [ ] Verify project compiles and runs on emulator with a blank Compose activity

**Deliverable:** Android Studio + emulator running on Linux. Empty app that launches a
dark screen on the emulator.

---

## ✅ Section 2: OAuth2 Authentication with Gmail

Implement Google Sign-In and OAuth2 token management for Gmail API access.

- [ ] Register the app in Google Cloud Console, enable Gmail API
- [ ] Configure OAuth2 client ID (Android type) with SHA-1 fingerprint
- [ ] Implement Google Sign-In flow using Google Identity Services library
- [ ] Request Gmail scopes: `gmail.readonly`, `gmail.modify`, `gmail.labels`
- [ ] Store access/refresh tokens in EncryptedSharedPreferences
- [ ] Implement automatic token refresh on 401 responses (Retrofit interceptor/authenticator)
- [ ] Build a simple sign-in screen (Google Sign-In button on dark background)
- [ ] Add sign-out functionality
- [ ] Gate all app content behind authentication state

**Deliverable:** User can sign in with Google, see their email address displayed, and sign out.

---

## Section 3: Gmail API Integration & Data Layer

Build the data layer: Retrofit services, Room database, and repository pattern. Translate
the existing TypeScript API patterns (client.ts, messages.ts, threads.ts, labels.ts) into
Kotlin.

- [ ] Define Retrofit interface for Gmail API:
  - `GET users/me/threads` — list threads (supports labelIds, q, pageToken, maxResults)
  - `GET users/me/threads/{id}` — get full thread
  - `POST users/me/threads/{id}/modify` — add/remove labels
  - `POST users/me/threads/{id}/trash` — trash thread
  - `POST users/me/threads/{id}/untrash` — untrash thread
  - `GET users/me/messages/{id}` — get full message
  - `POST users/me/messages/{id}/modify` — modify message labels
  - `POST users/me/messages/{id}/trash` — trash message
  - `GET users/me/labels` — list labels
- [ ] Create Room entities:
  - `ThreadEntity` (id, snippet, historyId, labelIds, lastMessageTimestamp)
  - `MessageEntity` (id, threadId, from, to, subject, snippet, body, date, labelIds, isRead)
  - `LabelEntity` (id, name, type)
- [ ] Create Room DAOs with queries for inbox view and thread detail
- [ ] Create `MailRepository` as single source of truth (API → Room → UI)
- [ ] Implement base64url decoding for message bodies (port codec.ts logic)
- [ ] Implement email header parsing (From, To, Subject, Date extraction from Gmail payload)
- [ ] Add pagination support via pageToken for thread listing

**Deliverable:** Repository can fetch threads/messages from Gmail, cache in Room, and
expose via Flow/LiveData.

---

## ✅ Section 4: Inbox Screen (Thread List)

Build the primary screen — a list of email threads showing sender, subject, snippet,
date, and unread state.

- [x] Create `InboxViewModel` that observes threads from repository
- [x] Trigger a fresh sync from Gmail API on app launch / screen entry
- [x] Add a manual refresh button in the top app bar (sync icon)
- [x] Build thread list item composable — single-line layout: unread dot · sender
      (fixed 110dp) · subject (weighted, ellipsed) · timestamp (intrinsic width)
- [x] Implement pull-to-refresh
- [x] Implement infinite scroll / pagination (load more on scroll to bottom)
- [x] Add loading state (spinner)
- [x] Add empty state ("no messages")
- [x] Add error state (snackbar)
- [x] Style with dark theme: black background, white text, grey secondary text

**Deliverable:** Scrollable inbox showing real Gmail threads, pull-to-refresh, pagination.

---

## ✅ Section 5: Thread Detail Screen (Message View)

Build the screen that shows all messages within a thread in chronological order.

- [x] Create `ThreadDetailViewModel` — loads full thread, observes Room, marks read on open
- [x] Build message card composable:
  - Sender name + timestamp header row (tap to expand/collapse)
  - Expandable/collapsible: collapsed shows snippet, expanded shows full body
  - HTML rendering via AndroidView + WebView; plain text wrapped in <pre>
  - No sender avatars (kept minimal)
- [x] Show messages in chronological order, most recent expanded by default
- [x] Thread subject as screen title / top bar
- [x] Back navigation to inbox
- [x] Mark thread as read when opened
- [x] WebView sizing: JS scrollHeight in CSS pixels == dp (no density conversion)
- [x] Scroll fix: LazyColumn + ACTION_MOVE requestDisallowInterceptTouchEvent(false)
      so WebView doesn't steal vertical scroll gestures
- [x] Reload guard: webView.tag tracks last-loaded HTML, prevents re-render on
      every recomposition
- [x] HTML emails: white background, preserve original <style> blocks (responsive
      @media queries), strip HTML width attributes via JS to trigger mobile layouts
- [x] Plain text emails: dark background, light text
- [x] Koin ViewModel key fix: key=threadId prevents same VM reuse across threads

**Deliverable:** Tap a thread in inbox → see all messages, bodies render correctly.

---

## Section 6: Thread Actions

Add actions for managing threads: archive, delete, spam, move, and read state.

- [ ] Implement action bar or bottom action sheet with:
  - **Archive** — remove INBOX label
  - **Delete** — trash thread
  - **Spam** — add SPAM label, remove INBOX
  - **Mark unread** — add UNREAD label
  - **Move to** — show label picker, add/remove labels
- [x] Swipe gestures on inbox list items (changed from plan):
  - Swipe left → delete (with undo snackbar)
  - Swipe right → move-to-label bottom sheet (applies label, removes INBOX, with undo snackbar)
- [x] Implement optimistic updates (_hiddenIds filter in ViewModel, rollback on API failure)
- [ ] Batch actions: long-press to select multiple threads, apply action to all
- [x] Undo snackbar for destructive actions (snackbar awaits result before firing API)
- [x] Update inbox list after actions (thread disappears immediately, restored on undo)

**Deliverable:** All thread management actions work with undo support and optimistic UI.

---

## Section 7: Background Sync & Notifications

Set up periodic background polling and local notifications for new emails.

- [ ] Create `SyncWorker` (extends CoroutineWorker):
  - Fetch latest threads from Gmail API
  - Compare against Room database to detect new messages
  - Store sync state (last historyId or last check timestamp)
- [ ] Register periodic WorkManager request:
  - Default interval: 15 minutes (Android minimum for periodic work)
  - Constraints: requires network connectivity
  - Retry policy: exponential backoff
- [ ] Create notification channel ("New Mail") on app startup (Android 8+ requirement)
- [ ] Show local notifications for new emails:
  - Title: sender name
  - Body: subject line
  - Tap notification → open thread detail
  - Group notifications when multiple new emails arrive
- [ ] Add user preference for sync interval and notification toggle
- [ ] Ensure sync runs even when app is killed (WorkManager handles this)
- [ ] Battery optimization: use `setRequiresBatteryNotLow(false)` — sync is lightweight

**Deliverable:** App checks for new mail every 15 minutes and shows notifications, even
when closed.

---

## Section 8: Navigation, Settings & Polish

Wire up navigation, add settings, and polish the overall experience.

- [ ] Set up Compose Navigation:
  - Sign-in → Inbox → Thread Detail
  - Settings screen
- [ ] Settings screen:
  - Account info (email, sign-out button)
  - Sync interval preference (15m, 30m, 1h)
  - Notifications on/off
- [ ] App bar with consistent styling across screens
- [ ] Splash screen / loading state while checking auth
- [ ] Handle edge cases:
  - No network connectivity (show cached data + offline banner)
  - Token expiry during use (re-auth flow)
  - Empty inbox
- [ ] Animations: screen transitions, list item appear/disappear
- [ ] Final visual pass: ensure consistent dark theme, spacing, typography

**Deliverable:** Complete, polished MVP ready for daily use.

---

## Dependency Summary

| Library | Purpose |
|---|---|
| Jetpack Compose + Material3 | UI framework |
| Compose Navigation | Screen routing |
| Room | Local SQLite database |
| Retrofit + OkHttp + Moshi | Gmail REST API client |
| Hilt | Dependency injection |
| WorkManager | Background periodic sync |
| Google Identity Services | OAuth2 sign-in |
| EncryptedSharedPreferences | Secure token storage |
| Coil | Image loading (avatars, if needed) |

## Section Order & Dependencies

```
Section 1 (scaffold)
    ↓
Section 2 (auth)
    ↓
Section 3 (data layer)
    ↓
 ┌──┴──┐
 4      5      ← can be done in either order
 (inbox) (thread)
 └──┬──┘
    ↓
Section 6 (actions)
    ↓
Section 7 (sync & notifications)
    ↓
Section 8 (polish)
```

Sections 1–3 are sequential (each builds on the last). Sections 4–5 can be worked on
in either order once the data layer is in place. Sections 6–8 are sequential.
