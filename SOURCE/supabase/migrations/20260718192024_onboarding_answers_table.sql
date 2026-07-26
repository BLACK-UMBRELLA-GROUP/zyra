-- Chapter 3/4 onboarding answers (DR-ZYRA-082, PROPOSED — not yet
-- ratified by Founder). Not part of ZYRA_DATABASE_SCHEMA_CURRENT_
-- VERSION_V1.md's approved 13 tables; fills a genuine gap where that
-- document never specifies where Chapter 3 (Your Values) and
-- Chapter 4 (Your Preferences) answers are persisted. One row per
-- user, JSONB keyed by question ID — mirrors the already-approved
-- timeline_milestones.metadata JSONB pattern rather than 174 narrow
-- per-question rows, since questions/options are code-defined
-- constants and no matching engine yet needs to query individual
-- answers relationally.

CREATE TABLE onboarding_answers (
  user_id                UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  ch3_answers            JSONB NOT NULL DEFAULT '{}'::jsonb,
  ch4_preferences        JSONB NOT NULL DEFAULT '{}'::jsonb,
  ch4_hard_requirements  JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER onboarding_answers_updated_at
  BEFORE UPDATE ON onboarding_answers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE onboarding_answers ENABLE ROW LEVEL SECURITY;

-- Own row only — same pattern as saves/likes per schema doc §5.
CREATE POLICY onboarding_answers_select ON onboarding_answers
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY onboarding_answers_insert ON onboarding_answers
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY onboarding_answers_update ON onboarding_answers
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
