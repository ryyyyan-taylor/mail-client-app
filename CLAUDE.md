# CLAUDE.md — Mail Client App

This file provides context for Claude Code sessions on this project. Read it at the
start of every session. Update it at the end of every session (see instructions below).

---

## Project Summary

A Gmail-only Android email client. Dark-themed, serverless (no backend), periodic
background polling for new mail. MVP is complete and feature work continues in `plan.md`.

**Package:** `com.mail.client`
**Working directory:** `/home/rt/Code/mail-client-app/android`
**Plan:** `plan.md` in the repo root

---

## Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Language | Kotlin 2.2.21 | |
| UI | Jetpack Compose + Material3 | Always-dark theme, no dynamic color |
| DI | Koin 4.2.0 | Switched from Hilt — AGP 9.x incompatible |
| Database | Room 2.7.0 | KSP codegen |
| Network | Retrofit 2.11.0 + OkHttp 4.12.0 + Moshi 1.15.1 | KotlinJsonAdapterFactory (reflection) |
| Auth | Google Sign-In (GoogleSignIn + GoogleAuthUtil) | EncryptedSharedPreferences for tokens |
| Background | WorkManager 2.10.0 | Periodic sync, UPDATE policy for interval changes |
| Build | AGP 8.9.1 | **Do not upgrade** — AGP 9.x breaks KSP/Koin |

**KSP version:** `2.2.21-2.0.5` — must match Kotlin version exactly.

---

## Critical Build Constraints

- **AGP must stay at 8.9.1.** AGP 9.x removed APIs that Koin's Gradle plugin and KSP
  depend on. If Android Studio prompts an upgrade, decline.
- **Do not add Hilt.** It is incompatible with AGP 9.x as of this project's start.
- **JVM target:** Both `compileOptions` (Java 17) and `kotlin { compilerOptions }` must
  agree. Use `JvmTarget.JVM_17`.
- **Emulator:** Use API 34 Google Play image. API 37 crashes on Google Sign-In.

---

## Architecture

```
com.mail.client/
├── data/
│   ├── local/          # Room: Entities, DAOs, MailDatabase, SettingsPrefs
│   ├── remote/         # Retrofit: GmailApiService, DTOs, AuthInterceptor, RetrofitProvider
│   └── repository/     # MailRepository (single source of truth), AuthRepository
├── di/                 # AppModule (Koin)
├── ui/
│   ├── theme/          # Color.kt, Theme.kt, Type.kt
│   ├── auth/           # SignInViewModel, SignInScreen
│   ├── inbox/          # InboxViewModel, InboxScreen
│   ├── thread/         # ThreadDetailViewModel, ThreadDetailScreen
│   └── settings/       # SettingsViewModel, SettingsSheet
├── util/               # EmailParser, TimeFormatter
└── worker/             # SyncWorker
```

**Navigation:** `sealed class NavScreen` with `mutableStateOf` in `MainActivity`. No
Compose Navigation — the current approach is sufficient for the screen count.

---

## Dark Theme Colours

| Name | Hex | Usage |
|---|---|---|
| Black | `#000000` | App background, list rows |
| SurfaceDark | `#111111` | Cards, elevated surfaces |
| SurfaceVariant | `#1A1A1A` | Selected row background |
| Divider | `#2A2A2A` | Row dividers |
| TextPrimary | `#E8E8E8` | Main text |
| TextSecondary | `#888888` | Timestamps, secondary labels |
| TextDisabled | `#555555` | Snippets, placeholders |
| Accent | `#7A9BB5` | Links, progress indicators, buttons |
| UnreadDot | `#9BBCD4` | Unread indicator dot in inbox |
| Danger | `#BB4A4A` | Destructive actions |

---

## Key Implementation Notes

### WebView (ThreadDetailScreen)
- CSS pixels from `scrollHeight` == dp when viewport is `width=device-width`.
  **Do not divide by density.** Use `cssPixels.dp` directly.
