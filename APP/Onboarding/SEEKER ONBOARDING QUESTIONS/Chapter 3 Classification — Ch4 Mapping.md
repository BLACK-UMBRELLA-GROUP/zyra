---
id: DOC-ZYRA-0037
type: SPEC
status: CURRENT
feature: APP: ONBOARDING
purpose: Onboarding / Seeker Onboarding Questions — Chapter 3 Classification — Ch4 Mapping
links: []
owner: ZYRA chat
---

FEATURE NAME
SEEKER ONBOARDING QUESTIONS
Document: Chapter 3 Classification — Chapter 4 Mapping

============================================================
CHAPTER 3 → CHAPTER 4 CLASSIFICATION
============================================================

Status: V3 — APPROVED
Last Updated: 2026-06-28
Counts corrected 2026-08-10 (Founder decision, Onboarding Direction B).

All 41 OPTIONAL questions confirmed for Chapter 4.
Chapter 4 total: 71 preference questions.

COUNT CORRECTION, 2026-08-10. The per-question classification below was
checked against SOURCE/lib/data/chapter3_categories.dart question by
question, all 104. It agrees with the code exactly — no question changed
classification. Only the SUMMARY lines were wrong: three category headers
in the confirmed list (Education 8, Faith 13, Technology 2) disagreed with
the items listed beneath them, and the totals inherited the error
(70 instead of 71, OPTIONAL 40 instead of 41, NONE 34 instead of 33).
The item lists were right all along; the numbers above them were not.

Per-gender reality, which no total in this document expressed: a man walks
71 Chapter 4 screens, a woman 70. Q39 (Masjid Attendance) is men-only, and
Q26 (Views on Polygamy) exists as two gender variants sharing one id — the
reason a naive count of the code returns 105 questions rather than 104.

------------------------------------------------------------
CLASSIFICATION KEY
------------------------------------------------------------

  CH4 ✓   — Confirmed Chapter 4 preference question
  NONE    — Descriptive only. No Ch4 preference question.

------------------------------------------------------------
CATEGORY 1 — FAMILY
------------------------------------------------------------

Q1   Previous Marriage Status      CH4 ✓  (REQUIRED)
Q2   Do You Have Children?         CH4 ✓  (REQUIRED)
Q3   Would You Like Children?      CH4 ✓  (REQUIRED)
Q4   Parents' Involvement          CH4 ✓  (REQUIRED)
Q5   Visiting Family               CH4 ✓  (OPTIONAL)
Q6   Living Near Parents           CH4 ✓  (REQUIRED)
Q7   Supporting Parents            CH4 ✓  (OPTIONAL)
Q8   Caring for Ageing Parents     CH4 ✓  (REQUIRED)
Q9   Living With In-Laws           CH4 ✓  (REQUIRED)
Q10  Siblings                      NONE

------------------------------------------------------------
CATEGORY 2 — EDUCATION & FINANCES
------------------------------------------------------------

Q11  Highest Education Level       CH4 ✓  (OPTIONAL)
Q12  Annual Income                 CH4 ✓  (REQUIRED)
Q13  Financial Readiness           CH4 ✓  (OPTIONAL)
Q14  Savings Habit                 CH4 ✓  (OPTIONAL)
Q15  Managing Finances             CH4 ✓  (OPTIONAL)
Q16  Career Ambition               CH4 ✓  (OPTIONAL)
Q17  Studying                      NONE
Q18  Working After Marriage        CH4 ✓  (REQUIRED)
Q19  Mahr Expectations             NONE
Q20  Debt Situation                CH4 ✓  (OPTIONAL)
Q21  Mortgage                      NONE
Q22  Financial Responsibility      CH4 ✓  (OPTIONAL)

------------------------------------------------------------
CATEGORY 3 — MARRIAGE GOALS
------------------------------------------------------------

Q23  Marriage Timeline             CH4 ✓  (REQUIRED)
Q24  Children Timeline             CH4 ✓  (OPTIONAL)
Q25  Marriage Structure            CH4 ✓  (REQUIRED)
Q26  Views on Polygamy             CH4 ✓  (REQUIRED)  gender-conditional
Q27  Main Reason for Marriage      NONE
Q28  Relocation                    CH4 ✓  (REQUIRED)
Q29  Homeschooling                 CH4 ✓  (OPTIONAL)
Q30  Travelling                    CH4 ✓  (OPTIONAL)
Q31  Marriage Pace                 CH4 ✓  (OPTIONAL)
Q32  Long-Term Vision              NONE

