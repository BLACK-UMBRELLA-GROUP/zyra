#!/usr/bin/env python3
"""ZYRA code-size tracker (OA-ZYRA-316). Read-only.

Prints the Founder's clean-up table: all app code, developer/preview code, the Founder preview,
and old-app files that still mention retired features. Run from anywhere:
    python3 ZYRA/SYSTEM/tools/blueprint/code_size.py
Add a row to REPORTS/CURRENT/ZYRA_CODE_SIZE_TRACKER_CURRENT_VERSION_V1.md after each clean-up step.
"""
import os, re, glob
LIB = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'SOURCE', 'lib')
LIB = os.path.normpath(LIB)
PREVIEW = ['zyra_one_journey_*.dart', 'zyra_view_request_draft_model.dart', 'zyra_request_*.dart',
           'zyra_draft_*.dart', 'zyra_founder_launch_*.dart', 'dev_discovery_directions.dart',
           'zyra_my_zyra_focus.dart']
# LOCK15: this shared presenter is currently imported only by the two Founder hosts.
FOUNDER_ONLY_SHARED = [os.path.join(LIB, 'widgets', 'zyra_focus_dashboard.dart')]
# 'Save' (saved profiles) is not counted: the word is too common to measure honestly by search.
RETIRED = {'Pause': r'pause', 'Restart': r'restart_journey|restartJourney'}

def lines(paths): return sum(sum(1 for _ in open(p, encoding='utf-8', errors='replace')) for p in paths)
alld = [p for p in glob.glob(LIB + '/**/*.dart', recursive=True)]
dev = [p for p in alld if os.sep + 'dev' + os.sep in p or p in FOUNDER_ONLY_SHARED]
prev = sorted({p for g in PREVIEW for p in glob.glob(os.path.join(LIB, 'dev', g))}
              | {p for p in FOUNDER_ONLY_SHARED if os.path.isfile(p)})
nondev = [p for p in alld if p not in dev]
print('| What | Size |\n|---|---|')
print(f'| All app code | {lines(alld):,} lines in {len(alld)} files |')
print(f'| Developer and preview code inside it | {lines(dev):,} lines in {len(dev)} files |')
print(f'| The Founder preview (planned app) | {lines(prev):,} lines in {len(prev)} files |')
TEST = os.path.normpath(os.path.join(LIB, '..', 'test'))
tests = glob.glob(TEST + '/**/*.dart', recursive=True)
pngs = glob.glob(TEST + '/**/*.png', recursive=True)
print(f'| Test code | {lines(tests):,} lines in {len(tests)} files |')
print(f'| Test screenshots (goldens) | {len(pngs):,} images, {sum(os.path.getsize(p) for p in pngs)//(1024*1024):,} MB |')
for name, rx in RETIRED.items():
    n = sum(1 for p in nondev if re.search(rx, open(p, encoding="utf-8", errors="replace").read(), re.I))
    print(f'| Old-app files that still mention {name} | {n} |')
