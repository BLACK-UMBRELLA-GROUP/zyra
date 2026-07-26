-- ZYRA — Initial Schema Migration
-- Source: SYSTEM/DOCUMENTS/ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md
-- (Status: Approved — Awaiting Supabase Implementation, Source OA: OA-103)
--
-- Table definitions (§3) and index recommendations (§6) below are
-- transcribed verbatim from that document. The Row Level Security
-- section (§5) only describes policies in prose — this file turns that
-- into real CREATE POLICY statements, which is new work, not a direct
-- transcription. Six tables have explicit policies in §5 (profiles,
-- saves, likes, matches, messages, wali_links); this migration also
-- adds RLS to the seven tables §5 doesn't individually cover
-- (subscriptions, profile_photos, wali_suggestions, profile_unlocks,
-- conversations, timelines, timeline_milestones), following the same
-- "own data only" spirit. Flagged inline wherever a judgment call was
-- made that isn't a direct spec transcription, per this build's
-- existing discipline (see DR-ZYRA-079/080/081) — recommend a Founder/
-- Lead Architect pass over the POLICY comments below before this is
-- treated as final, same as those decision records.
--
-- Run this in Supabase Dashboard > SQL Editor after project creation
-- (OA-101), in one paste, top to bottom.

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

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY profiles_select ON profiles FOR SELECT
  USING (id = auth.uid() OR (is_active = TRUE AND profile_complete = TRUE));

CREATE POLICY profiles_insert ON profiles FOR INSERT
  WITH CHECK (id = auth.uid());

CREATE POLICY profiles_update ON profiles FOR UPDATE
  USING (id = auth.uid());


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

CREATE UNIQUE INDEX subscriptions_active_user
  ON subscriptions(user_id)
  WHERE status = 'active';

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Not in §5's explicit table — extending the "own data" pattern.
-- Real purchases will be written by a server-side webhook (App Store/
-- Play Store receipt validation), not directly by the client, so no
-- INSERT/UPDATE policy for the authenticated role is granted here.
CREATE POLICY subscriptions_select ON subscriptions FOR SELECT
  USING (user_id = auth.uid());


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

CREATE UNIQUE INDEX profile_photos_primary
  ON profile_photos(user_id)
  WHERE is_primary = TRUE;

ALTER TABLE profile_photos ENABLE ROW LEVEL SECURITY;

-- Not in §5's explicit table. Read is intentionally broader than "own
-- rows only" (unlike saves/likes) because photos need to be visible to
-- other members browsing an active, complete profile — mirrors the
-- profiles_select policy above rather than a strict own-rows rule.
CREATE POLICY profile_photos_select ON profile_photos FOR SELECT
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = profile_photos.user_id AND p.is_active AND p.profile_complete
    )
  );

CREATE POLICY profile_photos_insert ON profile_photos FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY profile_photos_update ON profile_photos FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY profile_photos_delete ON profile_photos FOR DELETE
  USING (user_id = auth.uid());


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

ALTER TABLE wali_links ENABLE ROW LEVEL SECURITY;

-- §5: Read — rows where seeker_id or wali_id = auth.uid().
CREATE POLICY wali_links_select ON wali_links FOR SELECT
  USING (seeker_id = auth.uid() OR wali_id = auth.uid());

-- §5: Write — seeker_id = auth.uid() for creation. This covers Path 1/2
-- (Seeker invites Wali). Path 3 (Wali starts first, DR-ZYRA-081) has the
-- Wali generating the invite instead — that direction isn't covered by
-- §5's one-line policy description, so it's deliberately left out of
-- this migration rather than guessed at; a Wali-initiated insert path
-- (or a SECURITY DEFINER function both directions call) needs Founder/
-- Lead Architect confirmation before being added.
CREATE POLICY wali_links_insert ON wali_links FOR INSERT
  WITH CHECK (seeker_id = auth.uid());

CREATE POLICY wali_links_update ON wali_links FOR UPDATE
  USING (seeker_id = auth.uid() OR wali_id = auth.uid());


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

ALTER TABLE saves ENABLE ROW LEVEL SECURITY;

-- §5: Read/Write — own rows (saver_id = auth.uid()) only. Saves are
-- private per PROFILE DECISION SYSTEM/Summary.md — the saved_id user
-- must never be able to read who saved them, even for Mutual Save
-- Detection (that's computed server-side / via a SECURITY DEFINER
-- function, not by the ZYRA One client directly querying other users'
-- save rows).
CREATE POLICY saves_select ON saves FOR SELECT
  USING (saver_id = auth.uid());

CREATE POLICY saves_insert ON saves FOR INSERT
  WITH CHECK (saver_id = auth.uid());

CREATE POLICY saves_delete ON saves FOR DELETE
  USING (saver_id = auth.uid());


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

ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- §5 says "Read: Own rows only" for likes, but read literally (liker_id
-- = auth.uid() only) that would break Incoming Potentials — a ZYRA One
-- Seeker must be able to see rows where THEY are liked_id, not just
-- rows where they are liker_id. Interpreting "own rows" as "rows you're
-- involved in" (either side) rather than the narrower "rows you
-- created", since the narrower reading contradicts a named, documented
-- feature (MATCH_UX_SPEC / ZYRA_PRODUCT_SPEC §Incoming Potentials).
-- Flagging this interpretation for confirmation rather than silently
-- picking one.
CREATE POLICY likes_select ON likes FOR SELECT
  USING (liker_id = auth.uid() OR liked_id = auth.uid());

-- Write — own rows only: you can only create a like where you are the
-- liker (unambiguous, matches §5 exactly for the write side).
CREATE POLICY likes_insert ON likes FOR INSERT
  WITH CHECK (liker_id = auth.uid());


-- ============================================================
-- PROFILE UNLOCKS
-- Paid and automatic unlock records
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

