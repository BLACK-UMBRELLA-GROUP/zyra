-- OA-ZYRA-228 (Founder choice a): a multi-select answer is one scored
-- question. Average the configured lights across its selected options, then
-- add one unit to the denominator. A candidate can no longer change a
-- question's weight merely by selecting more options.

DO $migration$
DECLARE
  v_definition text;
  v_old_declaration text :=
    'v_total NUMERIC; v_max NUMERIC; v_excluded BOOLEAN;';
  v_new_declaration text :=
    'v_total NUMERIC; v_max NUMERIC; v_excluded BOOLEAN;' || chr(10) ||
    '  v_multi_total NUMERIC; v_multi_count INT;';
  v_old_array_block text := $old$
        IF jsonb_typeof(v_answer) = 'array' THEN
          FOR v_value IN SELECT jsonb_array_elements_text(v_answer) LOOP
            v_light := v_prefs_for_question ->> v_value;
            IF v_light IS NULL THEN CONTINUE; END IF;
            v_max := v_max + 1; v_total := v_total + zyra_light_weight(v_light);
          END LOOP;
        ELSE
$old$;
  v_new_array_block text := $new$
        IF jsonb_typeof(v_answer) = 'array' THEN
          v_multi_total := 0;
          v_multi_count := 0;
          FOR v_value IN SELECT jsonb_array_elements_text(v_answer) LOOP
            v_light := v_prefs_for_question ->> v_value;
            IF v_light IS NULL THEN CONTINUE; END IF;
            v_multi_total := v_multi_total + zyra_light_weight(v_light);
            v_multi_count := v_multi_count + 1;
          END LOOP;
          IF v_multi_count > 0 THEN
            v_max := v_max + 1;
            v_total := v_total + (v_multi_total / v_multi_count);
          END IF;
        ELSE
$new$;
BEGIN
  SELECT pg_get_functiondef('public.score_candidates(uuid[])'::regprocedure)
    INTO v_definition;

  IF v_definition IS NULL THEN
    RAISE EXCEPTION 'OA-ZYRA-228: score_candidates(uuid[]) not found';
  END IF;

  IF position(v_old_declaration IN v_definition) = 0 THEN
    RAISE EXCEPTION
      'OA-ZYRA-228: scorer declaration changed; refusing an unsafe rewrite';
  END IF;

  IF position(v_old_array_block IN v_definition) = 0 THEN
    RAISE EXCEPTION
      'OA-ZYRA-228: multi-select scorer block changed; refusing an unsafe rewrite';
  END IF;

  v_definition := replace(v_definition, v_old_declaration, v_new_declaration);
  v_definition := replace(v_definition, v_old_array_block, v_new_array_block);
  EXECUTE v_definition;
END
$migration$;

COMMENT ON FUNCTION public.score_candidates(uuid[]) IS
  'Caller-scoped compatibility scorer. Multi-select questions average selected-option lights and contribute one denominator unit (OA-ZYRA-228 option a).';