------------------------------------------------------------
CATEGORY 4 — FAITH
------------------------------------------------------------

Q33  Daily Prayers                 CH4 ✓  (REQUIRED)
Q34  Qur'an Reading                CH4 ✓  (REQUIRED)
Q35  Qur'an Memorisation           CH4 ✓  (OPTIONAL)
Q36  Ramadan Fasting               CH4 ✓  (REQUIRED)
Q37  Sunnah Fasting                CH4 ✓  (OPTIONAL)
Q38  Zakat                         CH4 ✓  (REQUIRED)
Q39  Masjid Attendance [MEN ONLY]  CH4 ✓  (REQUIRED)
Q40  Sadaqah                       CH4 ✓  (OPTIONAL)
Q41  Umrah                         NONE
Q42  Hajj                          NONE
Q43  Islamic Knowledge             CH4 ✓  (OPTIONAL)
Q44  Islamic Classes               CH4 ✓  (OPTIONAL)
Q45  Islamic Lectures              NONE
Q46  Madhhab                       CH4 ✓  (OPTIONAL)
Q47  Riba (Interest-Based Finance) CH4 ✓  (REQUIRED)
Q48  Children's Islamic Education  CH4 ✓  (REQUIRED)
Q49  Tahajjud                      CH4 ✓  (OPTIONAL)
Q50  Morning & Evening Adhkar      CH4 ✓  (OPTIONAL)
Q51  Pictures & Statues in Home    CH4 ✓  (OPTIONAL)

------------------------------------------------------------
CATEGORY 5 — LIFESTYLE
------------------------------------------------------------

Q52  Smoking & Vaping              CH4 ✓  (REQUIRED)
Q53  Alcohol                       CH4 ✓  (REQUIRED)
Q54  Halal Food                    CH4 ✓  (REQUIRED)
Q55  Music                         CH4 ✓  (OPTIONAL)
Q56  Physical Activity             CH4 ✓  (OPTIONAL)
Q57  Pets                          CH4 ✓  (OPTIONAL)
Q58  Tidiness                      NONE
Q59  Sleep Routine                 NONE
Q60  Hosting Family & Guests       CH4 ✓  (OPTIONAL)
Q61  Personality                   CH4 ✓  (OPTIONAL)
Q62  Free Time                     NONE
Q63  Work-Life Balance             CH4 ✓  (OPTIONAL)

------------------------------------------------------------
CATEGORY 6 — HOUSEHOLD ROLES & EXPECTATIONS
------------------------------------------------------------

Q64  Household Responsibilities    CH4 ✓  (REQUIRED)
Q65  Cooking                       CH4 ✓  (OPTIONAL)
Q66  Household Cleaning            CH4 ✓  (OPTIONAL)
Q67  Financial Provider            CH4 ✓  (REQUIRED)
Q68  Household Budgeting           CH4 ✓  (REQUIRED)
Q69  Domestic Help                 NONE
Q70  Household Decision Making     CH4 ✓  (REQUIRED)
Q71  Home Environment              CH4 ✓  (OPTIONAL)
Q72  Daily Routine                 CH4 ✓  (OPTIONAL)
Q73  Personal Space                CH4 ✓  (OPTIONAL)

------------------------------------------------------------
CATEGORY 7 — COMMUNICATION & EMOTIONAL INTELLIGENCE
------------------------------------------------------------

Q74  Communication Style           CH4 ✓  (OPTIONAL)
Q75  Conflict Resolution           CH4 ✓  (OPTIONAL)
Q76  Apologising                   NONE
Q77  Difficult Conversations       NONE
Q78  Decision Making               CH4 ✓  (OPTIONAL)
Q79  Receiving Feedback            NONE
Q80  Expressing Appreciation       NONE
Q81  Marriage Support              CH4 ✓  (OPTIONAL)
Q82  Continuous Growth             NONE
Q83  Forgiveness                   NONE
Q84  Quality Time                  CH4 ✓  (REQUIRED)
Q85  Privacy                       CH4 ✓  (REQUIRED)

