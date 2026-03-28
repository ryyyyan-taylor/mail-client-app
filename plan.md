# Mail Client Android App — Plan

## What's built

A dark-themed, serverless Gmail client for Android. All processing on-device.

**Completed MVP:**
- Google Sign-In, OAuth2 token management, automatic refresh on 401
- Inbox thread list: single-line rows, pull-to-refresh, infinite scroll, optimistic UI
- Thread detail: collapsible message cards, WebView HTML rendering, plain text fallback
- Thread actions: delete, spam, move-to-label (pill in thread view; swipe gestures in inbox)
- Batch selection: long-press → multi-select → delete/spam/move with undo snackbar
- Background sync: WorkManager every 15min, per-thread notifications, no grouping
- Settings: sync interval (15m/30m/1h), notifications toggle, sign-out

---

## Future work

Add features here as they come up. No fixed order.

- [x] Landscape two-pane layout — 50/50 split, scroll-hiding top bar, content-only right pane
- [ ] Search — `GET users/me/messages?q=` with a search bar in the inbox top bar
- [x] Section / label navigation — tap the title in the inbox top bar to open a section picker
      (inbox, sent, trash, spam + user labels alphabetically). Title updates to reflect current section.
- [ ] Compose & reply — new screen; requires `gmail.send` scope
- [ ] Unread count badge on the launcher icon
- [ ] Swipe-right → archive instead of move (user preference toggle in settings)
- [ ] Attachment previews — detect `filename` in MIME parts, open with system viewer
- [ ] Multiple accounts
