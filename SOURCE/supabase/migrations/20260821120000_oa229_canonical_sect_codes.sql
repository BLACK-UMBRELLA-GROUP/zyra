-- OA-ZYRA-229: one canonical sect code from client write to scorer read.
--
-- RULE FOR THE NEXT SECT VALUE
-- ----------------------------
-- UI copy is a label. Storage and preference-map keys are always the same
-- lowercase hyphenated code produced by zyra_sect_code(). Add a label to the
-- client picker; never add a title-case bridge to score_candidates().

CREATE OR REPLACE FUNCTION public.zyra_sect_code(p_label text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SET search_path TO 'public'
AS $function$
  SELECT COALESCE(
    NULLIF(
      regexp_replace(
        regexp_replace(lower(btrim(COALESCE(p_label, ''))), '[^a-z0-9]+', '-', 'g'),
        '(^-+|-+$)',
        '',
        'g'
      ),
      ''
    ),
    'other'
  );
$function$;

REVOKE ALL ON FUNCTION public.zyra_sect_code(text) FROM PUBLIC, anon, authenticated;

ALTER TABLE public.seeker_details
  DROP CONSTRAINT IF EXISTS seeker_details_sect_known;

-- Migrate the old `other` sentinel to the person's actual canonical code.
-- sect_other remains the display label, so no user-facing spelling is lost.
UPDATE public.seeker_details
SET sect = public.zyra_sect_code(
  CASE
    WHEN sect = 'other' AND NULLIF(btrim(sect_other), '') IS NOT NULL
      THEN sect_other
    ELSE sect
  END
)
WHERE sect IS NOT NULL;

-- The same conversion must reach both preference-map keys and per-option
-- hard requirements. Doing only the own answer would recreate the bridge.
UPDATE public.seeker_details AS details
SET preferences = jsonb_set(
  jsonb_set(
    details.preferences,
    '{sect,matrix}',
    COALESCE((
      SELECT jsonb_object_agg(
        public.zyra_sect_code(entry.key),
        entry.value
        ORDER BY public.zyra_sect_code(entry.key)
      )
      FROM jsonb_each(
        COALESCE(details.preferences->'sect'->'matrix', '{}'::jsonb)
      ) AS entry
    ), '{}'::jsonb),
    true
  ),
  '{sect,hard_requirement}',
  COALESCE((
    SELECT jsonb_agg(
      public.zyra_sect_code(item.value)
      ORDER BY public.zyra_sect_code(item.value)
    )
    FROM jsonb_array_elements_text(
      COALESCE(details.preferences->'sect'->'hard_requirement', '[]'::jsonb)
    ) AS item(value)
  ), '[]'::jsonb),
  true
)
WHERE details.preferences ? 'sect';

ALTER TABLE public.seeker_details
  ADD CONSTRAINT seeker_details_sect_known
  CHECK (sect IS NULL OR sect ~ '^[a-z0-9]+(-[a-z0-9]+)*$');

COMMENT ON COLUMN public.seeker_details.sect IS
  'Canonical lowercase hyphenated code. The same code keys preferences->sect->matrix and hard_requirement; display labels never enter scoring.';

-- Keep the newest live scorer byte-for-byte except for the two title-case
-- bridges. pg_get_functiondef makes this migration safe across the applied
-- OA-193 restatement whose full body is recorded remotely rather than copied
-- into this repository.
DO $migration$
DECLARE
  v_definition text;
  v_bridge_count integer;
BEGIN
  SELECT pg_get_functiondef('public.score_candidates(uuid[])'::regprocedure)
  INTO v_definition;

  v_bridge_count := (
    length(v_definition) - length(replace(v_definition, 'initcap(v_cand.sect)', ''))
  ) / length('initcap(v_cand.sect)');

  IF v_bridge_count <> 2 THEN
    RAISE EXCEPTION
      'OA-ZYRA-229 expected two initcap(v_cand.sect) bridges, found %; inspect scorer before migrating',
      v_bridge_count;
  END IF;

  EXECUTE replace(v_definition, 'initcap(v_cand.sect)', 'v_cand.sect');
END
$migration$;

