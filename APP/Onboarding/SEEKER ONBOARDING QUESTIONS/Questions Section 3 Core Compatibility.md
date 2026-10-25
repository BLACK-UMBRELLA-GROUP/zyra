---
id: DOC-ZYRA-0042
type: SPEC
status: CURRENT
feature: APP: ONBOARDING
purpose: Onboarding / Seeker Onboarding Questions — Questions Section 3 Core Compatibility
links: []
owner: ZYRA chat
---

FEATURE NAME
SEEKER ONBOARDING QUESTIONS
Document: Questions — Section 3 Core Compatibility

============================================================
SECTION 3 — PRIVATE CORE COMPATIBILITY
============================================================

Status: Approved

Note: Every question follows the standard compatibility
matrix pattern. See Summary.md for the full flow.
Hard Requirements only appear where explicitly noted.

------------------------------------------------------------
CATEGORY — FAMILY
------------------------------------------------------------

QUESTION 1 — PREVIOUS MARRIAGE STATUS
Hard Requirement: Supported

About You:
  What best describes your previous marriage status?
    • Never Married
    • Divorced
    • Widowed

Compatibility:
  Which previous marriage statuses would you be
  comfortable matching with?
  Status          Preference
  Never Married   🟢 🟡 🔴
  Divorced        🟢 🟡 🔴
  Widowed         🟢 🟡 🔴

  What the colours mean:
    🟢 I'd be happy to match with this status.
    🟡 It depends on the individual.
    🔴 I'd prefer not to match with this status.

Hard Requirement — generated dynamically:
  If only Divorced is 🔴:
    ☐ Never show me divorced people.
  If only Widowed is 🔴:
    ☐ Never show me widowed people.
  If Divorced and Widowed are 🔴:
    ☐ Never show me divorced or widowed people.
  If only Never Married is 🔴:
    ☐ Never show me people who have never been married.
  If Never Married and Divorced are 🔴:
    ☐ Never show me people who have never been married
      or are divorced.
  If Never Married and Widowed are 🔴:
    ☐ Never show me people who have never been married
      or are widowed.
  If all three are 🔴:
    ⚠️ At least one option must remain 🟢 or 🟡 so ZYRA
    can introduce compatible matches. Please update your
    preferences before continuing.
    [Block — do not allow user to continue]

──────────────────────────────────────────────────────────

QUESTION 2 — DO YOU HAVE CHILDREN?
Hard Requirement: Supported

About You:
  Do you currently have any children?
    • Yes
    • No

Compatibility:
  How would you feel about matching with someone who
  has children?
    🟢 I'd be happy to match with someone who has children.
    🟡 It depends on the individual.
    🔴 I'd prefer not to match with someone who has children.

Hard Requirement (if 🔴 selected):
  ☐ Never show me people who have children.

------------------------------------------------------------
CATEGORY — EDUCATION & FINANCES
------------------------------------------------------------

QUESTION 3 — HIGHEST EDUCATION LEVEL
Hard Requirement: Not supported

About You:
  What is the highest level of education you have completed?
    • School Leaver
    • College / Further Education
    • Bachelor's Degree
    • Master's Degree
    • Doctorate (PhD)
    • Other
  If Other: searchable predefined education list.

Compatibility:
  Which education levels would you be comfortable
  matching with?
  Level                     Preference
  School Leaver             🟢 🟡 🔴
  College / Further Ed      🟢 🟡 🔴
  Bachelor's Degree         🟢 🟡 🔴
  Master's Degree           🟢 🟡 🔴
  Doctorate (PhD)           🟢 🟡 🔴
  Other                     🟢 🟡 🔴

──────────────────────────────────────────────────────────

QUESTION 4 — EMPLOYMENT STATUS
Hard Requirement: Not supported

About You:
  Which best describes your current employment status?
    • Full-Time Employment
    • Part-Time Employment
    • Self-Employed
    • Student
    • Between Jobs
    • Unable to Work
    • Retired
    • Other
  If Other: searchable predefined employment list.

Compatibility:
  Which employment situations would you be comfortable
  matching with?
  Status                Preference
  Full-Time Employment  🟢 🟡 🔴
  Part-Time Employment  🟢 🟡 🔴
  Self-Employed         🟢 🟡 🔴
  Student               🟢 🟡 🔴
  Between Jobs          🟢 🟡 🔴
  Unable to Work        🟢 🟡 🔴
  Retired               🟢 🟡 🔴
  Other                 🟢 🟡 🔴

