---
id: DOC-ZYRA-0416
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Founder-named task - ONE-TIME install of the latest ZYRA build on the Founder's iPhone with the old PROFILE installer (answers Codex question 2)
links: [AD-AIOS-116]
owner: ZYRA chat
---

# ONE-TIME iPHONE INSTALL — 31 OCT 2026

**Founder, 31 Oct 2026 23:57 (clickable "Yes, once" + his words):** "yes once but ensure its only once and any uneeded
file must be cleared up by black umbreall chat and he need to make a note of that".

| Step | Detail |
|---|---|
| 1 | **Once only.** This brief allows exactly one run of the existing PROFILE installer (`SOURCE/run.sh`), including the Git read calls Flutter and Xcode make by themselves during it. It does not allow any other Git use, any repeat, any upgrade (no macOS, Xcode, Flutter, CocoaPods, Homebrew or other upgrade), any password prompt or restart. If the install fails, stop — do not retry; write what failed in the task note and mark this line FAILED |
| 2 | When: at the end of the GO run, after every line that run builds. It does not wait for QUESTION or FAILED lines. Before line 44 |
| 3 | The iPhone may be connected **by cable or wirelessly** (same Wi-Fi as the Mac, already paired with this Mac in Xcode, shown by `flutter devices` as a network device). Apple needs the phone **unlocked** while the app installs and launches. If the phone is not found or stays locked, mark FAILED with the reason (the exception is not used up) |
| 4 | Keep Apple's sandbox, signing and app identity exactly as they are. Install the current committed Founder preview (Ivory) |
| 5 | **Clean-up list:** in the task note, list every file and folder the install created or changed outside normal build output (caches, ephemeral packages, logs, DerivedData, Pods), with paths and sizes, under the heading "For Fable to clear". Do **not** delete anything yourself |
| 6 | Mark question 2 in `QUESTIONS.md` as used ("exception used <date/time>") and mark queue line 72 BUILT or FAILED. After this line the exception has expired; the next install needs the repaired protected route |
