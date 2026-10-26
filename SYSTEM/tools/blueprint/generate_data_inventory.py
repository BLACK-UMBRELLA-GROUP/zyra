#!/usr/bin/env python3
"""
generate_data_inventory.py - ZYRA blueprint part 3 (OA-ZYRA-309).

Replays SOURCE/supabase/migrations in filename order (no database is touched) and reports the
end state: every table with its columns, links (foreign keys), row-level security and policies,
every database function with its security mode and who may run it, triggers, storage buckets and
server (edge) functions. Writes PRODUCT/BLUEPRINT/ZYRA_DATA_INVENTORY_GENERATED.md.

Static reading of SQL text: dynamic SQL (EXECUTE format(...)) and objects created outside the
migrations are not seen. The live database can differ from the migrations if something was
applied by hand; that check needs the Founder's GO. No AI runs git; this tool never calls git.

Usage: python3 generate_data_inventory.py "<ZYRA root>"
"""
import os, re, sys, collections, json

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
MIG = os.path.join(ROOT, 'SOURCE', 'supabase', 'migrations')
FUN = os.path.join(ROOT, 'SOURCE', 'supabase', 'functions')
OUT = os.path.join(ROOT, 'PRODUCT', 'BLUEPRINT', 'ZYRA_DATA_INVENTORY_GENERATED.md')
JSON_OUT = os.path.join(ROOT, 'PRODUCT', 'BLUEPRINT', 'zyra_data_inventory.json')

def clean(sql):
    sql = re.sub(r'/\*[\s\S]*?\*/', ' ', sql)
    sql = re.sub(r'--[^\n]*', '', sql)
    return sql

def bare(n):
    n = n.strip().strip('"')
    return n.split('.')[-1].strip('"').lower()

def split_top(s):
    out, depth, cur, q = [], 0, '', False
    for ch in s:
        if ch == "'": q = not q
        if not q:
            if ch == '(': depth += 1
            elif ch == ')': depth -= 1
            elif ch == ',' and depth == 0:
                out.append(cur); cur = ''; continue
        cur += ch
    if cur.strip(): out.append(cur)
    return out

def body_after(sql, start):
    # text inside the parentheses that open at/after start
    i = sql.index('(', start); depth = 0
    for j in range(i, len(sql)):
        if sql[j] == '(': depth += 1
        elif sql[j] == ')':
            depth -= 1
            if depth == 0: return sql[i + 1:j]
    return sql[i + 1:]

tables = collections.OrderedDict(); functions = {}; triggers = {}; buckets = {}; comments = {}; views = {}
def table(n):
    return tables.setdefault(n, {'columns': collections.OrderedDict(), 'fks': set(), 'rls': False,
                                 'policies': {}, 'created': '', 'touched': '', 'schema': 'public'})

