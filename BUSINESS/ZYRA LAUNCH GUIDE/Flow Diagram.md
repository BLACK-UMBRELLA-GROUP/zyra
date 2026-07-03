FEATURE NAME
ZYRA LAUNCH GUIDE

============================================================
FLOW DIAGRAM
============================================================

------------------------------------------------------------
LAUNCH STAGES
------------------------------------------------------------

STAGE 1 — BUILD
Create in Lovable → Connect GitHub
→ Build Screens → Build Features
→ Test → Stable Version

STAGE 2 — BACKEND
Create Supabase → Connect
→ Create Stripe → Connect
→ Create Firebase → Connect

STAGE 3 — BUSINESS SETUP
Register ZYRA LTD → Business Bank
→ Purchase zyra.app → Google Workspace
→ Legal Documents → Insurance

STAGE 4 — APP STORE RELEASE
Apple Developer Account
→ Google Play Developer Account
→ Build Release Version
→ Submit to Apple + Google
→ Launch ZYRA

------------------------------------------------------------
DEV / MAIN WORKFLOW
------------------------------------------------------------

Build Feature
      │
      ▼
    DEV
      │
      ▼
  Testing
      │
      ▼
   Merge
      │
      ▼
    MAIN
      │
      ▼
  Publish
      │
      ▼
Apple Review + Google Review
      │
      ▼
Users Receive Update

------------------------------------------------------------
ADMIN ROLE CHECK FLOW
------------------------------------------------------------

User Logs In
      │
      ▼
  Supabase
      │
      ▼
Check Role
      │
    ┌─┴─────┐
   YES      NO
    │        │
    ▼        ▼
Show      Hide
Developer  Developer
Button     Button

------------------------------------------------------------
MONEY FLOW
------------------------------------------------------------

User → Stripe → ZYRA LTD → Business Bank

------------------------------------------------------------
PHOTO STORAGE FLOW
------------------------------------------------------------

User Uploads Photo
      │
      ▼
  ZYRA App
      │
      ▼
Supabase Storage
      │
      ▼
  Photo Saved
      │
      ▼
Displayed In ZYRA
