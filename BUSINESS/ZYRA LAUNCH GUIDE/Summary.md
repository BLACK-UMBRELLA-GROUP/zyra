FEATURE NAME
ZYRA LAUNCH GUIDE
Group: 8 — Development

============================================================
SUMMARY
============================================================

Purpose:
End-to-end development, business, launch and operational
guide for ZYRA.

Note:
Some status information in this file may be outdated.
Update as milestones are reached.

Owns:
• Development workflow
• Launch process
• Business setup
• Infrastructure
• Dev/Main workflow
• Ownership
• Marketing
• Legal overview

------------------------------------------------------------
DEVELOPMENT & RELEASE PROCESS
------------------------------------------------------------

STAGE 1 — BUILD ZYRA
1. Create ZYRA in Lovable.
2. Connect GitHub.
3. Build every screen.
4. Build every feature.
5. Test everything.
6. Reach a stable launch-ready version.

Current Structure:
ZYRA
│
├── Lovable
│
└── GitHub
    ├── DEV
    └── MAIN

------------------------------------------------------------
STAGE 2 — BACKEND SERVICES
------------------------------------------------------------

7.  Create Supabase
8.  Connect Supabase
9.  Create Stripe
10. Connect Stripe
11. Create Firebase
12. Connect Firebase

Purpose:
• User accounts
• Profiles
• Photos
• Messages
• Guardian data
• Notifications
• Payments

------------------------------------------------------------
STAGE 3 — BUSINESS SETUP
------------------------------------------------------------

13. Register ZYRA LTD
14. Open Business Bank
15. Purchase zyra.app
16. Create Google Workspace
17. Create Legal Documents
18. Purchase Insurance

------------------------------------------------------------
STAGE 4 — APP STORE RELEASE
------------------------------------------------------------

19. Apple Developer Account
20. Google Play Developer Account
21. Build Release Version
22. Submit to Apple
23. Submit to Google
24. Launch ZYRA

------------------------------------------------------------
DEV / MAIN WORKFLOW
------------------------------------------------------------

DEV Branch Purpose:
• New Features
• Experiments
• Testing
• Bug Fixes

MAIN Branch Purpose:
• Stable Version
• Production Release
• Published Version

Workflow:
Build Feature → DEV → Testing → Merge → MAIN
→ Publish → Apple Review → Google Review
→ Users Receive Update

Rules:
• Users never receive DEV automatically.
• Merging DEV → MAIN does NOT update users.
• Users only receive updates after a new App Store /
  Play Store release.

------------------------------------------------------------
ADMIN / DEVELOPER SYSTEM
------------------------------------------------------------

User Roles:
• User
• Guardian
• Admin

Stored inside Supabase.

Developer Button Visibility:
| Role  | Visible |
|-------|---------|
| User  | ❌      |
| Guardian  | ❌      |
| Admin | ✅      |

The App Store version contains the Developer system,
but only Admin accounts can see or access it.

------------------------------------------------------------
ZYRA ECOSYSTEM
------------------------------------------------------------

| Service          | Purpose                          | Cost              |
|------------------|----------------------------------|-------------------|
| Lovable          | Build the application            | Current plan      |
| GitHub           | Version control and backups      | Free              |
| Supabase         | Accounts, profiles, auth         | Free → ~£20+/mo   |
| Supabase Storage | Profile photos                   | Included          |
| Supabase DB      | Messaging                        | Included          |
| Firebase         | Push notifications               | Free tier         |
| Stripe           | Subscriptions and payments       | Per transaction   |
| Companies House  | Register ZYRA LTD               | ~£50              |
| Starling/Monzo   | Business bank account            | Free              |
| zyra.app         | Domain                           | ~£10-£50/year     |
| Google Workspace | Business email                   | Monthly           |
| Apple App Store  | iPhone app                       | ~$99/year         |
| Google Play      | Android app                      | ~$25 one-time     |
| Cyber Insurance  | Protect against cyber incidents  | TBC               |

Business Emails:
• support@zyra.app
• legal@zyra.app
• hello@zyra.app

------------------------------------------------------------
HOW EVERYTHING CONNECTS
------------------------------------------------------------

Users
↓
ZYRA App
├── Lovable
├── GitHub
├── Supabase (Users, Profiles, Photos, Messages, Roles, Guardians)
├── Firebase (Notifications)
├── Stripe (Payments)
├── Business Bank
└── Apple & Google

------------------------------------------------------------
PHOTO STORAGE PROCESS
------------------------------------------------------------

