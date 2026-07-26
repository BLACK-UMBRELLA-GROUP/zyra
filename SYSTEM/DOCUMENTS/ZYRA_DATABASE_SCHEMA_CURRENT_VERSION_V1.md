# ZYRA Database Schema
**Document:** ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1
**Version:** V1
**Status:** Approved — Awaiting Supabase Implementation
**Owner:** Lead Architect
**Date:** 2026-06-27
**Source OA:** OA-103
**Governing:** ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V2, ZYRA_ARCHITECTURE_CURRENT_VERSION_V2

---

## Contents

1. Design Principles
2. Schema Overview
3. Table Definitions (SQL)
4. Constraint Notes
5. Row Level Security Notes
6. Index Recommendations
7. Implementation Order
8. Version History

---

## 1. Design Principles

**Soft deletes everywhere.** No hard deletes on matches, conversations, messages, or user data. Every ended relationship is an archived record. This is a product spec requirement and must be enforced at schema level.

**DB-level business rule enforcement.** The one-active-match-per-Seeker and one-active-conversation-per-Seeker limits must be enforced as database constraints (partial unique indexes), not only in application logic.

**Supabase Auth integration.** The `profiles` table extends Supabase's `auth.users` table using the user's UUID as the primary key. All other tables foreign-key to `profiles.id`.

**Roles on profiles, not on auth.** Role (`seeker`, `wali`, `admin`) is stored on the `profiles` table. Admin role is manually assigned at database level — not self-assignable.

**Ordered match pairs.** To prevent duplicate match records, seeker pairs are always stored with the lesser UUID first (`seeker_a_id < seeker_b_id`). A check constraint enforces this.

---

## 2. Schema Overview

| Table | Purpose |
|-------|---------|
| profiles | All users — Seekers, Walis, Admins |
| subscriptions | Current plan for each user |
| profile_photos | Profile photos stored in Supabase Storage |
| wali_links | Seeker ↔ Wali guardian relationships |
| saves | Profile saves (private by default) |
| likes | Profile likes (interest signals) |
| profile_unlocks | Paid and automatic unlock records |
| matches | Confirmed mutual matches |
| conversations | One conversation per match |
| messages | Individual messages within a conversation |
| timelines | Journey timeline per match |
| timeline_milestones | Events recorded on the timeline |
| wali_suggestions | Extended Wali suggestions to their Seeker |

---

## 3. Table Definitions (SQL)

```sql
-- ============================================================
-- PROFILES
-- Extends Supabase auth.users
-- ============================================================
CREATE TABLE profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role            TEXT NOT NULL DEFAULT 'seeker'
                  CHECK (role IN ('seeker', 'wali', 'admin')),
  first_name      TEXT NOT NULL,
  date_of_birth   DATE NOT NULL,
  gender          TEXT NOT NULL CHECK (gender IN ('male', 'female')),
  location_text   TEXT,
  bio             TEXT,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  profile_complete BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at on change
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- SUBSCRIPTIONS
-- Current active plan per user
-- ============================================================
CREATE TABLE subscriptions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  plan_type       TEXT NOT NULL
                  CHECK (plan_type IN (
                    'seeker_basic', 'seeker_premium',
                    'wali_basic', 'wali_premium'
                  )),
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active', 'expired', 'cancelled')),
  billing_period  TEXT CHECK (billing_period IN ('monthly', 'annual')),
  started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- One active subscription per user
CREATE UNIQUE INDEX subscriptions_active_user
  ON subscriptions(user_id)
  WHERE status = 'active';


-- ============================================================
-- PROFILE PHOTOS
-- References Supabase Storage paths
-- ============================================================
CREATE TABLE profile_photos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  storage_path    TEXT NOT NULL,
  is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
  display_order   INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- One primary photo per user
CREATE UNIQUE INDEX profile_photos_primary
  ON profile_photos(user_id)
  WHERE is_primary = TRUE;


-- ============================================================
-- WALI LINKS
-- Guardian relationships between Seekers and Walis
-- ============================================================
CREATE TABLE wali_links (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seeker_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  wali_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'active', 'removed')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (seeker_id, wali_id)
);


-- ============================================================
-- SAVES
-- Private profile saves — interest without commitment
-- ============================================================
CREATE TABLE saves (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  saver_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  saved_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (saver_id, saved_id),
  CHECK (saver_id <> saved_id)
);


-- ============================================================
-- LIKES
-- Interest signals — mutual likes create a match
-- ============================================================
CREATE TABLE likes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  liker_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  liked_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (liker_id, liked_id),
  CHECK (liker_id <> liked_id)
);


-- ============================================================
-- PROFILE UNLOCKS
-- Paid unlocks and automatic match unlocks
-- One unlock record per unlocker/unlocked pair regardless of method
-- ============================================================
CREATE TABLE profile_unlocks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unlocker_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  unlocked_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  unlock_type     TEXT NOT NULL
                  CHECK (unlock_type IN (
                    'paid_single', 'paid_plus_single',
                    'paid_bundle', 'paid_plus_bundle',
                    'automatic_match'
                  )),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (unlocker_id, unlocked_id),
  CHECK (unlocker_id <> unlocked_id)
);


-- ============================================================
-- MATCHES
-- Created only on mutual like between two Seekers
-- Soft delete: status = 'ended', ended_at set
-- ============================================================
CREATE TABLE matches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seeker_a_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  seeker_b_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active', 'paused', 'ended')),
  ended_at        TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Always store lesser UUID first to prevent duplicate pairs
  CHECK (seeker_a_id < seeker_b_id),
  UNIQUE (seeker_a_id, seeker_b_id)
);

-- DB-level enforcement: one active match per Seeker
-- Partial unique index on seeker_a — only one row where status='active' per seeker_a
CREATE UNIQUE INDEX matches_seeker_a_active
  ON matches(seeker_a_id)
  WHERE status = 'active';

CREATE UNIQUE INDEX matches_seeker_b_active
  ON matches(seeker_b_id)
  WHERE status = 'active';


-- ============================================================
-- CONVERSATIONS
-- One conversation per match, auto-created on match creation
-- Soft delete: status = 'closed', closed_at set
-- ============================================================
CREATE TABLE conversations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id        UUID NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active', 'paused', 'closed')),
  closed_at       TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- MESSAGES
-- Individual messages within a conversation
-- Soft delete: deleted_at set, content optionally redacted
-- ============================================================
CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content         TEXT NOT NULL,
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX messages_conversation_created
  ON messages(conversation_id, created_at DESC);


-- ============================================================
-- TIMELINES
-- One timeline per match, auto-created on match creation
-- ============================================================
CREATE TABLE timelines (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id        UUID NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- TIMELINE MILESTONES
-- Journey events — current approved: Match, Conversation,
-- Family Stage, Meeting, Nikah (future stages TBD)
-- ============================================================
CREATE TABLE timeline_milestones (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timeline_id     UUID NOT NULL REFERENCES timelines(id) ON DELETE CASCADE,
  milestone_type  TEXT NOT NULL
                  CHECK (milestone_type IN (
                    'match_created',
                    'conversation_started',
                    'family_stage',
                    'meeting',
                    'nikah'
                  )),
  occurred_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata        JSONB
);


-- ============================================================
-- WALI SUGGESTIONS
-- Extended Wali: suggest profiles to their linked Seeker
-- ============================================================
CREATE TABLE wali_suggestions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wali_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  seeker_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  suggested_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at    TIMESTAMPTZ,
  UNIQUE (wali_id, seeker_id, suggested_id)
);
```

