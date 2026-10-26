#!/usr/bin/env python3
"""
generate_screen_map.py - ZYRA blueprint part 1 (OA-ZYRA-309).

Reads SOURCE/lib and lists every screen class with: where it lives, who it is for (from its
folder), which screens open it and which it opens, the buttons/taps it offers (label + what the
tap does when that is readable), sheets and dialogs it shows, and whether it has loading, empty and
error states. Writes PRODUCT/BLUEPRINT/ZYRA_SCREEN_INVENTORY_GENERATED.md.

It is a static reading of the code, not a run of the app: dynamic navigation or labels built at
run time can be missed. The plain-words screen map (PRODUCT/BLUEPRINT/ZYRA_SCREEN_MAP_...) is
written from this inventory and the code, and says where it relies on reading rather than
running. No AI runs git; this tool never calls git.

Usage: python3 generate_screen_map.py "<ZYRA root>"
"""
import os, re, sys, collections

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
LIB = os.path.join(ROOT, 'SOURCE', 'lib')
OUT = os.path.join(ROOT, 'PRODUCT', 'BLUEPRINT', 'ZYRA_SCREEN_INVENTORY_GENERATED.md')

CLASS = re.compile(r'class\s+([A-Z]\w*)\s+extends\s+(StatefulWidget|StatelessWidget|ConsumerWidget|ConsumerStatefulWidget)')
SCREENISH = re.compile(r'(Screen|Page|Shell|Flow|Gate|Workspace|Dashboard|Wizard|Hub)$')
ROUTE = re.compile(r'(?:PageRoute|PageRouteBuilder)\b[\s\S]{0,260}?(?:=>|return)\s*(?:const\s+)?([A-Z]\w+)\s*\(')
SHEET = re.compile(r'(showModalBottomSheet|showDialog|showGeneralDialog|showCupertinoModalPopup)\b[\s\S]{0,300}?(?:=>|return)\s*(?:const\s+)?([A-Z]\w+)\s*\(')
BTN = re.compile(r'\b(ElevatedButton|TextButton|OutlinedButton|FilledButton|IconButton|FloatingActionButton|ListTile|InkWell|GestureDetector|CupertinoButton|Zyra\w*(?:Button|Pill|Action|Tile|Row|Card)\w*|_\w*(?:Button|Pill|Action|Tile|Row)\w*)(?:\.\w+)?\s*\(')
TEXT = re.compile(r"""(?:Text|title|label|text|semanticLabel|tooltip)\s*[:(]\s*(?:const\s+)?(?:Text\(\s*)?['"]([^'"\n$]{2,60})['"]""")
TAP = re.compile(r'\b(onPressed|onTap|onLongPress)\s*:\s*([^,\n]{1,90})')
FOLDER_AUDIENCE = {'wali': 'Guardian', 'mentor': 'Guardian', 'home': 'Seeker', 'browse': 'Seeker', 'journey': 'Seeker',
                   'matches': 'Seeker', 'onboarding': 'New member', 'auth': 'Everyone (signed out)', 'subscription': 'Seeker',
                   'profile': 'Seeker', 'settings': 'Everyone signed in', 'chat': 'Seeker and Guardian', 'connections': 'Seeker',
                   'notifications': 'Everyone signed in', 'dev': 'Developer only', '': 'Everyone'}

def strip_comments(t):
    t = re.sub(r'/\*[\s\S]*?\*/', '', t)
    return re.sub(r'(?m)//.*$', '', t)

files = {}
for d, _, fs in os.walk(LIB):
    for f in fs:
        if f.endswith('.dart'):
            p = os.path.join(d, f); files[os.path.relpath(p, LIB)] = strip_comments(open(p, encoding='utf-8', errors='replace').read())

classes = {}  # name -> file
for rel, t in files.items():
    for m in CLASS.finditer(t):
        classes[m.group(1)] = rel
screens = {}
for rel in sorted(files):
    if not rel.startswith('screens/'):
        continue
    names = [m.group(1) for m in CLASS.finditer(files[rel]) if not m.group(1).startswith('_')]
    keep = [n for n in names if SCREENISH.search(n)] or names[:1]
    for n in keep:
        screens[n] = rel

opens = collections.defaultdict(set); opened_by = collections.defaultdict(set); sheets = collections.defaultdict(set)
def owner_screen(rel):
    names = [n for n, f in screens.items() if f == rel]
    return names or [os.path.basename(rel)[:-5]]
