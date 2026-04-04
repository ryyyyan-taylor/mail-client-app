# Session Notes — Mail Client App

This file is **not auto-loaded**. Reference it explicitly when you need history context.

---

## Android MVP Sessions

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

### 2026-03-28 (session 3)
- Real device testing via debug APK (`./gradlew assembleDebug`). SHA-1 already registered
  in Google Cloud Console for the debug keystore.
- Text size bump across the board (+1sp each role in `ui/theme/Type.kt`).
- Pill/button touch targets brought to M3 spec (48×48dp minimum).
- Back navigation fixed (`MainActivity.kt`): `BackHandler(enabled = screen is NavScreen.Thread)`
  clears `openThreadId` → returns to Inbox.

### 2026-03-29
- Notification action button: tapping "Delete" on a notification trashes the thread and
  dismisses the notification without opening the app.
  - New `NotificationActionReceiver` (`worker/NotificationActionReceiver.kt`): `BroadcastReceiver`
    + `KoinComponent`, cancels notification immediately then calls `mailRepository.trashThread()`
    via `goAsync()` + coroutine. Registered in `AndroidManifest.xml` with `exported="false"`.
  - `SyncWorker.notifyNewThread()`: added Delete `PendingIntent` (broadcast), request code
    `notificationId xor Int.MIN_VALUE` to avoid collision with tap intent.
  - New `res/drawable/ic_notification_email.xml`: white monochrome envelope vector drawable.
- Pill icon order changed to **More → Label → Delete** in both pills.
- Thread load performance: `MessageDao.replaceForThread()` wraps delete+insert in `@Transaction`.
  `ThreadDetailViewModel`: `loadFullThread` and `markRead` run in parallel via `coroutineScope`.

---

## Flutter Migration Sessions

### 2026-03-31 — Phases 1–4
- Flutter project at `flutter/`. Decisions locked: Riverpod, go_router, Android-first.
- Phase 1: pubspec.yaml deps, dark theme ported, go_router shell, iOS stubs.
  - Build env fixes (Arch): JDK dir, Gradle 8.13, desugar_jdk_libs, workmanager ^0.9.0.
- Phase 2: Drift DB (Threads/Messages/Labels), token_storage, settings_prefs, codegen.
  - `fromAddress`/`toAddress` column names (avoids Dart reserved word `from`).
- Phase 3: gmail_dtos.dart (json_serializable), gmail_api_service.dart (Dio), auth_interceptor
  (callback-based, `extra['_authRetried']` prevents infinite 401 loop), dio_provider.dart.
- Phase 4: util ports, auth_repository (google_sign_in + signInSilently), mail_repository
  (full port, 1hr label throttle, Drift Companion mappers), providers.dart, main.dart.

### 2026-03-31 — Phases 5–9
- Phase 5: SignInNotifier (AsyncNotifier, FutureOr<void> build), sign_in_screen, router splash.
- Phase 6: InboxNotifier (_sentinel pattern, _hiddenIds optimistic hide), inbox_screen
  (Dismissible swipe, LabelPickerSheet exported, _SectionPickerSheet).
- Phase 7: ThreadDetailNotifier (FamilyNotifier, parallel load, navigateBack), thread_detail_screen
  (_ThreadActionsPill vertical, _MessageCard expand/collapse, _HtmlBody WebView + JS height).
- Phase 8: SettingsNotifier (sync prefs in build), settings_sheet (Dart 3 records, Radio, Switch).
- Phase 9: sync_worker.dart (callbackDispatcher, _doSync, trashThreadStandalone),
  workmanager init in main.dart, notification deep link in router.
  - Gotcha: `registerPeriodicTask` takes `ExistingPeriodicWorkPolicy` (not `ExistingWorkPolicy`).

### 2026-04-01 — Phase 10
- SliverAppBar scroll-hiding in landscape: AppBar inside NestedScrollView left pane.
  `floating: true, snap: true`. AppBar title/actions extracted to shared helpers.
- Landscape pagination via `NotificationListener<ScrollUpdateNotification>` (depth==0 guard).
- Notification deep link for landscape: `/inbox?initialThread=<id>` vs `/thread/<id>`.

### 2026-04-01 — Phase 11
- Black splash: launch_background.xml → black, styles.xml → Theme.Black.NoTitleBar.
- Edge-to-edge insets: viewPaddingOf(context).bottom on ListView padding and pill Positioned.
- Screen transition: CustomTransitionPage on thread route (220ms fade + 4% slide).
- Flutter app feature-complete. Real-device testing begins.

---

## Real-Device Testing & Bug Fixes

### 2026-04-03
- **Auth 401 fix**: `SignInNotifier.build()` was `async` → caused immediate AsyncLoading→AsyncData
  transition → auto-navigated to inbox before sign-in. Fixed: `FutureOr<void> build() {}`.
  Added `import 'dart:async'` for FutureOr.
- **getAccessToken self-heal**: `signInSilently()` fallback when `currentUser == null` (app restart).
- **Background sync noise**: `_syncSection` only surfaces error on explicit refresh (isRefresh=true);
  background sync failures are silent.
- **WebView white flash**: `_HtmlBody` initial height changed from `1px` to `screenH` so WebView
  has a real viewport for `scrollHeight` measurement.
- **5th/6th messages not rendering**: Root cause — rich HTML emails have scrollHeight 10–25k px.
  Uncapped SizedBox height pushed later ListView items far off-screen. Fixed: cap at `screenH * 0.95`.
  Also added `AutomaticKeepAliveClientMixin` to `_MessageCardState` so expanded messages survive
  scroll-off; `gestureRecognizers` on WebViewWidget for nested scroll.
- **`markRead` blocking thread load**: `Future.wait([loadFullThread, markRead])` — markRead failure
  was aborting the whole wait. Fixed: `markRead(...).catchError((_) {})` makes it best-effort.
- **Snackbar duration**: All action snackbars set to 5s (`duration: Duration(seconds: 5)`).
- **`persist: false`** added to all snackbars to prevent them stacking.
