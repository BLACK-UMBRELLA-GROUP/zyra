# OA-ZYRA-198 — chronology archive

**Status:** BYTE-PRESERVED EVIDENCE / EXCLUDED FROM ACTIVE LOCAL REPLAY  
**Archived:** 2026-09-11  
**Authority:** Founder's explicit approval in Codex chat, under AD-AIOS-109  
**Outstanding action:** OA-ZYRA-198

This governed evidence directory preserves two exact SQL files added to the
active migration directory during the 2026-08-21 file-presence
reconciliation. The files record statements present in production migration
history, but they are not part of the repository's intended zero-state replay
chronology.

The SQL content, filenames, byte lengths, modes and original modification
times are preserved. Their identities, original paths and active successor
sequence are pinned in `manifest.json`. They live under
`SYSTEM/RESOURCES`, outside `SOURCE/supabase/migrations/`, so the
Supabase CLI cannot discover them as active migration input.

This archive does not delete or rewrite production history, approve a
production migration, or assert that the complete migration chain replays.
OA-ZYRA-198 remains open until a genuine zero-state replay succeeds.

Restore either file to active replay only under a new Founder-approved
chronology decision. Copy its exact bytes back, verify SHA-256 against the
manifest, and repeat the full isolated replay. Do not edit archived evidence
in place.