------------------------------------------------------------
CATEGORY 8 — TECHNOLOGY & DIGITAL LIFESTYLE
------------------------------------------------------------

Q86  Social Media Usage            CH4 ✓  (OPTIONAL)
Q87  Sharing Marriage Online       CH4 ✓  (REQUIRED)
Q88  Screen Time                   NONE
Q89  Technology at Home            NONE
Q90  Mobile Phone Boundaries       CH4 ✓  (OPTIONAL)
Q91  Gaming                        NONE
Q92  Television & Streaming        NONE
Q93  Learning Online               NONE

------------------------------------------------------------
CATEGORY 9 — HEALTH & WELL-BEING
------------------------------------------------------------

Q94  General Health                NONE
Q95  Physical Fitness              CH4 ✓  (OPTIONAL)
Q96  Diet                          NONE
Q97  Dietary Requirements          CH4 ✓  (OPTIONAL)
Q98  Sleep                         NONE
Q99  Managing Stress               NONE
Q100 Personal Well-being           NONE
Q101 Medical Conditions            NONE
Q102 Disabilities                  NONE
Q103 Long-Term Health              NONE
Q104 Final Reflection              NONE

------------------------------------------------------------
FINAL COUNTS
------------------------------------------------------------

CH4 ✓  Total:   71 questions
  — of which REQUIRED:  30
  — of which OPTIONAL:  41

NONE Total:      33 questions

CHAPTER 3 TOTAL: 104 questions

------------------------------------------------------------
CHAPTER 4 CONFIRMED LIST — ALL 70 (grouped by category)
------------------------------------------------------------

FAMILY (9):
  Q1  Previous Marriage Status
  Q2  Do You Have Children?
  Q3  Would You Like Children?
  Q4  Parents' Involvement
  Q5  Visiting Family
  Q6  Living Near Parents
  Q7  Supporting Parents
  Q8  Caring for Ageing Parents
  Q9  Living With In-Laws

EDUCATION & FINANCES (9):
  Q11 Highest Education Level
  Q12 Annual Income
  Q13 Financial Readiness
  Q14 Savings Habit
  Q15 Managing Finances
  Q16 Career Ambition
  Q18 Working After Marriage
  Q20 Debt Situation
  Q22 Financial Responsibility

MARRIAGE GOALS (8):
  Q23 Marriage Timeline
  Q24 Children Timeline
  Q25 Marriage Structure
  Q26 Views on Polygamy
  Q28 Relocation
  Q29 Homeschooling
  Q30 Travelling
  Q31 Marriage Pace

FAITH (16):
  Q33 Daily Prayers
  Q34 Qur'an Reading
  Q35 Qur'an Memorisation
  Q36 Ramadan Fasting
  Q37 Sunnah Fasting
  Q38 Zakat
  Q39 Masjid Attendance [Men Only]
  Q40 Sadaqah
  Q43 Islamic Knowledge
  Q44 Islamic Classes
  Q46 Madhhab
  Q47 Riba
  Q48 Children's Islamic Education
  Q49 Tahajjud
  Q50 Morning & Evening Adhkar
  Q51 Pictures & Statues in Home

LIFESTYLE (9):
  Q52 Smoking & Vaping
  Q53 Alcohol
  Q54 Halal Food
  Q55 Music
  Q56 Physical Activity
  Q57 Pets
  Q60 Hosting Family & Guests
  Q61 Personality
  Q63 Work-Life Balance

HOUSEHOLD ROLES (9):
  Q64 Household Responsibilities
  Q65 Cooking
  Q66 Household Cleaning
  Q67 Financial Provider
  Q68 Household Budgeting
  Q70 Household Decision Making
  Q71 Home Environment
  Q72 Daily Routine
  Q73 Personal Space

COMMUNICATION & EI (6):
  Q74 Communication Style
  Q75 Conflict Resolution
  Q78 Decision Making
  Q81 Marriage Support
  Q84 Quality Time
  Q85 Privacy

TECHNOLOGY (3):
  Q86 Social Media Usage
  Q87 Sharing Marriage Online
  Q90 Mobile Phone Boundaries

HEALTH (2):
  Q95 Physical Fitness
  Q97 Dietary Requirements