files = sorted(f for f in os.listdir(MIG) if f.endswith('.sql'))
for f in files:
    raw = open(os.path.join(MIG, f), encoding='utf-8', errors='replace').read()
    # function bodies are dollar-quoted: record and blank them so their SQL is not parsed as DDL
    for m in re.finditer(r'create\s+(?:or\s+replace\s+)?function\s+([\w."]+)\s*\(', raw, re.I):
        args = body_after(raw, m.end() - 1)
        after = m.end() + len(args) + 1
        tag = re.compile(r'(\$\w*\$)').search(raw, after)
        if not tag: continue
        header = raw[after:tag.start()]
        close = raw.find(tag.group(1), tag.end())
        fbody = raw[tag.end():close if close > 0 else tag.end()]
        tail = raw[close:close + 400] if close > 0 else ''
        name = bare(m.group(1)); schema = m.group(1).split('.')[0].strip('"').lower() if '.' in m.group(1) else 'public'
        rt = re.search(r'returns\s+([\s\S]+?)\s+(?:language|as|security|stable|immutable|volatile|set|strict|parallel|cost)\b', header + ' as', re.I)
        functions[name] = {'args': re.sub(r'\s+', ' ', args).strip()[:160], 'returns': re.sub(r'\s+', ' ', rt.group(1)).strip()[:60] if rt else '?',
                           'definer': 'security definer' in (header + tail).lower(), 'schema': schema, 'file': f,
                           'grants': functions.get(name, {}).get('grants', set()), 'dropped': False,
                           'tables': sorted(set(re.findall(r'\b(?:from|join|into|update)\s+(?:public\.)?"?(\w+)"?', fbody, re.I)))}
    sql = clean(re.sub(r'(\$\w*\$)[\s\S]*?\1', ' ', raw))
    for m in re.finditer(r'create\s+table\s+(?:if\s+not\s+exists\s+)?([\w."]+)\s*\(', sql, re.I):
        name = bare(m.group(1)); t = table(name); t['created'] = t['created'] or f; t['touched'] = f
        t['schema'] = m.group(1).split('.')[0].strip('"').lower() if '.' in m.group(1) else 'public'
        for part in split_top(body_after(sql, m.end() - 1)):
            p = part.strip(); low = p.lower()
            if not p: continue
            ref = re.search(r'references\s+([\w."]+)', p, re.I)
            if ref: t['fks'].add(bare(ref.group(1)))
            if re.match(r'(constraint|primary\s+key|unique|check|foreign\s+key|exclude)\b', low): continue
            cm = re.match(r'"?(\w+)"?\s+([\w\[\]]+(?:\s*\([^)]*\))?(?:\s+with(?:out)?\s+time\s+zone)?)', p)
            if cm: t['columns'][cm.group(1)] = cm.group(2)
    for m in re.finditer(r'alter\s+table\s+(?:if\s+exists\s+)?(?:only\s+)?([\w."]+)\s+([\s\S]*?);', sql, re.I):
        name = bare(m.group(1)); body = m.group(2); t = table(name); t['touched'] = f
        for a in re.finditer(r'add\s+column\s+(?:if\s+not\s+exists\s+)?"?(\w+)"?\s+([\w\[\]]+)', body, re.I): t['columns'][a.group(1)] = a.group(2)
        for a in re.finditer(r'drop\s+column\s+(?:if\s+exists\s+)?"?(\w+)"?', body, re.I): t['columns'].pop(a.group(1), None)
        for a in re.finditer(r'rename\s+column\s+"?(\w+)"?\s+to\s+"?(\w+)"?', body, re.I):
            if a.group(1) in t['columns']: t['columns'][a.group(2)] = t['columns'].pop(a.group(1))
        for a in re.finditer(r'references\s+([\w."]+)', body, re.I): t['fks'].add(bare(a.group(1)))
        if re.search(r'enable\s+row\s+level\s+security', body, re.I): t['rls'] = True
        if re.search(r'disable\s+row\s+level\s+security', body, re.I): t['rls'] = False
        rn = re.search(r'^\s*rename\s+to\s+"?(\w+)"?', body, re.I)
        if rn: tables[rn.group(1).lower()] = tables.pop(name)
    for m in re.finditer(r'drop\s+table\s+(?:if\s+exists\s+)?([\w.",\s]+?)(?:\s+cascade)?\s*;', sql, re.I):
        for n in m.group(1).split(','):
            if 'pg_temp' not in n.lower(): tables.pop(bare(n), None)
    # policies: creates and drops in the order they appear in the file
    for m in re.finditer(r'(create|drop)\s+policy\s+(?:if\s+exists\s+)?"?([^"]+?)"?\s+on\s+([\w."]+)([\s\S]*?);', sql, re.I):
        tb = table(bare(m.group(3)))
        if m.group(1).lower() == 'drop':
            tb['policies'].pop(m.group(2), None); continue
        rest = m.group(4)
        cmd = (re.search(r'\bfor\s+(all|select|insert|update|delete)\b', rest, re.I) or [None, 'all'])[1].lower()
        roles = (re.search(r'\bto\s+([\w,\s]+?)(?:\s+using|\s+with|$)', rest, re.I) or [None, 'public'])[1].strip()
        using = re.search(r'(?:using|with\s+check)\s*\(([\s\S]*)\)', rest, re.I)
        tb['policies'][m.group(2)] = {'cmd': cmd, 'roles': re.sub(r'\s+', ' ', roles), 'rule': re.sub(r'\s+', ' ', using.group(1))[:140] if using else ''}
    for m in re.finditer(r"update\s+storage\.buckets\s+set\s+public\s*=\s*(true|false)\s+where\s+id\s*=\s*'([^']+)'", sql, re.I):
        if m.group(2) in buckets: buckets[m.group(2)]['public'] = m.group(1) + f' (changed in {f})'
    for m in re.finditer(r'drop\s+function\s+(?:if\s+exists\s+)?([\w."]+)', sql, re.I):
        n = bare(m.group(1))
        if n in functions and functions[n]['file'] != f: functions[n]['dropped'] = True
        elif n in functions and not re.search(r'create\s+(?:or\s+replace\s+)?function\s+(?:public\.)?"?' + re.escape(n) + r'\b', raw[m.end():], re.I):
            functions[n]['dropped'] = True
    for m in re.finditer(r'(grant|revoke)\s+execute\s+on\s+function\s+([\w."]+)\s*\([^)]*\)\s+(?:to|from)\s+([\w,\s]+)', sql, re.I):
        n = bare(m.group(2))
        if n in functions:
            for r in [x.strip().lower() for x in m.group(3).split(',') if x.strip()]:
                (functions[n]['grants'].add if m.group(1).lower() == 'grant' else functions[n]['grants'].discard)(r)
    # triggers: creates (incl. constraint triggers) and drops in file order, keyed by (name, table).
    # Fixed 25 Oct (lesson F11): drops used to run after creates, and constraint triggers were missed.
    ev = []
    for m in re.finditer(r'create\s+(?:or\s+replace\s+)?(?:constraint\s+)?trigger\s+"?(\w+)"?[\s\S]*?\bon\s+([\w."]+)[\s\S]*?execute\s+(?:function|procedure)\s+([\w."]+)', sql, re.I):
        ev.append((m.start(), 'c', m.group(1), bare(m.group(2)), bare(m.group(3))))
    for m in re.finditer(r'drop\s+trigger\s+(?:if\s+exists\s+)?"?(\w+)"?\s+on\s+([\w."]+)', sql, re.I):
        ev.append((m.start(), 'd', m.group(1), bare(m.group(2)), None))
    # triggers made in a loop: do-block with foreach x in array array[...] and execute format('create trigger %I ... on public.%I', x || '_suffix', x)
    for blk in re.finditer(r'\bdo\s+(\$\w*\$)([\s\S]*?)\1', raw, re.I):
        b = clean(blk.group(2))
        arr = re.search(r'foreach\s+(\w+)\s+in\s+array\s+array\s*\[([^\]]*)\]', b, re.I)
        cf = re.search(r"format\(\s*'create\s+(?:constraint\s+)?trigger\s+%I[\s\S]*?execute\s+(?:function|procedure)\s+([\w.\"]+)\s*\([^']*'\s*,\s*\w+\s*\|\|\s*'(\w+)'", b, re.I)
        if arr and cf:
            for tb in re.findall(r"'(\w+)'", arr.group(2)):
                ev.append((10**9 + blk.start(), 'c', tb + cf.group(2), tb, bare(cf.group(1))))
    for _, kind, name, tb, fn in sorted(ev, key=lambda x: x[0]):
        if kind == 'd': triggers.pop((name, tb), None)
        else: triggers[(name, tb)] = {'table': tb, 'function': fn, 'file': f}
    # views (added 26 Oct: the first version listed tables only)
    for m in re.finditer(r'create\s+(?:or\s+replace\s+)?view\s+([\w."]+)', sql, re.I): views[bare(m.group(1))] = {'file': f}
    for m in re.finditer(r'drop\s+view\s+(?:if\s+exists\s+)?([\w."]+)', sql, re.I): views.pop(bare(m.group(1)), None)
    for m in re.finditer(r"insert\s+into\s+storage\.buckets\s*\(([^)]*)\)\s*values\s*\(([^)]*)\)", sql, re.I):
        cols = [c.strip() for c in m.group(1).split(',')]; vals = [v.strip().strip("'") for v in split_top(m.group(2))]
        d = dict(zip(cols, vals)); buckets[d.get('id', d.get('name', '?'))] = {'public': d.get('public', '?'), 'file': f}
    for m in re.finditer(r"""comment\s+on\s+(table|function)\s+([\w."]+)(?:\s*\([^)]*\))?\s+is\s+'((?:[^']|'')*)'""", raw, re.I):
        comments[(m.group(1).lower(), bare(m.group(2)))] = m.group(3).replace("''", "'")

