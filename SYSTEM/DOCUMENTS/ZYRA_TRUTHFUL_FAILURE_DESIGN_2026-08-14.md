# Truthful Failure Handling — Design

**OA-ZYRA-225** · 14 August 2026 · design only, nothing built

Four write paths swallow database errors and let the interface report success. This is the design for fixing them, written to be built at the Mac without further decisions.

---

## The principle

> **A screen may only show a state the server has agreed to.**
> Where it can't wait, it must be able to take the state back.

That gives exactly two shapes, and every path is one or the other:

| Shape | When | Cost of being wrong |
|---|---|---|
| **Await then commit** | The action is a claim about a person's intent that others rely on | A moment of waiting |
| **Optimistic with rollback** | The action is cheap, private, and must feel instant | A card flicking back, with a reason |

The mistake to avoid is treating this as one rule. Making Browse await four network round trips per swipe would ruin the deck to fix a rare failure. Making a family answer optimistic would mean a Journey safeguard that lies.

---

## The service layer

Every one of these services currently returns `void` or a bare value and swallows its `catch`. They need a result type. One, shared:

```dart
/// The outcome of a write. `ZyraWriteResult.ok` or a failure carrying
/// something a screen can act on.
sealed class ZyraWriteResult {
  const ZyraWriteResult();
  bool get isOk => this is ZyraWriteOk;
}

class ZyraWriteOk extends ZyraWriteResult {
  const ZyraWriteOk();
}

class ZyraWriteFailed extends ZyraWriteResult {
  /// The server's own refusal code where it gave one — 'paused_limit_reached',
  /// 'not_eligible_to_continue'. Null for an unexpected error.
  final String? code;

  /// Already logged by the service. Carried for the screen's own logging,
  /// never for display — a Postgres error is not a message to a person.
  final Object error;

  const ZyraWriteFailed({required this.error, this.code});
}
```

**Why sealed rather than a bool:** the recognised refusals must stay distinguishable from unexpected errors. `suspendJourney` already rethrows two of them by name; that behaviour is correct and must survive the change. A bool would flatten "the server said no, here's why" into "something went wrong".

**Never display `error`.** Screens map `code` to copy they own. A raw database string reaching a user is its own defect.

---

## Path 1 · Save · Consider · Pass

`zyra_discovery_service.dart:318-339, 481-491` · `browse_screen.dart:1127, 1164, 1194`

**Shape: optimistic with rollback.**

Browse must stay instant — this is the app's core gesture and it happens hundreds of times a session. But today the write isn't even awaited, so a failure is invisible forever.

```
1. Apply locally, advance the deck — unchanged, still instant
2. Await the write in the background, holding the profile and the decision
3. On failure:
     · undo the AppState change for that profile
     · put the profile back in the deck at the current position,
       NOT at the end — burying it is a second silent failure
     · one SnackBar: "That didn't save. {Name} is back in your deck."
     · log
```

**The hard part is `_index`.** Restoring a profile shifts the cursor, and `_advance()` may already have moved. Re-insert at `_index` and do **not** decrement — the person is next, not current. Someone mid-swipe on the following card should not have the deck jump under their thumb.

**A failed Like is the worst case and needs naming:** it can silently prevent a match. If `recordLike` fails, the other person's Like never meets yours. The rollback must be visible, not just correct.

---

## Path 2 · Family answers

`zyra_journey_service.dart:860-872` · `journey_flow_screen.dart:2819-2826` · `wali_journey_detail_screen.dart:172-187`

**Shape: await then commit. Never optimistic.**

This is a Journey safeguard. A Seeker or Guardian believing their family response was recorded when it wasn't is the most serious of the four.

```
1. Disable the submit control, show the button's own spinner
2. Await every answer in the batch
3. All succeeded  → reload, show the submitted state
   Any failed     → stay on the form
                    · KEEP THE TYPED TEXT — losing it is a second injury
                    · name which answers didn't save
                    · offer Retry, which re-sends only the failures
```

**Batch semantics:** the answers go one at a time today, so a partial failure is possible and currently invisible. Track per-question outcomes and retry only what failed — re-sending successful answers risks duplicates depending on the constraint.

---

## Path 3 · Pause

`zyra_journey_service.dart:908-914` · `journey_flow_screen.dart:319-333` · `connections_screen.dart:1048-1075`

**Shape: await then commit.**

Today two recognised refusals rethrow and everything else is swallowed, so the sheet closes as if the Journey paused while it may still be running.

```
1. Keep the confirmation sheet open, disable its actions
2. Await
3. ok                            → close, refresh
   failed with a known code      → keep open, show that rule's own copy
                                   (paused_limit_reached already has copy)
   failed with anything else     → keep open, "That didn't go through.",
                                   Retry · Cancel
```

**Do not close the sheet on an unexpected error.** Closing is the gesture that says it worked.

---

## Path 4 · Notifications

`zyra_notification_service.dart` · `notifications_screen.dart`

**Shape: typed result, three states.**

An empty list on failure renders "All caught up — No new notifications." That copy is most misleading exactly when someone needs to retry.

```dart
sealed class ZyraFetchResult<T> { }
class ZyraFetchOk<T>     extends ZyraFetchResult<T> { final T data; }
class ZyraFetchFailed<T> extends ZyraFetchResult<T> { final Object error; }
```

| State | Renders |
|---|---|
| loading | `ZyraLoading` |
| ok, empty | "All caught up · No new notifications." — unchanged, and now true |
| ok, items | the list |
| failed | "Couldn't load your notifications." + **Retry** |

**The badge must follow.** `fetchUnreadCount` returns 0 on failure, so the tab shows no badge during an outage — the same lie in a smaller place. On failure, leave the previous count rather than clearing it.

---

## Tests come first

There are 18 tests in the app and **none** cover a failure path. That is why four of these could exist at once.

Write these before touching the services:

| Test | Asserts |
|---|---|
| Save fails | AppState is unchanged and the profile is back in the deck |
| Like fails | rollback happens and the failure is surfaced, not swallowed |
| Family answer fails | typed text survives and the submitted state is NOT shown |
| Family answer partially fails | only failed answers are retried |
| Pause fails, unknown error | sheet stays open |
| Pause fails, `paused_limit_reached` | that rule's own copy, sheet stays open |
| Notification fetch fails | error state, never "All caught up" |
| Unread count fails | previous badge is retained, not zeroed |

They're fakeable at the service boundary — no live database needed.

---

## Order of work

1. `ZyraWriteResult` and `ZyraFetchResult`
2. The eight tests, failing
3. Notifications — smallest surface, proves the pattern
4. Pause — one call site each side
5. Family answers — the most serious
6. Save / Consider / Pass — the fiddliest, because of the deck cursor
7. Verify by forcing each failure on device

Steps 3 to 6 are independently shippable. Each leaves the app whole, which is what makes stopping between them cheap.

---

## What this does not cover

Retry queues, offline write buffering, and optimistic concurrency are all out of scope. The goal here is narrow and worth stating plainly: **stop the app claiming things that didn't happen.** Making those things eventually happen anyway is a different, larger piece of work.
