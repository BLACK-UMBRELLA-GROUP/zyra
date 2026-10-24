#!/usr/bin/env python3
"""
ZYRA — Documentation Index generator.

WHY THIS IS A SCRIPT AND NOT A DOCUMENT
---------------------------------------
The Index went 19 days stale (measured 2026-08-13): 36 of 65 current-version
documents created after its date were absent from it, while it described
itself as the source of truth for "where does X live". It went stale because
it was hand-maintained, and hand-maintenance loses to a project that produces
a governed document every other day.

So the Index is now GENERATED from disk. Run this and the Index cannot be
wrong about what exists — only about what things mean, which is what the
curated notes below are for.

USAGE
    cd "SUB BUSINESS/ZYRA"
    python3 SYSTEM/tools/generate_doc_index.py

Writes SYSTEM/DOCUMENTS/ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V4.md.
Re-run after adding, superseding or relocating any governed document.
Raised as part of OA-ZYRA-208 (findings become actions).
"""

import io
import os
import re
import sys
from datetime import date

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'SYSTEM', 'DOCUMENTS',
                   'ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V4.md')

SKIP_DIRS = {'.git', 'SOURCE', '_to_delete', 'node_modules', '.dart_tool'}

# Area → (heading, owner). Longest prefix wins.
AREAS = [
    ('SYSTEM/DOCUMENTS/MASTER_GOVERNANCE', 'Governance contracts', 'Founder'),
    ('SYSTEM/DOCUMENTS/MASTER_CONTRACTS', 'Execution contracts', 'Founder'),
    ('SYSTEM/DOCUMENTS/MASTER_STANDARDS', 'Standards', 'Lead Architect'),
    ('SYSTEM/DECISIONS_REGISTER', 'Decisions register', 'Founder'),
    ('SYSTEM/OUTSTANDING_ACTIONS', 'Outstanding actions register', 'Lead Architect'),
    ('SYSTEM/AGENTS', 'Agent contracts (legacy — see note)', 'Lead Architect'),
    ('SYSTEM/RESOURCES', 'Resources and working material', 'Lead Architect'),
    ('SYSTEM/LOGS', 'Logs', 'Lead Architect'),
    ('SYSTEM/DOCUMENTS', 'System documents', 'Lead Architect'),
    ('APP/Standards', 'App standards', 'Lead Architect'),
    ('APP', 'Feature specifications', 'Product (Fable) / Lead Architect'),
    ('BUSINESS', 'Business documents', 'Founder'),
    ('REPORTS', 'Reports', 'Lead Architect'),
    ('ARCHIVE', 'Retired frameworks (frozen)', '—'),
]

FIELD = re.compile(r'^\*\*(Version|Status|Date|Supersedes|Owner|Author):\*\*\s*(.+?)\s*$', re.M)
TITLE = re.compile(r'^#\s+(.+?)\s*$', re.M)
SUPERSESSION_BANNER = re.compile(
    r'^ {0,3}> {1,4}\*\*SUPERSEDED[ \t]+—[ \t]+'
    r'(?:NOT CURRENT\.[^*\r\n]*|\d{4}-\d{2}-\d{2}\.)\*\*(?=$|[ \t\r\n])'
)


def read_meta(path):
    try:
        head = io.open(path, encoding='utf-8', errors='replace').read(4000)
    except OSError:
        return {}
    meta = {k: v for k, v in FIELD.findall(head)}
    # A leading explicit banner, before or directly after the document H1,
    # outranks the historical Status header. Skip blank lines, not indentation:
    # four spaces/tabs denote code examples, never an H1 or status banner.
    lead = re.sub(r'\A(?:[ \t]*\r?\n)*', '', head, count=1)
    lead = re.sub(r'\A {0,3}#[ \t]+[^\r\n]+\r?\n(?:[ \t]*\r?\n)*', '', lead, count=1)
    meta['SupersededFlag'] = bool(SUPERSESSION_BANNER.match(lead))
    t = TITLE.search(head)
    if t:
        meta['Title'] = t.group(1)
    return meta