User Uploads Photo → ZYRA App → Supabase Storage
→ Photo Saved → Displayed In ZYRA

Example:
5,000 Users × 5 Photos = 25,000 Photos

Supabase automatically manages:
• Storage
• Backups
• Retrieval
• Delivery

Upgrade storage plan as ZYRA grows.
No manual server management required.

------------------------------------------------------------
OWNERSHIP & INTELLECTUAL PROPERTY
------------------------------------------------------------

Own yourself:
✅ GitHub
✅ Supabase
✅ Stripe
✅ Domain
✅ Business Email

If hiring freelancers:
Always obtain written Intellectual Property transfer.

Recommended:
• Trademark ZYRA
• Trademark Logo

Usually NOT required:
• Patent

Rules:
✅ Use your own images
✅ Use licensed images
✅ Use licensed icons
❌ Never use random Google images
❌ Never copy competitor wording

------------------------------------------------------------
DOMAIN STRATEGY
------------------------------------------------------------

Main: zyra.app
Recommended additionally:
• zyra.co.uk
• zyra.uk
• zyra.com

Redirect every additional domain to zyra.app.

------------------------------------------------------------
LEGAL
------------------------------------------------------------

Required:
• Privacy Policy
• Terms & Conditions
• Cookie Policy
• GDPR Compliance
• Community Guidelines
• Refund Policy
• Copyright Notice

Recommended:
• Trademark registration for ZYRA
• Trademark registration for Logo

------------------------------------------------------------
INSURANCE
------------------------------------------------------------

Cyber Insurance
• Protects against data breaches, hacks, ransomware.

Professional Indemnity
• Protects against legal claims.

Directors & Officers
• Protects company directors.

------------------------------------------------------------
COMPANY & FINANCE
------------------------------------------------------------

Company: ZYRA LTD

Money Flow:
User → Stripe → ZYRA LTD → Business Bank

Tax & Accounting Requirements:
• Corporation Tax
• Annual Accounts
• Confirmation Statement

Recommended: Accountant (~£300-£1,500/year)

------------------------------------------------------------
WEBSITE
------------------------------------------------------------

Main: zyra.app

Recommended Pages:
• Home
• Features
• Pricing
• About
• Contact
• Privacy Policy
• Terms
• Support

------------------------------------------------------------
SECURITY
------------------------------------------------------------

Essential:
• Strong Password Rules
• Email Verification
• Database Security
• Encrypted Connections
• Backups
• Account Recovery

Future:
• Two-Factor Authentication
• AI Moderation
• Fraud Detection
• Device Monitoring

------------------------------------------------------------
MARKETING
------------------------------------------------------------

Organic:
• TikTok
• Instagram Reels
• Facebook
• YouTube Shorts
• X
• Blog
• Referral Programme
• Mosque Outreach
• Community Partnerships

Paid:
• Facebook Ads
• Instagram Ads
• TikTok Ads
• Google Ads

Influencer Marketing:
• Muslim Creators
• Marriage Coaches
• Islamic Educators
• Community Pages

------------------------------------------------------------
APPROXIMATE RUNNING COSTS
------------------------------------------------------------

| Stage         | Monthly Cost       |
|---------------|--------------------|
| Building      | £0 - £30           |
| Small Launch  | £30 - £75          |
| Growing App   | £75 - £250+        |
| Large App     | £250+              |
| Marketing     | £0 - £1,000+       |

------------------------------------------------------------
CURRENT STATUS
------------------------------------------------------------

| Item                    | Status       |
|-------------------------|--------------|
| Lovable                 | ✅ Done      |
| GitHub                  | ✅ Done      |
| DEV Branch              | ✅ Done      |
| MAIN Branch             | ✅ Done      |
| Admin Permission System | ✅ Planned   |
| Supabase                | 🔜 Next      |
| Stripe                  | 🔜 Future    |
| Firebase                | 🔜 Future    |
| Company                 | 🔜 Near Launch|
| Domain                  | 🔜 Near Launch|
| Business Bank           | 🔜 Near Launch|
| Legal                   | 🔜 Near Launch|
| Insurance               | 🔜 Near Launch|
| Apple Developer         | 🔜 Launch    |
| Google Play Developer   | 🔜 Launch    |

============================================================
APPROVED TO-DO LIST
============================================================
• Create and connect Supabase.
• Design production database for:
  - Users
  - Profiles
  - Photos
  - Messages
  - Guardians
  - User Roles
  - Proposal Tracker
  - Referrals
  - Subscriptions
  - Future AI Features
