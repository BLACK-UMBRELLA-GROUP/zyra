#!/usr/bin/env python3
"""Planned-app screen map generator (OA-ZYRA-309 / DR-ZYRA-274). Read-only.

Reads the Founder preview shell (SOURCE/lib/dev/zyra_one_journey_concept_shell.dart) and writes
PRODUCT/BLUEPRINT/ZYRA_PLANNED_SCREEN_INVENTORY_GENERATED.md: every tab and page, its title, the
method that builds it, the pages it opens, and the visible labels and messages found in its code.
Re-run after any change to the planned app.
"""
import os, re, collections
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
SHELL = os.path.join(ROOT, 'SOURCE', 'lib', 'dev', 'zyra_one_journey_concept_shell.dart')
OUT = os.path.join(ROOT, 'PRODUCT', 'BLUEPRINT', 'ZYRA_PLANNED_SCREEN_INVENTORY_GENERATED.md')
src = open(SHELL, encoding='utf-8').read()

def strip_comments(s):
    s = re.sub(r'/\*[\s\S]*?\*/', '', s)
    return re.sub(r'(?m)^\s*//.*$', '', s)
code = strip_comments(src)

def body_from(i):
    """Return the body text of a method whose header ends at index i ('{' or '=>' follows)."""
    j = i
    while code[j].isspace(): j += 1
    if code.startswith('=>', j):
        depth = 0; k = j + 2; q = None
        while k < len(code):
            c = code[k]
            if q:
                if c == '\\': k += 2; continue
                if c == q: q = None
            elif c in '\'"': q = c
            elif c in '([{': depth += 1
            elif c in ')]}': depth -= 1
            elif c == ';' and depth == 0: return code[j:k]
            k += 1
        return code[j:]
    if code[j] != '{': return ''
    depth = 0; k = j; q = None
    while k < len(code):
        c = code[k]
        if q:
            if c == '\\': k += 2; continue
            if c == q: q = None
        elif c in '\'"': q = c
        elif c == '{': depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0: return code[j:k + 1]
        k += 1
    return code[j:]

methods = {}
for m in re.finditer(r'(?m)^\s{2}(?:static\s+)?(?:[\w<>?,\s]+?)\s+(_\w+)\s*(\([^)]*\)|\{[^}]*\})?\s*(?=\{|=>)', code):
    name = m.group(1)
    if name not in methods:
        methods[name] = body_from(m.end())
for m in re.finditer(r'(?m)^\s{2}(?:[\w<>?]+)\s+get\s+(_\w+)\s*(?==>|\{)', code):
    methods.setdefault(m.group(1), body_from(m.end()))

# page -> builder, from _content()
content = methods.get('_content', '')
page_builder = {}
for m in re.finditer(r"((?:'[a-z_]+'\s*\|\|\s*)*'[a-z_]+')\s*=>\s*(_\w+)\(", content):
    for p in re.findall(r"'([a-z_]+)'", m.group(1)): page_builder[p] = m.group(2)
titles = {}
for m in re.finditer(r"((?:'[a-z_]+'\s*\|\|\s*)*'[a-z_]+')\s*=>\s*'([^']+)'", methods.get('_pageOptionsTitle', '')):
    for p in re.findall(r"'([a-z_]+)'", m.group(1)): titles[p] = m.group(2)

seeker_tabs = ['Profiles', 'Journey', 'My ZYRA', 'Guardian', 'Profile']
guardian_tabs = ['My ZYRA', 'Network', 'Seekers', 'Profile']
tab_builders = {'seeker': [], 'guardian': []}
sw = re.findall(r'switch \(_tab\) \{(.*?)\}', content, re.S)
for role, block in zip(['guardian', 'seeker'], sw):
    tab_builders[role] = re.findall(r'=>\s*(_\w+)\(', block)

NAV = re.compile(r"(?:_open|_pages\.add|_showJourneyAction|_openBrowseOptions|_openPage|_push)\(\s*'([a-z_]+)'|=>\s*_open\(\s*'([a-z_]+)'|(?:page|target|destination)\s*:\s*'([a-z_]+)'")
LABEL = re.compile(r"(?:label|title|text|heading|_title|_heading|_button|_action|_row|row)\s*[:(]\s*'([^'$]{3,80})'")
MSG = re.compile(r"(?:message|subtitle|detail|description|body|_body|_paragraph|_line)\s*[:(]\s*'([^']{12,160})'")

