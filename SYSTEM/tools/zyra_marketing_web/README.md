---
id: DOC-ZYRA-0129
type: GUIDE
status: CURRENT
feature: CODE AND TOOLS
purpose: ZYRA Marketing Command Centre
links: []
owner: ZYRA chat
---

# ZYRA Marketing Command Centre

This is a local-only operating workspace for the ZYRA marketing team. It does
not connect to social accounts, publish content, send replies or spend money.

The canonical Founder entry point is inside AIOS:

```text
http://127.0.0.1:7700/marketing/
```

For a fallback developer-only loopback server, run from the ZYRA project root:

```sh
sh SYSTEM/tools/run_zyra_marketing_center.sh
```

The fallback opens at `http://127.0.0.1:4319`. Both routes use the same state,
stored in `SYSTEM/RESOURCES/MARKETING_COMMAND_CENTER/state.json` using atomic
writes and cross-process locking.

The initial workflow is:

1. Create or edit a draft.
2. Run the ZYRA brand check.
3. Record compliance review for sensitive or spend-bearing work.
4. Submit the exact preview to the Founder.
5. Record the Founder's decision.
6. Export the approved publishing pack and publish manually.
7. Record the post URL and performance metrics.

Any material edit after approval resets the item to draft. Sensitive community
categories are always routed to a human and cannot become public replies here.

The Inspiration inbox is collection-only. It retains saved video links and
marks exact repeat URLs; it does not fetch, analyse, copy or implement them.
