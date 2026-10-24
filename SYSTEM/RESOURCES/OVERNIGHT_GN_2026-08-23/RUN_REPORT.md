# Overnight Run Report — Guardian Network first delivery

## HANDOFF

```
DOCUMENTATION: complete
APP FIRST DRAFT: incomplete
TESTS: fail (flutter analyze: FAIL after 4 fix iterations — ORIGINAL RESTORED, app untouched; zyra_check: not run)
API COST: $0.85 (~£0.67 est.)
FOUNDER REVIEW: not ready
```

Started 2026-08-23T01:00:05.161107+00:00 · finished 2026-08-23T01:09:16.146879+00:00

## Cost breakdown — per task

| Office | Agent | Task | Model | In | Out | Cost USD | ms | Result |
|---|---|---|---|---|---|---|---|---|
| Guardian Network Run | Fable | t1-fable-position | claude-sonnet-4-6 | 7477 | 2500 | $0.0599 | 64841 | ok |
| Guardian Network Run | Codex | t2-codex-challenge | gpt-4o | 12597 | 885 | $0.0403 | 11085 | ok |
| Guardian Network Run | Fable | t3-fable-agreed | claude-sonnet-4-6 | 8549 | 3000 | $0.0706 | 71007 | ok |
| Guardian Network Run | Codex | t4-codex-implement | gpt-4o | 14936 | 9000 | $0.1273 | 75769 | ok |
| Guardian Network Run | Codex | t5-codex-fix-1 | gpt-4o | 9901 | 9000 | $0.1148 | 55773 | ok |
| Guardian Network Run | Codex | t5-codex-fix-2 | gpt-4o | 10325 | 9000 | $0.1158 | 52946 | ok |
| Guardian Network Run | Codex | t5-codex-fix-3 | gpt-4o | 10469 | 9000 | $0.1162 | 62796 | ok |
| Guardian Network Run | Codex | t5-codex-fix-4 | gpt-4o | 10424 | 8998 | $0.1160 | 69725 | ok |
| Guardian Network Run | Fable | t7-fable-verify | claude-sonnet-4-6 | 16985 | 2500 | $0.0885 | 61612 | ok |
| **TOTAL** | | | | | | **$0.8495** | | ceiling $4.00 |

Costs = exact token counts × ai_comms COST_TABLE rates (estimates; provider dashboards are the meter of record). Every task is also in WORKSPACE_DATA/ai_usage/executions.json (office 'Guardian Network Run', trigger overnight-gn:*) — the AI Usage page reads that file.

## Outputs

- 00a/00b — the Fable↔Codex discussion
- 01_AGREED_RULES.md — the build contract (Founder D1-D13 ratification still open)
- 02_DRAFT_v*.dart — every iteration (final one is IN THE APP if analyze passed)
- ORIGINAL_wali_network_screen.dart — pre-run backup
- ANALYZE_pass*.txt / ZYRA_CHECK.txt — gate evidence
- 03_FABLE_VERIFY.md — final contradiction check