# Helpers used by many pages (headers, menus, shared rails) would make every page look like it opens everything.
_callers = collections.Counter()
for _b in set(page_builder.values()) | {x for v in tab_builders.values() for x in v}:
    for _c in set(re.findall(r'\b(_[a-z]\w*)\(', methods.get(_b, ''))): _callers[_c] += 1
SHARED = {c for c, n in _callers.items() if n > 4}

def collect(name, depth=0, seen=None):
    seen = seen or set()
    if name in seen or name not in methods or depth > 3: return set(), [], []
    seen.add(name)
    b = methods[name]
    nav = {x for t in NAV.findall(b) for x in t if x and x in page_builder}
    labels = [x for x in LABEL.findall(b)]
    msgs = [x for x in MSG.findall(b)]
    for callee in set(re.findall(r'\b(_[a-z]\w*)\(', b)):
        if callee in page_builder.values() and callee != name: continue  # another page
        if callee in SHARED: continue
        n2, l2, m2 = collect(callee, depth + 1, seen)
        nav |= n2; labels += l2; msgs += m2
    return nav, labels, msgs

def uniq(xs, n):
    out = []
    for x in xs:
        x = re.sub(r'\s+', ' ', x).strip()
        if x and x not in out: out.append(x)
    return out[:n]

pages_by_builder = collections.defaultdict(list)
for p, b in page_builder.items(): pages_by_builder[b].append(p)
opened_from = collections.defaultdict(set)
rows = []
for p, b in sorted(page_builder.items()):
    nav, labels, msgs = collect(b)
    for t in nav: opened_from[t].add(p)
    rows.append((p, b, nav, labels, msgs))
tab_rows = []
for role, names in (('Seeker', seeker_tabs), ('Guardian', guardian_tabs)):
    for i, b in enumerate(tab_builders[role.lower()]):
        nav, labels, msgs = collect(b)
        label = names[i] if i < len(names) else f'tab {i}'
        for t in nav: opened_from[t].add(f'{role} tab "{label}"')
        tab_rows.append((role, label, b, nav, labels, msgs))

out = ['---', 'id: DOC-ZYRA-0286', 'type: REPORT', 'status: CURRENT', 'feature: PRODUCT BLUEPRINT',
       'purpose: Generated screen inventory of the planned app (Founder preview) - every tab and page, its title, what opens it, what it opens, and the labels and messages in its code',
       'links: [DOC-ZYRA-0278, DR-ZYRA-274]', 'owner: Fable (generated)', '---', '',
       '# ZYRA PLANNED APP — SCREEN INVENTORY (GENERATED)', '',
       'Generated by `SYSTEM/tools/blueprint/generate_planned_screen_map.py` from `SOURCE/lib/dev/zyra_one_journey_concept_shell.dart`. '
       'Do not edit by hand. Labels and messages are the literal strings found in each page\'s code (first ones only); '
       'some appear only in certain states.', '',
       f'**{len(tab_rows)} tabs** (5 Seeker, 4 Guardian) and **{len(page_builder)} pages**.', '',
       '## Tabs', '', '| Role | Tab | Built by | Opens | Labels found |', '|---|---|---|---|---|']
for role, label, b, nav, labels, msgs in tab_rows:
    out.append(f'| {role} | {label} | `{b}` | {", ".join(sorted(nav)) or "—"} | {" · ".join(uniq(labels, 12)) or "—"} |')
out += ['', '## Pages', '', '| Page | Title | Built by | Opened from | Opens | Labels found | Messages found |', '|---|---|---|---|---|---|---|']
for p, b, nav, labels, msgs in rows:
    out.append(f'| `{p}` | {titles.get(p, "—")} | `{b}` | {", ".join(sorted(opened_from.get(p, []))) or "—"} | {", ".join(sorted(nav)) or "—"} | '
               f'{" · ".join(uniq(labels, 10)).replace("|", "/") or "—"} | {" · ".join(uniq(msgs, 3)).replace("|", "/") or "—"} |')
unreached = sorted(p for p in page_builder if not opened_from.get(p))
out += ['', '## Pages with no opener found', '', 'Either opened in a way the generator cannot follow, or unreachable:', '',
        ', '.join(f'`{p}`' for p in unreached) or 'none', '']
open(OUT, 'w', encoding='utf-8').write('\n'.join(out))
print(f'{len(tab_rows)} tabs, {len(page_builder)} pages, {len(unreached)} without an opener -> {os.path.relpath(OUT, ROOT)}')
