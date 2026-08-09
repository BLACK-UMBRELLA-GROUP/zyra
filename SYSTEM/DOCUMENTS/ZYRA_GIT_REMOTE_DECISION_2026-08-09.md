# GIT REMOTE — WHAT IT COSTS, WHAT IT EXPOSES, AND ONE DECISION FOR YOU

2026-08-09. Written to be read on a phone. Everything measured, not estimated.

---

## 1. First, a thing I found while measuring

**Your repository is 380MB, and 377MB of it is test photos.**

`SOURCE/supabase/dev_test_photos/` — 101 PNGs, 5–8MB each, of stock
portraits used to seed test profiles.

They are **already in git history**, committed on or before 26 July. All
101 are in `HEAD`. Your `.git` folder is 377.86 MiB and those photos are
essentially all of it. The rest of the project — every line of Dart, every
migration, every governance document, fourteen years of decisions — is
about **3MB**.

Two consequences:

- Adding them to `.gitignore` now would achieve **nothing**. They are in
  history. Every clone downloads them forever.
- This is the **cheapest moment it will ever be** to change that. There is
  exactly one commit in history and no remote, so nobody has a clone.
  After the first push, removing them means rewriting published history.

**It is not urgent.** 380MB pushes fine (see §3). But you should decide
knowingly rather than discover it in six months.

---

## 2. What goes in the remote

The git repository root is the whole **ZYRA** folder, not just `SOURCE`.
So a remote carries all of this:

| Folder | Size | What it is |
|---|---|---|
| `SOURCE/` | 670M on disk, ~380M tracked | The app, migrations, test photos |
| `SYSTEM/` | 2.4M | Decisions register, OA register, audits, invariants, handovers |
| `APP/` | 840K | UX specifications |
| `BUSINESS/` | 268K | Business plan, competitor research, website copy |
| `REPORTS/`, `ARCHIVE/` | 280K | Reports and superseded documents |

**Be clear-eyed about `SYSTEM/`.** It contains
`ZYRA_CONTRADICTION_AUDIT_2026-08-08.md` — a catalogue of security holes
in a live application, four of which are **still open** — plus your
Article 9 data-handling design and the guardian trust model.

That is an argument for a **private** repo with two-factor authentication.
It is *not* an argument for leaving those documents unversioned: you have
already been bitten by exactly that (audit finding 5.1, two decisions
registers with disjoint content and nothing saying which governs).
Unversioned governance is how that happened.

**Your API keys are safe either way** — the `PRIVATE — API KEYS` folder is
not inside the repository, and `supabase_config.dart` and
`oauth_config.dart` are correctly ignored. Verified today.

---

## 3. Does 380MB actually fit?

Yes, comfortably. GitHub's current published limits:

| Limit | Value | You |
|---|---|---|
| Individual file | recommended 1MB, **enforced at 100MB** | largest is 7.7MB ✅ |
| Repository on-disk | recommended max **10GB** | 380MB ✅ |
| Single push | **enforced at 2GB** | first push ~380MB ✅ |

The first push takes a few minutes on home broadband. Everything after
that is a few kilobytes.

---

## 4. The three real options

### A · Private repo on a hosting service — GitHub, GitLab or Bitbucket

Offsite. Survives fire, theft, drive failure and a stolen laptop. Gives
you a web view of history, and a place to put issues later.
GitHub's free plan includes unlimited private repositories.

Cost: your governance documents and security audit sit on someone else's
infrastructure, protected by your password and 2FA.

### B · A bare repo on an external drive

    git init --bare /Volumes/<drive>/zyra.git
    git remote add backup /Volumes/<drive>/zyra.git
    git push backup main

No third party, no account, no upload, instant. Protects against every
software-side disaster — bad merges, `rm -rf`, a corrupted working tree.

Cost: it is in the same building as the Mac. Fire and theft take both.

### C · Both

B for the fast local safety net, A for the offsite copy. Git supports any
number of remotes; pushing to two is one extra command. This is what most
people should do and almost nobody does.

---

## 5. My recommendation

**C, done in the order B then A.**

The external drive takes two minutes and removes the sharpest risk
immediately — a mistake at the keyboard. Do it in the same Terminal
session as the commit.

Then a private GitHub repo when you have ten minutes, because a local
backup and the original living on the same desk is not a backup, it is
two copies of the same accident.

**On the test photos: leave them.** 380MB is well inside every limit and
rewriting history to save disk you are not short of is a poor trade. But
add `SOURCE/supabase/dev_test_photos/` to `.gitignore` so it does not keep
growing, and if the folder ever doubles, revisit it then.

---

## 6. What I need from you

One answer: **A, B, or C** — and if A or C, **which host**.

Then I write the second paste-once command, so the commit and the remote
happen in the same trip to the Mac.

I cannot do this part myself. It needs your account, your drive, and your
Terminal.

---

## 7. What this does not solve

A remote protects the repository. It does not protect:

- **The Supabase database.** 149 profiles and every migration live only in
  Supabase's hosted Postgres. Check what your plan's backup retention
  actually is — that is a separate job and arguably more urgent than this
  one, because there is no local copy at all.
- **The 84+ live-only migrations.** The database is ahead of the repo.
  `supabase db pull` is still outstanding.

Sources: [GitHub repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits)
