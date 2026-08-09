-- Wali Journey/Timeline/Messages visibility (Founder decision,
-- 2026-07-26). Builds the "Standard Wali capabilities" already
-- ratified in APP/Standards/WALI_ARCHITECTURE_CURRENT_VERSION_V5.md
-- ("View Seeker's active Journey progress", "View messages between
-- Seeker and their match", "View Timeline") — approved since 2026-07-04
-- but never built (wali_dashboard_screen.dart's own comment: "Journey/
-- Timeline visibility for a Wali isn't built yet").
--
-- Scope, per that same document's own boundary and PROFILE DECISION
-- SYSTEM/Summary.md's Timeline Access rule ("Wali is not involved at
-- the Browse/Potential Journey stage"): a Wali sees a linked Seeker's
-- match/conversation/timeline data ONLY once it has left 'potential'
-- status (i.e. an Active Journey has begun, per promote_journey_to_
-- active()). Browse-stage activity (Saves, Considers, Passes, the
-- Potential-Journey-only match list) remains OUT of scope — that is
-- the explicit "WHAT THE WALI CAN NEVER SEE: Match list / Browse
-- activity" rule, which this migration deliberately does NOT touch.
-- Widening beyond this boundary requires a separate, explicit Decision
-- Record (see SYSTEM/DECISIONS_REGISTER — DR draft pending Founder
-- review, 2026-07-26).
--
-- Mechanism: additive OR clause on each existing SELECT policy —
-- unchanged for a Seeker querying their own data; a Wali gains
-- visibility only where wali_links has an 'active' link to one of the
-- two seekers on a non-'potential' match. Existing policies are
-- DROP + CREATE'd (matching this repo's established migration style)
-- rather than ALTER POLICY, to keep the full resulting expression
-- readable in one place per table.

-- matches
DROP POLICY matches_select ON matches;
CREATE POLICY matches_select ON matches FOR SELECT
  USING (
    seeker_a_id = auth.uid() OR seeker_b_id = auth.uid()
    OR (
      status <> 'potential'
      AND EXISTS (
        SELECT 1 FROM wali_links wl
        WHERE wl.wali_id = auth.uid() AND wl.status = 'active'
          AND wl.seeker_id IN (matches.seeker_a_id, matches.seeker_b_id)
      )
    )
  );

-- conversations
DROP POLICY conversations_select ON conversations;
CREATE POLICY conversations_select ON conversations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM matches m
      WHERE m.id = conversations.match_id
        AND (
          m.seeker_a_id = auth.uid() OR m.seeker_b_id = auth.uid()
          OR (
            m.status <> 'potential'
            AND EXISTS (
              SELECT 1 FROM wali_links wl
              WHERE wl.wali_id = auth.uid() AND wl.status = 'active'
                AND wl.seeker_id IN (m.seeker_a_id, m.seeker_b_id)
            )
          )
        )
    )
  );

-- messages (read-only for Wali — no corresponding insert policy change,
-- so a Wali can view but never send into a Seeker's conversation)
DROP POLICY messages_select ON messages;
CREATE POLICY messages_select ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      JOIN matches m ON m.id = c.match_id
      WHERE c.id = messages.conversation_id
        AND (
          m.seeker_a_id = auth.uid() OR m.seeker_b_id = auth.uid()
          OR (
            m.status <> 'potential'
            AND EXISTS (
              SELECT 1 FROM wali_links wl
              WHERE wl.wali_id = auth.uid() AND wl.status = 'active'
                AND wl.seeker_id IN (m.seeker_a_id, m.seeker_b_id)
            )
          )
        )
    )
  );

-- timelines
DROP POLICY timelines_select ON timelines;
CREATE POLICY timelines_select ON timelines FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM matches m
      WHERE m.id = timelines.match_id
        AND (
          m.seeker_a_id = auth.uid() OR m.seeker_b_id = auth.uid()
          OR (
            m.status <> 'potential'
            AND EXISTS (
              SELECT 1 FROM wali_links wl
              WHERE wl.wali_id = auth.uid() AND wl.status = 'active'
                AND wl.seeker_id IN (m.seeker_a_id, m.seeker_b_id)
            )
          )
        )
    )
  );

-- timeline_milestones
DROP POLICY timeline_milestones_select ON timeline_milestones;
CREATE POLICY timeline_milestones_select ON timeline_milestones FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM timelines t
      JOIN matches m ON m.id = t.match_id
      WHERE t.id = timeline_milestones.timeline_id
        AND (
          m.seeker_a_id = auth.uid() OR m.seeker_b_id = auth.uid()
          OR (
            m.status <> 'potential'
            AND EXISTS (
              SELECT 1 FROM wali_links wl
              WHERE wl.wali_id = auth.uid() AND wl.status = 'active'
                AND wl.seeker_id IN (m.seeker_a_id, m.seeker_b_id)
            )
          )
        )
    )
  );