ALTER TABLE profile_unlocks ENABLE ROW LEVEL SECURITY;

-- Not in §5's explicit table. Read-only for the unlocker; writes happen
-- via a server-side function once payment (paid_*) or a match event
-- (automatic_match) is confirmed — not a direct client insert, since
-- unlock_type must be trustworthy.
CREATE POLICY profile_unlocks_select ON profile_unlocks FOR SELECT
  USING (unlocker_id = auth.uid());


-- ============================================================
-- MATCHES
-- Created only on mutual like between two Seekers
-- ============================================================
CREATE TABLE matches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seeker_a_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  seeker_b_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active', 'paused', 'ended')),
  ended_at        TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (seeker_a_id < seeker_b_id),
  UNIQUE (seeker_a_id, seeker_b_id)
);

CREATE UNIQUE INDEX matches_seeker_a_active
  ON matches(seeker_a_id)
  WHERE status = 'active';

CREATE UNIQUE INDEX matches_seeker_b_active
  ON matches(seeker_b_id)
  WHERE status = 'active';

ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

-- §5: Read — rows where seeker_a_id or seeker_b_id = auth.uid().
CREATE POLICY matches_select ON matches FOR SELECT
  USING (seeker_a_id = auth.uid() OR seeker_b_id = auth.uid());

-- §5: Write — "Application service role only." Deliberately no INSERT/
-- UPDATE policy for the authenticated role: a match must only be
-- created by a trusted server-side path (e.g. a SECURITY DEFINER
-- Postgres function triggered when a mutual like is detected, enforcing
-- the seeker_a_id < seeker_b_id ordering and the one-active-match
-- constraint), never directly by a client insert. That function is not
-- yet written — needed before Browse's Like action can create real
-- matches against this schema.


-- ============================================================
-- CONVERSATIONS
-- One conversation per match, auto-created on match creation
-- ============================================================
CREATE TABLE conversations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id        UUID NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active', 'paused', 'closed')),
  closed_at       TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Not in §5's explicit table. Mirrors the matches_select scope: a user
-- may read a conversation only if they're one of the two Seekers on its
-- match. No client write policy — created by the same server-side path
-- that creates the match ("auto-created on match creation" per schema
-- comment above), not inserted directly.
CREATE POLICY conversations_select ON conversations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM matches m
      WHERE m.id = conversations.match_id
        AND (m.seeker_a_id = auth.uid() OR m.seeker_b_id = auth.uid())
    )
  );


-- ============================================================
-- MESSAGES
-- Individual messages within a conversation
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

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- §5: Read — conversation_id belongs to a match the user is part of.
CREATE POLICY messages_select ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      JOIN matches m ON m.id = c.match_id
      WHERE c.id = messages.conversation_id
        AND (m.seeker_a_id = auth.uid() OR m.seeker_b_id = auth.uid())
    )
  );

-- §5: Write — sender_id = auth.uid(). Also checks conversation
-- membership (§5's line only names sender_id, but without a membership
-- check any authenticated user could insert a message into someone
-- else's conversation by guessing a conversation_id — added as a
-- necessary tightening, not a spec deviation).
CREATE POLICY messages_insert ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM conversations c
      JOIN matches m ON m.id = c.match_id
      WHERE c.id = messages.conversation_id
        AND (m.seeker_a_id = auth.uid() OR m.seeker_b_id = auth.uid())
    )
  );


-- ============================================================
-- TIMELINES
-- One timeline per match, auto-created on match creation
-- ============================================================
CREATE TABLE timelines (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id        UUID NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE timelines ENABLE ROW LEVEL SECURITY;

CREATE POLICY timelines_select ON timelines FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM matches m
      WHERE m.id = timelines.match_id
        AND (m.seeker_a_id = auth.uid() OR m.seeker_b_id = auth.uid())
    )
  );


-- ============================================================
-- TIMELINE MILESTONES
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

ALTER TABLE timeline_milestones ENABLE ROW LEVEL SECURITY;

CREATE POLICY timeline_milestones_select ON timeline_milestones FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM timelines t
      JOIN matches m ON m.id = t.match_id
      WHERE t.id = timeline_milestones.timeline_id
        AND (m.seeker_a_id = auth.uid() OR m.seeker_b_id = auth.uid())
    )
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

ALTER TABLE wali_suggestions ENABLE ROW LEVEL SECURITY;

CREATE POLICY wali_suggestions_select ON wali_suggestions FOR SELECT
  USING (wali_id = auth.uid() OR seeker_id = auth.uid());

CREATE POLICY wali_suggestions_insert ON wali_suggestions FOR INSERT
  WITH CHECK (
    wali_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM wali_links wl
      WHERE wl.wali_id = auth.uid() AND wl.seeker_id = wali_suggestions.seeker_id AND wl.status = 'active'
    )
  );

CREATE POLICY wali_suggestions_update ON wali_suggestions FOR UPDATE
  USING (seeker_id = auth.uid());


-- ============================================================
-- INDEX RECOMMENDATIONS (§6, verbatim)
-- ============================================================

CREATE INDEX profiles_browse
  ON profiles(gender, is_active, profile_complete)
  WHERE is_active = TRUE AND profile_complete = TRUE;

CREATE INDEX saves_mutual
  ON saves(saved_id, saver_id);

CREATE INDEX likes_liker   ON likes(liker_id, created_at DESC);
CREATE INDEX likes_liked   ON likes(liked_id, created_at DESC);

CREATE INDEX wali_links_seeker ON wali_links(seeker_id) WHERE status = 'active';
CREATE INDEX wali_links_wali   ON wali_links(wali_id)   WHERE status = 'active';

CREATE INDEX subscriptions_user ON subscriptions(user_id) WHERE status = 'active';
