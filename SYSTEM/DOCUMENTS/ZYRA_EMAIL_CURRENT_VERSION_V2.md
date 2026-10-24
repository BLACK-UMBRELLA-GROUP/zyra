# ZYRA — Email Architecture

**Version:** V2
**Status:** CURRENT_VERSION
**Date:** 2026-08-22 (V1 archived same day: blackumbrella@ added, AD-AIOS-103)
**Owner:** Founder
**Built by:** Fable (Founder directive "ZYRA Email Alias Setup", 2026-08-22)
**Related:** ACCESS_AND_ACCOUNTS_REGISTER (group SYSTEM), OA-AIOS-348

---

## 1. The model

One paid Google Workspace user. Nine free aliases. Everything lands in one
inbox, pre-sorted by label. No second licence, no Groups, no forwarding
chains — the cleanest configuration Workspace supports at this size.

| Fact | Value |
|---|---|
| Paid user (the only one) | `admin@zyraconnect.app` |
| Workspace plan | Business Starter, 1 licence |
| Aliases | 9, free (limit is 30 per user) |
| Where alias mail lands | admin@'s inbox, labelled by recipient |
| Sending identity | admin@ by default (aliases can be enabled as "send as" later, free, Gmail Settings → Accounts) |

**Standing rule:** `admin@zyraconnect.app` is the *owner identity*. It is not
published anywhere a purpose alias would do. Outsiders learn the alias; the
real mailbox stays quiet.

---

## 2. The alias table

| Alias | Purpose | Gmail label | Published where (intent) |
|---|---|---|---|
| `dev@zyraconnect.app` | Development identity for services (GitHub, Supabase, registrars, CI) | **Dev** | Service signups only — never public pages |
| `hello@zyraconnect.app` | General/public contact | **General** | Website, socials |
| `support@zyraconnect.app` | User support | **Support** | App, website support page |
| `finance@zyraconnect.app` | Invoices, billing, receipts | **Finance** (existing label, shared with the accounting flow) | Suppliers, billing forms |
| `legal@zyraconnect.app` | Legal correspondence | **Legal** | Terms, contracts |
| `privacy@zyraconnect.app` | Privacy/data requests (GDPR) | **Privacy** | Privacy policy |
| `security@zyraconnect.app` | Vulnerability reports, security contact | **Security** | security.txt, disclosure page |
| `careers@zyraconnect.app` | Hiring | **Careers** | Job posts |
| `blackumbrella@zyraconnect.app` | **Interim Black Umbrella identity** — BUG-side service signups until BUG has its own domain (AD-AIOS-103) | **Black Umbrella** | Service signups only — never public |

Labels Dev, General, Support, Legal, Privacy, Security, Careers, and
Black Umbrella were created 2026-08-22 (colour-coded). Finance already existed (accounting flow,
sublabels Receipts/Logged) and is reused — no duplicate.

---

## 3. Routing (how the sorting works)

Nine Gmail filters, one per alias, each of the form:

```
Matches:  deliveredto:<alias>@zyraconnect.app
Do this:  Apply label "<Label>"
```

`deliveredto:` keys on which address *received* the message (To, Cc or Bcc),
which is exactly the Founder's rule: **the recipient alias determines the
label.** Filters do nothing else — mail stays in the inbox, nothing is
archived, nothing auto-replies, nothing forwards.

---

## 4. Verification (2026-08-22)

| Check | Result |
|---|---|
| Alias save | "Alternative email addresses updated" — all 8 listed on the user |
| Test mail to each alias | **9/9 "Delivered to Gmail mailbox"** in Google Admin → Email Log Search, ~0.7s each, zero bounces |
| Filters installed | All 9 visible in Gmail → Settings → Filters |
| Label applied end-to-end | Self-sent tests can't prove this (Gmail merges mail you send to yourself into Sent and skips filters). Proven with an external-sender test — see below. |
| **External-sender proof** | **CONFIRMED 2026-08-22 15:16Z** — Founder sent from an outside Gmail address to `support@`; it arrived in the inbox with the **Support** label auto-applied by the filter. |

All 9 filters are textually identical except for the alias string, so the one
external proof covers the pattern; delivery itself was verified per-alias
(8/8 in the Email Log Search).

---

## 5. dev@ as the development identity — migration rules

The *intent* is that services (GitHub, Supabase, Cloudflare, registrar, CI)
eventually use `dev@zyraconnect.app` as their login/contact so development
accounts stop depending on personal addresses.

**Founder's standing constraint (verbatim intent):** review each account
individually before changing ownership or login details. **Do not blindly
migrate critical accounts.**

So, explicitly:

- **Nothing was migrated on 2026-08-22.** The alias merely exists and works.
- Each future migration is its own reviewed step: check recovery methods,
  2FA, billing contacts, and lockout risk *before* switching, one service at
  a time, each filed in the Access & Accounts register.
- New signups from now on may use `dev@` directly — that requires no
  migration and no review.
- Note: `dev@` is an alias, not a separate identity. Anything signed up with
  it is ultimately controlled by admin@'s password/passkeys. That is the
  point (one set of credentials to protect) — but it means admin@'s security
  posture carries every service riding on dev@.

---

## 5b. blackumbrella@ — the interim Black Umbrella identity

Black Umbrella and ZYRA are two separate companies and must remain
separable (Founder, 2026-08-22; tax: ZYRA will pay BUG fees). Until BUG
has its own domain and email, `blackumbrella@zyraconnect.app` is the
**interim BUG identity**: any BUG-side service signup uses it, so the two
companies' account streams never blur even on one domain. At BUG
incorporation + own domain, services on blackumbrella@ re-point one
reviewed account at a time (same discipline as dev@, AD-AIOS-102 §4).
Full model: AD-AIOS-103.

## 6. Later (deliberately not built now)

| Step | Trigger |
|---|---|
| Convert an alias to a Google Group / shared inbox | (a) The day anyone besides the Founder needs to read that stream (first hire, support volume); (b) a Google surface that refuses aliases — e.g. the OAuth consent screen's "User support email" accepts only real users or Groups (AD-AIOS-102) |
| "Send as" alias identities in Gmail | First time the Founder wants replies to come *from* support@/hello@ instead of admin@ |
| Per-label notification rules | Volume makes the single inbox noisy |

Groups are free; converting an alias later is: remove alias → create group
with same address → add members. No mail is lost either way (the address
keeps resolving to the same domain). **One mechanical step at conversion:**
group-delivered mail does not reliably carry `Delivered-To: <alias>`, so
update that alias's Gmail filter to match `to:(<alias>@zyraconnect.app)`
as well — otherwise the label silently stops applying (AD-AIOS-102).

---

*Single-current-version model: this file is the source of truth for ZYRA
email architecture. Supersedes nothing (first version).*
