# OA-ZYRA-281 Phase 2 reversible patch evidence

This evidence covers the 14 authorised source, test, and staged-migration
files listed in `036_CODEX-FABLE_2026-08-30_OA-ZYRA-281_PHASE_2_COMPLETION.md`.
It does not include the governance handover, completion report, or binary
candidate screenshots.

Run from `SOURCE/` without git:

```sh
patch -E -p1 < ../SYSTEM/RESOURCES/PATCHES/OA-ZYRA-281_PHASE_2/reverse.patch
```

`-E` removes the two new files after their reverse hunks make them empty. The
2026-08-30 proof restored all 12 existing files to their recorded pre-edit
SHA-256 hashes and restored both new-file states to absent: 14/14 passed.
The restored tree then passed `flutter analyze --no-pub` and the full
667/667 pre-patch test suite.

Restore Phase 2 with:

```sh
patch -p1 < ../SYSTEM/RESOURCES/PATCHES/OA-ZYRA-281_PHASE_2/forward.patch
```

The forward proof restored every recorded post-edit SHA-256 hash: 14/14
passed. The completion report records the final post-patch test, analyzer,
static, fixture, and remote non-application evidence.

Evidence hashes:

- `forward.patch`: `d055a1a98053ff2f22c1a1b212ed5c7912f9822e7a1469cca5ac23320592c16d`
- `reverse.patch`: `1c295ac8e7e88789f51a7725e5b786802aa3c4d018f95994a50fe7b76f615e2c`