def clean(value, limit=70):
    """Header fields in this project sometimes run to a paragraph. Take the
    first clause only — the Index is a registry, not a mirror."""
    if not value:
        return '—'
    v = re.split(r'\s+[·—]\s+\*\*|\. ', value.strip())[0]
    v = v.replace('**', '').replace('|', '/').strip()
    return (v[:limit - 1] + '…') if len(v) > limit else (v or '—')


def area_for(rel):
    for prefix, heading, owner in AREAS:
        if rel.startswith(prefix + os.sep) or rel == prefix:
            return heading, owner
    return 'Other', 'Lead Architect'


def collect():
    rows = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames
                      if d not in SKIP_DIRS and 'PRIVATE' not in d.upper()]
        for fn in sorted(filenames):
            if not fn.endswith('.md'):
                continue
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, ROOT)
            meta = read_meta(full)
            heading, owner = area_for(rel)
            current, archived = classify_currency(rel, meta)
            rows.append({
                'rel': rel.replace(os.sep, '/'),
                'name': fn,
                'dir': os.path.dirname(rel).replace(os.sep, '/') or '.',
                'current': current,
                'archived': archived,
                'heading': heading,
                'owner': meta.get('Owner') or meta.get('Author') or owner,
                'version': clean(meta.get('Version'), 24),
                'status': clean(meta.get('Status'), 46),
                'date': clean(meta.get('Date'), 12),
                'title': clean(meta.get('Title'), 62),
            })
    return rows


def classify_currency(rel, meta):
    """Do not publish rollback copies or explicitly superseded files as current."""
    parts = rel.replace(os.sep, '/').split('/')
    archived = bool(
        meta.get('SupersededFlag')
        or any(p.lower() in {'archive', 'archives', 'temporary', 'pre',
                              'backup', 'backups', 'doc_pre',
                              'doc_pre_delivery', 'delivery_doc_pre',
                              'launch_doc_pre', 'pre_source'}
               or p.lower().endswith('_pre')
               for p in parts[:-1])
        or re.search(r'_\d{4}-\d{2}-\d{2}_V\d+\.md$', parts[-1])
    )
    return 'CURRENT_VERSION' in parts[-1] and not archived, archived


PREAMBLE = """# ZYRA — Documentation Index

**Version:** V4
**Status:** CURRENT_VERSION
**Date:** {today}
**Supersedes:** ZYRA_DOCUMENTATION_INDEX_2026-09-12_V3.md (SYSTEM/DOCUMENTS/ARCHIVE/)
**Governing Reference:** ZYRA_GOVERNANCE, DR-ZYRA-103
**Generated by:** `SYSTEM/tools/generate_doc_index.py` — do not hand-edit the tables

---

## How to use this document

| Question | Look at |
|---|---|
| What documents exist, and where? | This Index — §2 onward |
| What does each one *mean* / who owns it? | This Index — Owner and Status columns |
| What is the literal folder tree? | `TREEVIEW.md` |
| What was decided, and why? | `SYSTEM/DECISIONS_REGISTER/DECISIONS_V1.md` |
| What still needs doing? | `SYSTEM/OUTSTANDING_ACTIONS/OUTSTANDING_ACTIONS_V2.md` |

## What changed from V3

V4 records the DR-ZYRA-228 / OA-ZYRA-286 documentation reconciliation: the
current Developer Mode and Authentication summaries/scripts, Settings &
Identity V3, Developer Control handover V2 and App Store runbook V2. Their
superseded governed versions remain byte-preserved in the documented archive
locations.

The mechanism introduced by V3 remains unchanged. **The tables below are
generated from disk.** The Index can therefore be wrong only when it has not
been regenerated or when a source document's own metadata is wrong.

Regenerate after adding, superseding or relocating any governed document:

```
cd "SUB BUSINESS/ZYRA" && python3 SYSTEM/tools/generate_doc_index.py
```

## Reading the Status column

Status is taken verbatim from each document's own header, truncated to its
first clause. Documents in this project distinguish carefully between
`APPROVED`, `PROPOSED — nothing built`, `FOR REVIEW`, `PARKED` and
`IMPLEMENTED`. **A document existing is not a decision having been made.**
Where the column reads `—`, the document declares no status and should be
treated as informational, not governing.
Explicit supersession banners and archived/rollback locations take priority
over retained CURRENT_VERSION filenames. Historical files are not renamed.

## Ownership

Owner is the document's own `Owner:`/`Author:` field where present, otherwise
assigned by area: Founder owns governance, decisions and business documents;
Lead Architect owns system documents, standards and registers; Product owns
feature specifications. Ownership means accountability for currency, not
authorship.

---
"""