CALL = re.compile(r'(?:=>|return|builder:\s*\(_\)\s*=>)\s*(?:const\s+)?([A-Z]\w+)\s*\(')
for rel, t in files.items():
    src = owner_screen(rel)
    own = {m.group(1) for m in CLASS.finditer(t)}
    for m in re.finditer(r'(?<![\w.])([A-Z]\w+)\s*\(', t):
        tgt = m.group(1)
        if tgt in screens and tgt != src[0] and not re.search(r'(class|extends|State<)\s*$', t[max(0, m.start() - 12):m.start()]):
            for s_ in src[:1]:
                opens[s_].add(tgt); opened_by[tgt].add(s_)
    for m in SHEET.finditer(t):
        for s_ in src[:1]:
            sheets[s_].add(m.group(2))

def buttons(t):
    out = []
    for m in BTN.finditer(t):
        win = t[m.end(): m.end() + 700]
        lab = TEXT.search(win); tap = TAP.search(win)
        label = lab.group(1).strip() if lab else ''
        action = ''
        if tap:
            action = tap.group(2).strip().rstrip(')')
            tgt = re.search(r'(?:=>|return)\s*(?:const\s+)?([A-Z]\w+(?:Screen|Page|Sheet|Dialog|Flow|Shell))\s*\(', win[:400]) or re.search(r'\b(show\w+Sheet|show\w*Dialog)\b', win[:300])
            if tgt: action = 'opens ' + tgt.group(1)
            elif action.startswith('('): action = 'inline action'
        if label or action:
            out.append((label or '(icon / no text)', action or '—', m.group(1)))
    seen = set(); res = []
    for b in out:
        if b[:2] not in seen:
            seen.add(b[:2]); res.append(b)
    return res

def states(t):
    s = []
    if re.search(r'CircularProgressIndicator|ZyraLoading|Loading\w*\(|isLoading|_loading', t): s.append('loading')
    if re.search(r'[Ee]mpty\w*\(|isEmpty\s*\)?\s*\?|_empty|EmptyState', t): s.append('empty')
    if re.search(r'[Ee]rror\w*\(|catch\s*\(|hasError|_error|ErrorState|FullScreenError', t): s.append('error')
    return ', '.join(s) or '—'

by_area = collections.defaultdict(list)
for n, f in sorted(screens.items(), key=lambda x: (x[1], x[0])):
    if n.startswith('_'): continue
    parts = f.split('/')
    area = parts[1] if len(parts) > 2 else ''
    by_area[area].append(n)

out = ['---', 'id: DOC-ZYRA-0279', 'type: REPORT', 'status: CURRENT', 'feature: PRODUCT BLUEPRINT',
       'purpose: Generated inventory of the OLD member app screens (SOURCE/lib/screens) - who it is for, what opens it, what it opens, its buttons and states. Used for the clean-up; the planned app is DOC-ZYRA-0286',
       'links: [OA-ZYRA-309, DOC-ZYRA-0278]', 'owner: Fable', '---', '',
       '# ZYRA SCREEN INVENTORY (GENERATED)', '',
       'Generated by `SYSTEM/tools/blueprint/generate_screen_map.py` from `SOURCE/lib`. **Do not edit by hand** —',
       're-run the tool. Static reading of the code: navigation or labels built at run time can be missed.', '',
       f'Screens: **{sum(len(v) for v in by_area.values())}** in {len(by_area)} areas · Dart files read: {len(files)}', '']
for area in sorted(by_area, key=lambda a: (a == 'dev', a)):
    out += [f'## {area or "top level"} — {FOLDER_AUDIENCE.get(area, "Everyone")}', '']
    for n in by_area[area]:
        f = screens[n]; t = files[f]
        out += [f'### {n}', '', f'- File: `SOURCE/lib/{f}`',
                f'- Opened from: {", ".join(sorted(opened_by.get(n, []))) or "— (start screen, shell tab or opened dynamically)"}',
                f'- Opens: {", ".join(sorted(x for x in opens.get(n, []) if x != n)) or "—"}',
                f'- Sheets and dialogs: {", ".join(sorted(sheets.get(n, []))) or "—"}',
                f'- States in the code: {states(t)}']
        bs = buttons(t)
        if bs:
            out += ['', '| Button / tap | What it does | Widget |', '|---|---|---|']
            out += [f'| {b[0].replace("|", "/")} | {b[1].replace("|", "/")[:80]} | {b[2]} |' for b in bs[:40]]
            if len(bs) > 40: out.append(f'| … {len(bs) - 40} more | | |')
        out.append('')
os.makedirs(os.path.dirname(OUT), exist_ok=True)
open(OUT, 'w', encoding='utf-8').write('\n'.join(out) + '\n')
print(f'{OUT}: {sum(len(v) for v in by_area.values())} screens, {os.path.getsize(OUT)//1024} KB')