- HTML emails: white background, preserve `<style>` blocks from original `<head>`
  (they contain `@media` responsive rules), strip HTML `width` attributes via JS.
- Plain text: dark background (`#000`), light text.
- Scroll fix: touch listener resets `requestDisallowInterceptTouchEvent(false)` on
  `ACTION_MOVE` so LazyColumn reclaims vertical scroll from the WebView.
- Reload guard: `webView.tag` stores last-loaded HTML; skip `loadDataWithBaseURL`
  if unchanged, prevents reload loop on recomposition.
- Koin ViewModels with parameters: always pass `key = threadId` to `koinViewModel()`
  to prevent the same instance being reused across different threads.

### Gmail API
- Inbox sync uses `format=metadata` (fast, no body).
- Opening a thread uses `format=full` (full message bodies).
- Labels stored as comma-separated strings in Room (e.g. `"INBOX,UNREAD"`).
- Token refresh: `AuthInterceptor` catches 401, invalidates token, retries once.
- `syncLabels()` is throttled to once per hour (in-memory timestamp guard in `MailRepository`).

### Inbox
- Single-line rows: unread dot · sender (fixed 110dp) · subject (weighted, ellipsed) · timestamp.
- Swipe left → delete (undo snackbar). Swipe right → move-to-label sheet.
- Long-press → batch selection mode. `BackHandler` exits it.
- Optimistic hide: `_hiddenIds: MutableStateFlow<Set<String>>` filtered in `observeInbox()`;
  rolled back on API failure or undo.

### Thread actions
- Bottom-right vertical pill: Move, Delete, MoreVert (Spam, Mark read/unread).
- Pill hidden via `AnimatedVisibility` while thread is loading.
- Actions that remove the thread from inbox set `navigateBack = true` in state,
  triggering `onBack()` via `LaunchedEffect`.

### Settings
- `SettingsPrefs` wraps `SharedPreferences` — sync interval + notifications enabled.
- `MailClientApp.scheduleSyncWorker()` reads interval from prefs on each start;
  uses `ExistingPeriodicWorkPolicy.UPDATE` so changes apply at the next run.
- `SyncWorker` checks `authRepository.isSignedIn()` before running, and
  `settingsPrefs.notificationsEnabled` before firing notifications.

---

## Session Notes

### 2026-03-28
- MVP complete. All 8 sections shipped.
- Settings (SettingsSheet + SettingsViewModel), splash screen, SyncWorker auth/pref
  guards, syncLabels throttle, visual bug fixes (CircularProgressIndicator modifier,
  SelectionPill padding, ThreadActionsPill AnimatedVisibility).
- Moved Settings out of top bar into MoreVert overflow; removed redundant refresh icon
  (pull-to-refresh covers it).

### 2026-03-28 (session 2)
- Landscape two-pane layout: persistent 50/50 split with scroll-hiding top bar.
  - `LocalConfiguration.current.orientation` detection in both `InboxScreen` and `MainActivity`.
  - `TopAppBarDefaults.enterAlwaysScrollBehavior()` + `nestedScroll` in landscape only.
  - `InboxListContent` private composable extracted so list renders in both orientations.
  - Right pane: `key(selectedThreadId) { ThreadDetailScreen(contentOnly=true) }` or
    "select a thread" placeholder.
  - `contentOnly: Boolean = false` param on `ThreadDetailScreen` — skips Scaffold/TopAppBar,
    renders `Box(Black)` with SnackbarHost at BottomStart + action pill at BottomEnd.
  - `initialSelectedThreadId: String?` param on `InboxScreen` + `LaunchedEffect` sync
    so notification taps route correctly in landscape without going through `NavScreen.Thread`.
  - `MainActivity`: `openThreadId != null && !isLandscape` guards `NavScreen.Thread`;
    landscape passes `initialSelectedThreadId = openThreadId` to `InboxScreen` instead.
