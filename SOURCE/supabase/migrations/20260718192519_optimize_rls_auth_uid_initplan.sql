-- Performance advisory fix (auth_rls_initplan, WARN, surfaced by
-- get_advisors after the onboarding_answers migration). Every RLS
-- policy in the schema calls auth.uid() unwrapped, which Postgres
-- re-evaluates per row instead of once per query. Wrapping as
-- (select auth.uid()) lets the planner treat it as a stable
-- subquery, evaluated once. Same logic as every policy below,
-- purely a rewrite for query plan efficiency — no access-control
-- behaviour changes. Systemic across the original initial_schema
-- migration, not specific to any one table, so fixed in one
-- pass rather than piecemeal.

-- profiles
DROP POLICY profiles_insert ON profiles;
CREATE POLICY profiles_insert ON profiles FOR INSERT WITH CHECK (id = (select auth.uid()));

DROP POLICY profiles_select ON profiles;
CREATE POLICY profiles_select ON profiles FOR SELECT USING (id = (select auth.uid()) OR (is_active = true AND profile_complete = true));

DROP POLICY profiles_update ON profiles;
CREATE POLICY profiles_update ON profiles FOR UPDATE USING (id = (select auth.uid()));

-- subscriptions
DROP POLICY subscriptions_select ON subscriptions;
CREATE POLICY subscriptions_select ON subscriptions FOR SELECT USING (user_id = (select auth.uid()));

-- profile_photos
DROP POLICY profile_photos_delete ON profile_photos;
CREATE POLICY profile_photos_delete ON profile_photos FOR DELETE USING (user_id = (select auth.uid()));

DROP POLICY profile_photos_insert ON profile_photos;
CREATE POLICY profile_photos_insert ON profile_photos FOR INSERT WITH CHECK (user_id = (select auth.uid()));

DROP POLICY profile_photos_select ON profile_photos;
CREATE POLICY profile_photos_select ON profile_photos FOR SELECT USING (
  user_id = (select auth.uid())
  OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = profile_photos.user_id AND p.is_active AND p.profile_complete)
);

DROP POLICY profile_photos_update ON profile_photos;
CREATE POLICY profile_photos_update ON profile_photos FOR UPDATE USING (user_id = (select auth.uid()));

-- wali_links
DROP POLICY wali_links_insert ON wali_links;
CREATE POLICY wali_links_insert ON wali_links FOR INSERT WITH CHECK (seeker_id = (select auth.uid()));

DROP POLICY wali_links_select ON wali_links;
CREATE POLICY wali_links_select ON wali_links FOR SELECT USING (seeker_id = (select auth.uid()) OR wali_id = (select auth.uid()));

DROP POLICY wali_links_update ON wali_links;
CREATE POLICY wali_links_update ON wali_links FOR UPDATE USING (seeker_id = (select auth.uid()) OR wali_id = (select auth.uid()));

-- saves
DROP POLICY saves_delete ON saves;
CREATE POLICY saves_delete ON saves FOR DELETE USING (saver_id = (select auth.uid()));

DROP POLICY saves_insert ON saves;
CREATE POLICY saves_insert ON saves FOR INSERT WITH CHECK (saver_id = (select auth.uid()));

DROP POLICY saves_select ON saves;
CREATE POLICY saves_select ON saves FOR SELECT USING (saver_id = (select auth.uid()));

-- likes
DROP POLICY likes_insert ON likes;
CREATE POLICY likes_insert ON likes FOR INSERT WITH CHECK (liker_id = (select auth.uid()));

DROP POLICY likes_select ON likes;
CREATE POLICY likes_select ON likes FOR SELECT USING (liker_id = (select auth.uid()) OR liked_id = (select auth.uid()));

-- profile_unlocks
DROP POLICY profile_unlocks_select ON profile_unlocks;
CREATE POLICY profile_unlocks_select ON profile_unlocks FOR SELECT USING (unlocker_id = (select auth.uid()));

-- matches
DROP POLICY matches_select ON matches;
CREATE POLICY matches_select ON matches FOR SELECT USING (seeker_a_id = (select auth.uid()) OR seeker_b_id = (select auth.uid()));

-- conversations
DROP POLICY conversations_select ON conversations;
CREATE POLICY conversations_select ON conversations FOR SELECT USING (
  EXISTS (SELECT 1 FROM matches m WHERE m.id = conversations.match_id AND (m.seeker_a_id = (select auth.uid()) OR m.seeker_b_id = (select auth.uid())))
);

-- messages
DROP POLICY messages_insert ON messages;
CREATE POLICY messages_insert ON messages FOR INSERT WITH CHECK (
  sender_id = (select auth.uid())
  AND EXISTS (
    SELECT 1 FROM conversations c JOIN matches m ON m.id = c.match_id
    WHERE c.id = messages.conversation_id AND (m.seeker_a_id = (select auth.uid()) OR m.seeker_b_id = (select auth.uid()))
  )
);

DROP POLICY messages_select ON messages;
CREATE POLICY messages_select ON messages FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM conversations c JOIN matches m ON m.id = c.match_id
    WHERE c.id = messages.conversation_id AND (m.seeker_a_id = (select auth.uid()) OR m.seeker_b_id = (select auth.uid()))
  )
);

-- timelines
DROP POLICY timelines_select ON timelines;
CREATE POLICY timelines_select ON timelines FOR SELECT USING (
  EXISTS (SELECT 1 FROM matches m WHERE m.id = timelines.match_id AND (m.seeker_a_id = (select auth.uid()) OR m.seeker_b_id = (select auth.uid())))
);

-- timeline_milestones
DROP POLICY timeline_milestones_select ON timeline_milestones;
CREATE POLICY timeline_milestones_select ON timeline_milestones FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM timelines t JOIN matches m ON m.id = t.match_id
    WHERE t.id = timeline_milestones.timeline_id AND (m.seeker_a_id = (select auth.uid()) OR m.seeker_b_id = (select auth.uid()))
  )
);

-- wali_suggestions
DROP POLICY wali_suggestions_insert ON wali_suggestions;
CREATE POLICY wali_suggestions_insert ON wali_suggestions FOR INSERT WITH CHECK (
  wali_id = (select auth.uid())
  AND EXISTS (SELECT 1 FROM wali_links wl WHERE wl.wali_id = (select auth.uid()) AND wl.seeker_id = wali_suggestions.seeker_id AND wl.status = 'active')
);

DROP POLICY wali_suggestions_select ON wali_suggestions;
CREATE POLICY wali_suggestions_select ON wali_suggestions FOR SELECT USING (wali_id = (select auth.uid()) OR seeker_id = (select auth.uid()));

DROP POLICY wali_suggestions_update ON wali_suggestions;
CREATE POLICY wali_suggestions_update ON wali_suggestions FOR UPDATE USING (seeker_id = (select auth.uid()));

-- onboarding_answers
DROP POLICY onboarding_answers_select ON onboarding_answers;
CREATE POLICY onboarding_answers_select ON onboarding_answers FOR SELECT USING (user_id = (select auth.uid()));

DROP POLICY onboarding_answers_insert ON onboarding_answers;
CREATE POLICY onboarding_answers_insert ON onboarding_answers FOR INSERT WITH CHECK (user_id = (select auth.uid()));

DROP POLICY onboarding_answers_update ON onboarding_answers;
CREATE POLICY onboarding_answers_update ON onboarding_answers FOR UPDATE USING (user_id = (select auth.uid())) WITH CHECK (user_id = (select auth.uid()));
