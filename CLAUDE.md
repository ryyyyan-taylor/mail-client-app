# CLAUDE.md — Mail Client App

This file provides context for Claude Code sessions on this project. Read it at the
start of every session. Update it at the end of every session (see instructions below).

---

## Project Summary

A Gmail-only Android email client. Dark-themed, serverless (no backend), periodic
polling for new mail. MVP scope: inbox, thread view, actions (archive/delete/spam/move/
mark read). No compose or reply.

**Package:** `com.mail.client`
**Working directory:** `/home/rt/Code/mail-client-app/android`
**Plan:** `plan.md` in the repo root — sections track progress with ✅

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
| Background | WorkManager 2.10.0 | Section 7 — not yet implemented |
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
│   ├── local/          # Room: Entities, DAOs, MailDatabase
│   ├── remote/         # Retrofit: GmailApiService, DTOs, AuthInterceptor, RetrofitProvider
│   └── repository/     # MailRepository (single source of truth), AuthRepository
├── di/                 # AppModule (Koin)
├── ui/
│   ├── theme/          # Color.kt, Theme.kt, Type.kt
│   ├── auth/           # SignInViewModel, SignInScreen
│   ├── inbox/          # InboxViewModel, InboxScreen (ThreadListItem)
│   └── thread/         # ThreadDetailViewModel, ThreadDetailScreen (MessageCard, HtmlBody)
├── util/               # EmailParser, TimeFormatter
└── worker/             # (Section 7 — not yet built)
```

**Navigation:** Currently simple `var openThreadId` state in `MainActivity`. Full
Compose Navigation wired in Section 8.

---

## Dark Theme Colours

| Name | Hex | Usage |
|---|---|---|
| Black | `#000000` | App background, list rows |
| SurfaceDark | `#111111` | Cards, elevated surfaces |
| SurfaceVariant | `#1A1A1A` | |
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

### Inbox layout
- Single-line rows: unread dot · sender (fixed 110dp) · subject (weighted, ellipsed
  before the date) · timestamp (intrinsic width).

---

## Session Notes

### 2026-03-27
- Completed Section 4: InboxViewModel, InboxScreen, single-line ThreadListItem.
- Completed Section 5: ThreadDetailViewModel, ThreadDetailScreen with collapsible
  MessageCard and WebView-based HtmlBody.
- Fixed WebView height bug (CSS px ≠ physical px — do not use density conversion).
- Fixed scroll conflict (LazyColumn + WebView touch interception).
- Fixed ViewModel reuse bug (added `key = threadId` to koinViewModel).
- Fixed WebView reload loop (webView.tag guard in AndroidView update block).
- HTML emails: white background; preserve email's own `<style>` blocks for responsive
  @media queries; JS strips HTML `width` attrs to trigger mobile layouts.
- Next: Section 6 (thread actions — swipe gestures, archive/delete/spam/move).

---

## How to Update This File

At the end of every session, append a new entry under **Session Notes** with:
- Date
- What was completed or changed (be specific — file names, bugs fixed, decisions made)
- Any new constraints or gotchas discovered
- What comes next

Also update `plan.md` to mark completed items with `✅` or `[x]`.

Update global memory files in `/home/rt/.claude/projects/-home-rt-Code-mail-client-app/memory/`
if anything changes about the user's preferences, project goals, or key decisions.