tables = {k: v for k, v in tables.items() if v['columns'] or v['created']}
live_fn = {k: v for k, v in functions.items() if not v['dropped']}
edge = []
if os.path.isdir(FUN):
    for d in sorted(os.listdir(FUN)):
        p = os.path.join(FUN, d, 'index.ts')
        if os.path.exists(p):
            head = open(p, encoding='utf-8', errors='replace').read(1500)
            doc = re.sub(r'\s*(//|\*|/\*\*?|\*/)\s?', ' ', ' '.join(re.findall(r'^\s*(?://|/?\*).*$', head, re.M)[:6])).strip()
            edge.append((d, doc[:200]))

out = ['---', 'id: DOC-ZYRA-0281', 'type: REPORT', 'status: CURRENT', 'feature: PRODUCT BLUEPRINT',
       'purpose: Generated inventory of ZYRA data from the migrations - every table, column, link, security rule, database function, trigger, storage bucket and server function',
       'links: [OA-ZYRA-309, DOC-ZYRA-0280]', 'owner: Fable', '---', '', '# ZYRA DATA INVENTORY (GENERATED)', '',
       f'Generated by `SYSTEM/tools/blueprint/generate_data_inventory.py` by replaying {len(files)} migrations ({files[0][:8]} → {files[-1][:8]}). **Do not edit by hand.**',
       'Static reading of SQL: dynamic SQL and anything applied outside the migrations are not seen.', '',
       f'Tables **{len(tables)}** · functions **{len(live_fn)}** ({sum(1 for v in live_fn.values() if v["definer"])} run with owner rights) · triggers **{len(triggers)}** · storage buckets **{len(buckets)}** · server functions **{len(edge)}**', '',
       '## Tables', '']