---

## 4. Constraint Notes

**One active match per Seeker** — enforced via two partial unique indexes on `matches(seeker_a_id) WHERE status = 'active'` and `matches(seeker_b_id) WHERE status = 'active'`. A Seeker appears as either seeker_a or seeker_b. Both indexes together guarantee no Seeker has two active matches simultaneously.

**Ordered match pairs** — `CHECK (seeker_a_id < seeker_b_id)` ensures the lesser UUID is always in seeker_a. The application must sort the two Seeker IDs before inserting. This prevents both `(A, B)` and `(B, A)` existing as separate rows.

**One conversation per match** — `UNIQUE (match_id)` on conversations. A match can only ever have one conversation record.

**Soft deletes on matches** — `ended_at` is set on End Match. Status becomes `'ended'`. Rows are never deleted. This satisfies the product spec requirement that ended matches are archived, not deleted.

**Self-like/save prevention** — `CHECK (liker_id <> liked_id)` and `CHECK (saver_id <> saved_id)` at schema level.

---

## 5. Row Level Security Notes

Supabase RLS must be enabled on all tables. Key policies:

| Table | Read policy | Write policy |
|-------|-------------|-------------|
| profiles | Own row always. Others: is_active = true and profile_complete = true | Own row only |
| saves | Own rows (saver_id = auth.uid()) only | Own rows only — saves are private |
| likes | Own rows only | Own rows only |
| matches | Rows where seeker_a_id or seeker_b_id = auth.uid() | Application service role only |
| messages | conversation_id belongs to a match the user is part of | sender_id = auth.uid() |
| wali_links | Rows where seeker_id or wali_id = auth.uid() | seeker_id = auth.uid() for creation |

Admin role bypasses RLS via service role key. Developer access in-app verifies `role = 'admin'` on the profiles table.

---

## 6. Index Recommendations

```sql
-- Profile discovery (browse page)
CREATE INDEX profiles_browse
  ON profiles(gender, is_active, profile_complete)
  WHERE is_active = TRUE AND profile_complete = TRUE;

-- Mutual save detection (Premium feature)
CREATE INDEX saves_mutual
  ON saves(saved_id, saver_id);

-- Outgoing/incoming potentials
CREATE INDEX likes_liker   ON likes(liker_id, created_at DESC);
CREATE INDEX likes_liked   ON likes(liked_id, created_at DESC);

-- Wali link lookups
CREATE INDEX wali_links_seeker ON wali_links(seeker_id) WHERE status = 'active';
CREATE INDEX wali_links_wali   ON wali_links(wali_id)   WHERE status = 'active';

-- Subscription check (plan gate)
CREATE INDEX subscriptions_user ON subscriptions(user_id) WHERE status = 'active';
```

---

## 7. Implementation Order

These tables must be created in this order due to foreign key dependencies:

1. `profiles`
2. `subscriptions`
3. `profile_photos`
4. `wali_links`
5. `saves`
6. `likes`
7. `profile_unlocks`
8. `matches`
9. `conversations`
10. `messages`
11. `timelines`
12. `timeline_milestones`
13. `wali_suggestions`

---

## 8. Version History

| Version | Date | Change |
|---------|------|--------|
| V1 | 2026-06-27 | Initial schema design. 13 tables covering MVP through Conversation Stage per ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V2. Source OA: OA-103. |