──────────────────────────────────────────────────────────

QUESTION 5 — ANNUAL INCOME
Hard Requirement: Not supported

About You:
  Which range best represents your annual income?
  (Currency and ranges auto-adjust by country)

  Example (United Kingdom):
    • Under £20,000
    • £20,000 – £39,999
    • £40,000 – £59,999
    • £60,000 – £79,999
    • £80,000 – £99,999
    • £100,000+

Compatibility:
  Which income ranges would you be comfortable matching with?
  (Same localised ranges shown)
  Range   Preference
  [1]     🟢 🟡 🔴
  [2]     🟢 🟡 🔴
  [3]     🟢 🟡 🔴
  [4]     🟢 🟡 🔴
  [5]     🟢 🟡 🔴
  [6]     🟢 🟡 🔴

──────────────────────────────────────────────────────────

QUESTION 6 — FINANCIAL READINESS FOR MARRIAGE
Hard Requirement: Not supported

About You:
  How would you describe your current financial readiness
  for marriage?
    • Ready now
    • Almost ready
    • Still working towards it
    • I would rely on family support
    • Other
  If Other: searchable predefined list.

Compatibility:
  Which financial situations would you be comfortable
  matching with?
  Situation                     Preference
  Ready now                     🟢 🟡 🔴
  Almost ready                  🟢 🟡 🔴
  Still working towards it      🟢 🟡 🔴
  I would rely on family        🟢 🟡 🔴
  Other                         🟢 🟡 🔴

──────────────────────────────────────────────────────────

QUESTION 7 — PREFERRED MAHR BUDGET
Hard Requirement: Not supported

About You:
  (Men) Which Mahr range would you feel comfortable offering?
  (Women) Which Mahr range would you feel comfortable
  requesting?
  (Currency and ranges auto-adjust by country)

  Example (United Kingdom):
    • Up to £1,000
    • £1,001 – £5,000
    • £5,001 – £10,000
    • £10,001 – £25,000
    • £25,001 – £50,000
    • £50,000+

Compatibility:
  Which Mahr ranges would you be comfortable with?
  Range               Preference
  Up to £1,000        🟢 🟡 🔴
  £1,001 – £5,000     🟢 🟡 🔴
  £5,001 – £10,000    🟢 🟡 🔴
  £10,001 – £25,000   🟢 🟡 🔴
  £25,001 – £50,000   🟢 🟡 🔴
  £50,000+            🟢 🟡 🔴

------------------------------------------------------------
CATEGORY — MARRIAGE GOALS
------------------------------------------------------------

QUESTION 8 — DO YOU WANT CHILDREN?
Hard Requirement: TBC

About You:
  Do you want to have children?
    • Yes
    • No
    • Unsure

Compatibility: TBC

──────────────────────────────────────────────────────────

QUESTION 9 — MARRIAGE STRUCTURE
Hard Requirement: TBC

About You:
  Which best describes your preferred marriage structure?
    • Monogamy Only
    • Open To Polygyny
    • Seeking Additional Wife

Compatibility: TBC

------------------------------------------------------------
CATEGORY — FAITH
------------------------------------------------------------

QUESTIONS 10–17 — FAITH QUESTIONS
Compatibility matrices: TBC per question

Questions:
  10. How Often Do You Pray?
  11. How Often Do You Read The Quran?
  12. Quran Memorisation
  13. Do You Fast During Ramadan?
  14. Do You Pay Zakat?
  15. Have You Performed Umrah?
  16. Have You Performed Hajj?
  17. Approach To Interest-Based (Riba) Financial Products

Note: Exact options and compatibility matrices for
questions 8–17 to be confirmed in a future session.

------------------------------------------------------------
CATEGORY — LIFESTYLE
------------------------------------------------------------

QUESTION 18 — DO YOU SMOKE OR VAPE?
Hard Requirement: TBC

About You: Do you smoke or vape?
Compatibility: TBC

──────────────────────────────────────────────────────────

QUESTION 19 — ARE YOU WILLING TO RELOCATE?
Hard Requirement: TBC

About You: Are you willing to relocate?
Compatibility: TBC

Note: Exact options and compatibility matrices for
questions 18–19 to be confirmed in a future session.