for n in sorted(tables):
    t = tables[n]; c = comments.get(('table', n), '')
    out += [f'### {n}' + (f' ({t["schema"]})' if t['schema'] != 'public' else ''), '']
    if c: out += [f'> {c[:400]}', '']
    out += [f'- Created `{t["created"]}` · last changed `{t["touched"]}`',
            f'- Links to: {", ".join(sorted(t["fks"] - {n})) or "—"}',
            f'- Row-level security: {"**on**" if t["rls"] else ("unknown — created outside the migrations" if not t["created"] else "**OFF**")} · policies: {len(t["policies"])}',
            f'- Columns ({len(t["columns"])}): ' + ', '.join(f'`{k}` {v}' for k, v in t['columns'].items())]
    if t['policies']:
        out += ['', '| Policy | Action | Who | Rule |', '|---|---|---|---|']
        out += [f'| {p} | {d["cmd"]} | {d["roles"]} | `{d["rule"].replace("|", "/")}` |' for p, d in sorted(t['policies'].items())]
    out.append('')
out += ['## Database functions', '', 'Who may run a function is read from plain `grant`/`revoke` lines only. Grants made in loops, sweeps and default-privilege changes (Aug 2026) are not followed, so the live database is the only reliable answer.', '', '| Function | Arguments | Returns | Owner rights | Who may run it (plain grant/revoke lines only) | Reads/writes | Comment |', '|---|---|---|---|---|---|---|']
for n in sorted(live_fn):
    v = live_fn[n]
    out.append(f'| `{n}` | {v["args"].replace("|", "/") or "—"} | {v["returns"]} | {"yes" if v["definer"] else "no"} | {", ".join(sorted(v["grants"])) or "not in a plain line"} | {", ".join(x for x in v["tables"] if x in tables)[:120] or "—"} | {comments.get(("function", n), "")[:160].replace("|", "/")} |')
out += ['', '## Triggers', '', '| Trigger | Table | Runs |', '|---|---|---|']
out += [f'| `{k[0]}` | {v["table"]} | `{v["function"]}` |' for k, v in sorted(triggers.items())]
out += ['', '## Views', '', '| View | Created in |', '|---|---|'] + [f'| `{k}` | `{v["file"]}` |' for k, v in sorted(views.items())]
out += ['', '## Storage buckets', '', '| Bucket | Public | Created in |', '|---|---|---|']
out += [f'| `{k}` | {v["public"]} | `{v["file"]}` |' for k, v in sorted(buckets.items())]
out += ['', '## Server (edge) functions', '', '| Function | What its header says |', '|---|---|']
out += [f'| `{d}` | {doc.replace("|", "/") or "—"} |' for d, doc in edge]
os.makedirs(os.path.dirname(OUT), exist_ok=True)
open(OUT, 'w', encoding='utf-8').write('\n'.join(out) + '\n')
json.dump({'tables': {k: {**v, 'fks': sorted(v['fks']), 'columns': dict(v['columns'])} for k, v in tables.items()},
           'functions': {k: {**v, 'grants': sorted(v['grants'])} for k, v in live_fn.items()},
           'triggers': {f'{k[0]} ON {k[1]}': v for k, v in triggers.items()}, 'views': views, 'buckets': buckets, 'edge': edge, 'comments': {f'{a}:{b}': c for (a, b), c in comments.items()}},
          open(JSON_OUT, 'w'), indent=1, default=list)
print(f'{len(tables)} tables, {len(live_fn)} functions, {len(triggers)} triggers, {len(buckets)} buckets, {len(edge)} edge; {os.path.getsize(OUT)//1024} KB')