- Section/label navigation: tap inbox title → bottom sheet (system sections + user labels).
  - Fixed filter bug: `it.type != "system"` (was `== "user"`, dropped blank-type labels).
  - Fixed scroll bug: SectionPickerSheet uses `LazyColumn` (was `Column`).
  - Fixed Moshi crash: `LabelDto.name: String?` (was non-nullable, threw on labels
    without `name` field, silently swallowed, stale cache used).
  - Fixed throttle: `syncLabels(force=true)` called via `refreshLabels()` when picker opens.
- Dark splash screen: `themes.xml` switched from `Theme.Material.Light.NoActionBar` to
  `Theme.Material.NoActionBar` with `windowBackground/statusBarColor/navigationBarColor = #000`.
  Eliminates white flash before Compose renders.
- Next: real device testing, then iterate on features from plan.md.

### 2026-03-28 (session 3)
- Real device testing via debug APK (`./gradlew assembleDebug`). SHA-1 already registered
  in Google Cloud Console for the debug keystore.
- Text size bump across the board (+1sp each role in `ui/theme/Type.kt`):
  - bodyLarge 15→16sp, bodyMedium 13→14sp, bodySmall 12→13sp, titleMedium 15→16sp, labelSmall 11→12sp
  - Inbox row hardcoded sizes also bumped: sender/subject 13→14sp, timestamp 12→13sp (`InboxScreen.kt`).
- Pill/button touch targets brought to M3 spec (48×48dp minimum):
  - `ThreadDetailScreen.kt` `PillIconButton`: 40→48dp, icon 18→20dp.
  - `InboxScreen.kt` `PillIconButton` (selection pill): icon 18→20dp (was already 48dp).
- Back navigation fixed (`MainActivity.kt`): `BackHandler(enabled = screen is NavScreen.Thread)`
  clears `openThreadId` → returns to Inbox. Back from Inbox exits app. Landscape unaffected
  (NavScreen.Thread is never set in landscape).
- Next: continue real device testing, then pick next feature from plan.md backlog.

### 2026-03-29
- Notification action button: tapping "Delete" on a notification trashes the thread and
  dismisses the notification without opening the app.
  - New `NotificationActionReceiver` (`worker/NotificationActionReceiver.kt`): `BroadcastReceiver`
    + `KoinComponent`, cancels notification immediately then calls `mailRepository.trashThread()`
    via `goAsync()` + coroutine.
  - Registered in `AndroidManifest.xml` with `exported="false"`.
  - `SyncWorker.notifyNewThread()`: added Delete `PendingIntent` (broadcast), request code
    `notificationId xor Int.MIN_VALUE` to avoid collision with tap intent.
  - New `res/drawable/ic_notification_email.xml`: white monochrome envelope vector drawable,
    replaces `android.R.drawable.ic_dialog_email` as the notification small icon.
- Pill icon order changed to **More → Label → Delete** in both pills (trash at trailing edge).
  - `InboxScreen.kt` (selection pill, horizontal): More Box moved before Label, Delete stays last.
  - `ThreadDetailScreen.kt` (actions pill, vertical): More Box moved to top, Label + divider
    inserted between More and Delete, Delete stays at bottom.
- Thread load performance fixes:
  - `MessageDao.replaceForThread()`: new `@Transaction` method wraps `deleteForThread` +
    `insertAll` atomically. Room's Flow no longer emits an intermediate empty list, eliminating
    the spinner flash on revisit.
  - `MailRepository.loadFullThread()`: uses `replaceForThread` instead of separate delete+insert.
  - `ThreadDetailViewModel`: `loadFullThread` and `markRead` now run in parallel via
    `coroutineScope { async { } + async { } }`, saving one full API round-trip off load time.

---

## How to Update This File

At the end of every session, append a new entry under **Session Notes** with:
- Date
- What was completed or changed (be specific — file names, bugs fixed, decisions made)
- Any new constraints or gotchas discovered
- What comes next

Also update `plan.md` (tick off completed items, add new feature ideas as they come up).

Update global memory files in `/home/rt/.claude/projects/-home-rt-Code-mail-client-app/memory/`
if anything changes about the user's preferences, project goals, or key decisions.