def render(rows):
    out = [PREAMBLE.format(today=date.today().isoformat())]

    current = [r for r in rows if r['current']]
    archived = [r for r in rows if r['archived']]
    plain = [r for r in rows if not r['current'] and not r['archived']]

    out.append("## 1. Summary\n")
    out.append("| Class | Count |")
    out.append("|---|---:|")
    out.append("| Current-version governed documents | %d |" % len(current))
    out.append("| Archived versions (reference-only) | %d |" % len(archived))
    out.append("| Ungoverned documents (no version suffix) | %d |" % len(plain))
    out.append("| **Total** | **%d** |" % len(rows))
    out.append("")
    out.append("> The %d ungoverned documents are mostly `Summary.md` / "
               "`References.md` / `Flow Diagram.md` files under `APP/` and "
               "`BUSINESS/`. `BUSINESS/` in particular holds the "
               "commercially load-bearing documents and is being promoted to "
               "governed status under **OA-ZYRA-209**." % len(plain))
    out.append("")
    out.append("---\n")

    n = 2
    for _, heading, _owner in AREAS + [(None, 'Other', None)]:
        group = [r for r in current if r['heading'] == heading]
        if not group:
            continue
        out.append("## %d. %s — current\n" % (n, heading))
        out.append("| Document | V | Status | Date | Owner | Location |")
        out.append("|---|---|---|---|---|---|")
        for r in sorted(group, key=lambda x: x['name']):
            stem = r['name'].replace('.md', '')
            stem = re.sub(r'_CURRENT_VERSION_V\d+$', '', stem)
            out.append("| `%s` | %s | %s | %s | %s | `%s/` |" % (
                stem, r['version'], r['status'], r['date'], r['owner'], r['dir']))
        out.append("")
        n += 1

    out.append("---\n")
    out.append("## %d. Archived versions (reference-only)\n" % n)
    out.append("Archived documents are **never** authoritative. Where an "
               "archived version conflicts with the current one, the current "
               "one wins — `ZYRA_GOVERNANCE` §4.3.\n")
    out.append("| Document | Superseded on | Location |")
    out.append("|---|---|---|")
    for r in sorted(archived, key=lambda x: (x['dir'], x['name'])):
        m = re.search(r'_(\d{4}-\d{2}-\d{2})_V\d+\.md$', r['name'])
        out.append("| `%s` | %s | `%s/` |" % (
            r['name'].replace('.md', ''), m.group(1) if m else '—', r['dir']))
    out.append("")
    n += 1

    out.append("---\n")
    out.append("## %d. Ungoverned documents\n" % n)
    out.append("No version suffix, no status header, no supersession trail. "
               "Listed so they are visible, not because they are "
               "authoritative. **OA-ZYRA-209** promotes the `BUSINESS/` set "
               "first, in the Founder's priority order: Pricing, Terminology, "
               "Brand Guidelines, Launch Guide.\n")
    out.append("| Document | Location |")
    out.append("|---|---|")
    for r in sorted(plain, key=lambda x: (x['dir'], x['name'])):
        out.append("| `%s` | `%s/` |" % (r['name'], r['dir']))
    out.append("")

    out.append("---\n")
    out.append("*Generated %s by `SYSTEM/tools/generate_doc_index.py`. "
               "Tables are machine-written; the prose above is maintained by "
               "hand.*" % date.today().isoformat())
    return "\n".join(out) + "\n"


def main():
    rows = collect()
    io.open(OUT, 'w', encoding='utf-8').write(render(rows))
    cur = sum(1 for r in rows if r['current'])
    print("Documentation Index V4 written: %d documents (%d current)"
          % (len(rows), cur))
    print(OUT)


if __name__ == '__main__':
    sys.exit(main())
