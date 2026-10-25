---
id: DOC-ZYRA-9026
type: REPORT
status: CURRENT
feature: REPORTS
purpose: ZYRA release-readiness review
links: []
owner: ZYRA chat
---

# ZYRA release-readiness review

**Date:** 4 October 2026 · **Version:** V1 · **Project:** ZYRA / Black Umbrella Group  
**Prepared by:** Codex, ZYRA FINAL REALEASE  
**Authority:** Founder request for deep research and coordination, not implementation or release approval  
**Overall result:** **NOT READY FOR PUBLIC MEMBER RELEASE on the evidence available**  
**Tracking:** Supplementary evidence for **OA-AIOS-392**, with technical remediation under **OA-ZYRA-305** and the specialist actions identified below. This report creates no duplicate action identifiers and closes none.  
**Verification:** Read-only evidence review, current primary-source research, targeted source checks and named-chat status requests. Not a penetration test, legal certification, fresh end-to-end test or fresh store-console inspection. Internal verification is not Founder acceptance.

## Readout

ZYRA has substantial implemented UI, passing local tests and local iPhone delivery evidence. It does not yet have a verified, safe ordinary-member journey from registration through identity verification, funded membership, discovery, communication, cancellation and deletion on the exact public-release artifact.

The immediate blockers are three critical backend findings, an ordinary-user developer override, unfinished identity and membership authority, incomplete photo/privacy and moderation evidence, unresolved operator/legal requirements, and public website inconsistencies. Store approval and production recovery evidence are also missing. More marketing automation will not resolve these blockers.

The October 3 full-app audit records **61 finding groups: 3 critical, 23 high, 30 medium, 2 low and 3 informational**. The critical findings concern safety-report deletion, historical Main Guardian chat access and photo-path ownership. The audit established risky catalog/code paths; it did **not** establish that real member content was accessed or an exploit occurred. On October 4, **ZYRA APP BUILD** explicitly confirmed that its newest signup amendment did not repair or close F01–F07/F19 and that it had no newer verified repair receipts for them.

### Evidence limits

- Local source and records were reviewed without running Git, entering the prohibited private-key tree, changing member data, applying migrations, altering accounts or submitting a build.
- Store/legal requirements were researched against current primary sources on October 4. Rules still need checking against the eventual platform, account type, country and submitted binary.
- The live website was checked read-only. Its homepage advertises Basic at £9.99 once; `/terms` and `/delete-account` return homepage content. This does not prove an HTTP redirect. The website notice is website-specific, not a complete member-app notice.
- Historical TestFlight, provider, account-security and database observations are labelled as historical. They are not silently promoted to today's live state.
- The app and admin chats may be changing files for separately authorised work. This is a point-in-time report, not a freeze of their work.
- Six-country legal coverage below is an applicability screen, not completed country clearance. Qualified advice is needed for unresolved jurisdiction-specific issues.

## 1. Four different release gates

| Gate | What it permits | Evidence needed | Current conclusion |
|---|---|---|---|
| Local design preview | Founder examines synthetic/local UI | Isolation, safe credentials, honest preview labelling | Available in parts; not real-member readiness |
| External synthetic TestFlight | Invited people examine the approved demo build | Current Apple beta approval, working review access, isolated demo data, no misleading live functionality | Last retained external build status is Waiting for Review; current status unknown |
| Real-member beta | People supply real photos and matrimonial information | Applicable privacy/safety duties, admission, authorisation, photo protection, moderation, support and rollback | Not cleared; current critical findings and real-photo hold remain |
| Public paid launch | Ordinary members can discover, pay, communicate and obtain support | All applicable gates below, exact release artifact and store approval, Founder GO and post-verification | Not ready |

Synthetic testing is not an exemption from Apple rules. Private real-data testing is not an exemption from privacy or safety duties. The standing Founder restriction remains: **external testers must not upload real photos until the approved photo work has shipped and been proven**. This review does not remove that hold. First external TestFlight testing requires beta review; beta approval is not public App Store approval. [Apple external-testing process](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/)

## 2. Current product contract—not the historical chat proposals

The authority is [Pricing V6](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/BUSINESS/ZYRA PRICING/ZYRA_PRICING_CURRENT_VERSION_V6.md>), dated October 4:

- Seeker Basic and Guardian Basic: **£4.99 once per role**, no monthly subscription. Neither is a free product. Selecting Basic is not proof the fee was paid.
- Seeker One: **£29.99/month**; ordinary contract retains one 14-day trial per verified person for life. Guardian One: **£19.99/month**, no trial.
- Family: independently configurable 0–10 Seeker and 0–10 Guardian places; 0/0 invalid. The saving starts at three places and caps at 40%. The formula yields 120 valid configurations; that does **not** establish a need for 120 separate store products.
- Both roles require their own membership or Family place. Proven verified-person linkage can avoid repeating identity verification; payment never grants a Guardian relationship or historical-chat permission.
- Additional Guardian is a relationship role under Guardian One, **not a separate retention SKU or allowance per link**.
- Protected £4.99 first-month Seeker and £4.99-per-person Family comparisons are **design previews**. Their ordinary trial/introductory eligibility, dual-role treatment and store operation remain unresolved. They must not be advertised as live offers.
- Intended phase-one markets are **UK, US, Canada, Australia, New Zealand and UAE**. Intent is not store availability, legal clearance or a decision to launch all six simultaneously. Saudi Arabia is not in this approved list.

Basic ad support is also a local rehearsal, not an approved live ad provider. The earlier no-Basic/paid-only server contract must be reconciled before activation. Retention discounts remain approved design requiring commercial/store feasibility and separate implementation approval; they are **not a launch prerequisite**. See [retention feasibility package](</Users/shakeelahmad/Developer/DEVELOPMENT/BLACK UMBRELLA GROUP/SYSTEM/RESOURCES/REPORTS/ZYRA_RETENTION_COMMERCIAL_AND_STORE_FEASIBILITY_2026-09-27_V1.md>). **Tracking: OA-ZYRA-253/293/303; OA-AIOS-392.**

## 3. Release blockers and the proof required to close them

Each row maps to existing actions. “Unproven” means no sufficient receipt was found, not that failure was reproduced in this review.

| Priority / finding | Available evidence | Release acceptance evidence | Owner / existing action |
|---|---|---|---|
| Critical: safety-report loss on deletion | Audit F01: account deletion/cascades can remove reports about or by the deleted person | Lawful, bounded retention design; deletion tests preserve required investigation records without retaining everything indefinitely; rights/retention notice matches | ZYRA APP BUILD + ZYRA ADMIN · OA-ZYRA-305; OA-AIOS-392 REC-013 |
| Critical: old chat visibility for current Main Guardian | F02: current Main branch is not sufficiently bounded to historical attempts/authority | Positive and negative tests across appointment/removal, ended attempts, reinstatement and devices; optional past summaries must not imply old-message access | ZYRA APP BUILD · OA-ZYRA-290/291/305 |
| Critical: foreign photo-path references | F03: owner-row rules do not prove referenced object ownership | Server-enforced owner/object binding; arbitrary known foreign paths rejected; authorised own-photo and migration cases remain valid | ZYRA APP BUILD · OA-ZYRA-302/305 |
| High: developer authority in ordinary flows | F19 source spot-check: default Guardian override can bypass ordinary Main requirements | Demo/founder state cannot authorise ordinary accounts; release and remote-server denial tests; no email-only admin privilege | ZYRA APP BUILD · OA-ZYRA-286/305 |
| High: compatibility and credit authority | F04–F07: raw score/progress exposure and server Plus/credit gaps | No pre-unlock sensitive result oracle; atomic, idempotent spending; repeat/concurrent/retry calls cannot double-charge or bypass entitlement | ZYRA APP BUILD · OA-ZYRA-193/192/285/305 |
| High: real identity/admission not proven | Real provider unavailable/held; UI verification is not provider proof | Actual provider integration, explicit applicable consent, verified-person binding, adult admission, refusal/retry/recovery; server prevents early publication | ZYRA APP BUILD + ZYRA ADMIN · OA-ZYRA-263/266/303 |
| High: payments do not yet prove funded access | Basic fallback, Family grace/role hydration and linked-Seeker entitlement issues | Store-backed receipts, server lifecycle authority and restored Basic reconciliation; no failed/unpaid purchase creates access | ZYRA APP BUILD · OA-ZYRA-253/293/305 |
| High: uploads and moderation incomplete | Client processing is proven in parts; trusted upload limits/quarantine and ordinary stored-object privacy remain open | Uploaded/downloaded object privacy test, trusted ownership/MIME/size/processing controls, moderation before unsafe exposure, batch/retry recovery | ZYRA APP BUILD · OA-ZYRA-266/302/303/305 |
| High: safety operations | Moderation queue ownership/triage/resolution lacks accepted operational evidence | Working report/block flows, published rules/contact, staffed escalation, evidence retention, sanctions, appeals and incident rehearsals | ZYRA APP BUILD + ZYRA ADMIN · OA-ZYRA-237/263/266/305; OA-AIOS-392 REC-013 |
| High: notification and message boundaries | F27–F28: copied private-message snippets and broad notification updates; staged message policy risks | Minimise secondary message content; restrict server-authored fields; ordinary/Guardian denial tests and idempotent retries | ZYRA APP BUILD · OA-ZYRA-231/296/298/305 |
| High: operator, privacy and legal readiness | Existing company/controller, ICO, terms, DPIA and market actions remain open; no fresh acceptance packet | Identified operator/controller, applicable registrations, lawful bases, consent, notices, retention and safety assessments; executable support/rights routes | ZYRA ADMIN · OA-AIOS-381/386/392 |
| High: misleading/broken public website | Current Basic price conflicts; terms/deletion routes show homepage | Agreed prices/offer status, real terms/privacy/support/deletion destinations, tested contact/consent flow | ZYRA MARKETING, coordinating website work · OA-AIOS-390/392; OA-ZYRA-253/293 |
| High: release artifact and compliance | Local builds/test receipts exist; latest first-photo build not installed; current store state unmeasured | Exact signed archive/build identity, complete runtime/privacy/accessibility checks, current store decisions and Founder acceptance | ZYRA APP BUILD · OA-ZYRA-257/268/286/303/304/305 |
| High: resilience and privileged access | No fresh restore rehearsal; database minor and dashboard security findings remain open | Tested database plus photo-object restore, monitored failures, rollback/forward repair, privileged account and recovery evidence | ZYRA APP BUILD + ZYRA ADMIN · OA-ZYRA-276/297/305; OA-AIOS-379/383/392 |

The full [October 3 app audit](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/DOCUMENTS/ZYRA_FULL_APP_AUDIT_HANDOVER_CURRENT_VERSION_V1.md>) remains the detailed technical source. Cosmetic findings can be triaged; authorisation, privacy, money and safety failures cannot be marked complete because the screen looks finished.

### What the passing tests actually prove

The latest [first-photo receipt](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/RESOURCES/REVIEWS/SIGNUP_FIRST_PHOTO_2026-10-04_VERIFICATION.json>) records **2,672 functional passes, 2 existing skips, zero failures**, clean analysis, three targeted real-font layout checks and 18 candidate captures. Its signed local iOS build is ready, but installation/native launch remains pending phone unlock. Earlier October 4 Family-preview installation evidence belongs to an earlier artifact. Neither is an App Store update or an accepted ordinary-user/payment/IDV test.

The October 3 broad visual run recorded 124 failures out of 335 tests. They may include outdated approved baselines; they are not automatically 124 production defects. They require disposition, not blanket baseline promotion. Native VoiceOver/TalkBack, large text, touch targets, contrast, small screens and poor-network recovery still need accepted evidence. **OA-ZYRA-257/286/303/304/305.**

## 4. Photo privacy, authentication and infrastructure

### Photos

The approved processor caps both axes at 1440 pixels, applies orientation and produces fresh quality-85 JPEGs without unnecessary metadata. Processing failure must stop upload; original-file fallback is prohibited. Three supplied GPS-positive iPhone HEIC fixtures lost their metadata through ZYRA's processor. That is useful **processor proof**, not an ordinary signed-in upload/download or Android proof. [Photo handover](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/DOCUMENTS/ZYRA_PROFILE_PHOTO_UPLOAD_PRIVACY_AND_SIZE_HANDOVER_CURRENT_VERSION_V2.md>)

Remaining acceptance: ordinary iPhone upload → stored-object download → metadata/dimension check; Android gallery processing; high-megapixel/low-memory device; portrait/landscape/panorama; cancellation and failures; safe replacement/batch recovery. An emulator fixture can check its processing path, but cannot prove a real Android picker/camera/OEM or low-memory result.

Seed maintenance remains separate: JPEGs under new paths, verified uploads, all affected database references updated transactionally, Browse checked, old files retired only after verification. Bucket limits follow measured output, seed conversion and older-client compatibility—not before. Do not assume old objects are disposable or publish capacity forecasts from a few fixtures. **OA-ZYRA-302/303/305; capacity OA-ZYRA-276.**

### Authentication and keys

September 24 receipts confirm migration of the client to the existing publishable key and restored-session refresh on a real device. They do not prove every login method, every installed client or current review-build parity. The bounded tooling scan found no active legacy privileged-key consumer; it was not a universal account/CI inventory. [Key-migration handover](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/DOCUMENTS/ZYRA_SUPABASE_KEY_MIGRATION_HANDOVER_CURRENT_VERSION_V1.md>)

**Do not disable legacy keys or rotate the JWT secret from this review.** That remains a separate exact-action gate after replacement delivery and consumer checks. Test ordinary Apple/Google sign-in and verified recovery-email OTP; email is a recovery method, not ordinary email/password signup. Private email relay/account linking, role switching, restart/session renewal, revoked sessions and deletion must work without founder/dev shortcuts. [Current authentication source](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/lib/services/zyra_auth.dart>) · **OA-AIOS-383; OA-ZYRA-286/303/305.**

### Infrastructure and recovery

- Apply the production checklist to actual configuration: row-level security, privileged functions, authentication/email capacity, rate limiting, security advisories, least privilege and operational monitoring. Free-project inactivity and backups need an explicit availability plan. No automatic upgrade/purchase is authorised. [Supabase production checklist](https://supabase.com/docs/guides/deployment/going-into-prod)
- Database backup does **not** include Storage photo objects. Restore rehearsal must cover both, with encryption/access restrictions and deletion-aware retention. Define acceptable data loss and recovery time, then demonstrate them. [Supabase backup scope](https://supabase.com/docs/guides/platform/backups)
- The October 3 record reports an older PostgreSQL minor. Current live version is not remeasured here. Assess the security update and compatibility before a scoped, separately approved upgrade. [Supabase security-release notes](https://supabase.com/changelog/postgres-15-19-17-11-breaking-changes)
- Check device credential/cache storage and backup exclusions. Debug-key Android signing, ordinary backup-eligible auth storage and unverified aggregate privacy manifests are still documented gaps. Use mobile security standards as a verification framework, not a claim of certification. [OWASP MASVS](https://mas.owasp.org/MASVS/)
- Secure privileged email, developer/store accounts, domain, backend and admin dashboard with tested primary/backup factors and recovery. An admin YubiKey gate does not repair app authorisation or make a site attack-proof. Preserve service identities and emergency recovery before enforcing policy. **OA-AIOS-379; OA-ZYRA-268/286/297/305.**

## 5. Apple release requirements

**Common policy gates.** Member content needs filtering, reporting, timely handling, blocking and a reachable contact. Reviewers need complete access; the special alternative demo mode described for legal/security constraints requires Apple's prior approval. Digital memberships normally use IAP subject to storefront exceptions, not a blanket external-checkout assumption. A Family name is not an enterprise exemption. Login choices must satisfy Apple's privacy-equivalent-login rule where applicable. Section 5.1.1(ix) directs apps requiring sensitive information to use the service provider's legal-entity submission rather than an individual's; establish applicability and seller identity. Marriage-first positioning alone does not prove meaningful differentiation in a saturated category. [Apple review guidelines](https://developer.apple.com/app-store/review/guidelines/)

The concrete submission checklist is:

1. **Working ordinary and reviewer flows:** complete functionality, available backend, non-expiring access instructions, both roles and funded/locked states. Do not expect Apple to infer a one-field tester code as a username/password. [Review preparation](https://developer.apple.com/app-store/review/)
2. **Seller and commerce:** correct legal seller, active agreements, required bank/tax details, sandbox and production product configuration. First IAP submission needs the applicable app-version submission. [IAP setup](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/) · [Submitting IAP](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/)
3. **Subscriptions:** actual local price, duration, renewal and trial/offer terms; privacy/terms links; restore and subscription-management paths. Test purchase cancellation, pending/failed payment, refunds, grace, expiry, duplicate events, Family transfer and overlap. A calculated price is not a store product. [Apple subscriptions](https://developer.apple.com/app-store/subscriptions/)
4. **Deletion:** initiation inside the app, not only deactivation or a support email; delete associated personal data, including shared photos/content, except justified legally required retention. Disclose any processing timeline and confirm completion. Warn that account deletion does not itself cancel Apple billing. Apply Sign in with Apple token revocation where relevant. Apple does not universally impose Google's separate public web-deletion requirement. [Apple account-deletion guidance](https://developer.apple.com/support/offering-account-deletion-in-your-app)
5. **Privacy:** accurate App Privacy answers for app and SDK collection, including sensitive religious/ethnic information and linkage; privacy notice agrees with actual processing. Advertising/tracking needs a separate applicability check—ATT is not required merely because an app has analytics. [Privacy labels](https://developer.apple.com/app-store/app-privacy-details/) · [Tracking rules](https://developer.apple.com/app-store/user-privacy-and-data-use/)
6. **Archive inspection:** aggregate privacy manifests, listed SDK signatures/manifests and required-reason APIs; inspect the archived binary rather than only repository files. [SDK requirements](https://developer.apple.com/support/third-party-SDK-requirements/) · [Required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
7. **Toolchain:** uploads require Xcode 26/iOS 26 SDK or later from April 28, 2026. This is a build-SDK requirement, not a requirement to make iOS 26 the minimum supported OS. [Apple dated requirement](https://developer.apple.com/news/upcoming-requirements/?id=04282026a)
8. **Metadata:** current age-rating questionnaire, real content/age-access controls, app screenshots, support URLs, truthful descriptions and encryption/export declarations. Decide iPhone-only versus supported iPad before submission; the source currently includes both device families. [Age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating) · [Export compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/)
9. **Regional duties:** EU trader declarations if distributing in the EU; the UK is not an EU country. The six intended markets do not themselves include EU distribution. [Apple EU trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements)

Payment/steering permissions must be checked by storefront. Apple permits external purchase links/calls to action in the US storefront without the relevant link entitlement; that is not permission for the other five intended markets. Do not infer an approved external checkout design from this exception. [Apple storefront payment rules](https://developer.apple.com/app-store/review/guidelines/)

**Recorded rejection:** external build 1.0.0 (4) was rejected September 20 under 2.1(a), Information Needed, because the reviewer lacked usable full-access sign-in information. A corrected external build 5 was uploaded and submitted September 24; retained evidence says **Waiting for Review**, not approved. An older handover header still says upload pending, conflicting with its completed body and submission receipt. Obtain current App Store Connect status and correspondence before deciding whether any further build is needed. Internal and external artifacts sharing a build number are not interchangeable proof. [External-access handover](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/DOCUMENTS/ZYRA_EXTERNAL_TESTER_ACCESS_HANDOVER_CURRENT_VERSION_V2.md>) · [Apple status definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/app-and-submission-statuses/)

**Tracking:** OA-ZYRA-253/257/268/286/303/304/305; OA-AIOS-386/392. No upload or resubmission is authorised here.

## 6. Android / Google Play—conditional on launch scope

Do not hold an explicitly iPhone-only first launch for unfinished Android, but do not advertise Android availability without its gate:

- Correct organisation/account verification, production signing and Play App Signing/OAuth configuration. The current release Gradle configuration uses debug signing. If a qualifying new personal account is used, the 12-testers/14-continuous-days closed-test and production-access requirements apply; this is not universal for every developer account. [Account verification](https://support.google.com/googleplay/android-developer/answer/13628312?hl=en) · [New-personal-account testing](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en-en)
- New apps/updates target Android 16/API 36 from August 31, 2026. Play Billing Library 8+ is the current deadline unless an applicable extension was granted. Inspect the packaged dependencies. [Target API](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en-EN) · [Billing deprecation](https://developer.android.com/google/play/billing/deprecation-faq)
- Verify 16 KB page compatibility of Flutter and native libraries. Google's current page-size document states update enforcement from February 1, 2027; avoid recycling an older blog deadline as the complete current rule. [Current page-size requirements](https://developer.android.com/guide/practices/page-sizes)
- Complete Data Safety/privacy disclosures and both in-app and external web account-deletion routes. Internal-testing-only treatment differs from closed/open/production tracks. [Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en) · [Deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)
- Profile-photo selection normally uses the system picker; it does not justify broad gallery permissions. [Photo-permission policy](https://support.google.com/googleplay/android-developer/answer/14115180?hl=en-CA)
- Core matchmaking apps must enable Play Console's **Restrict Minor Access** functionality; an in-app DOB question alone does not fulfil this store requirement. Social/dating child-safety duties still apply to an adults-only app: published standards, in-app reporting, appropriate CSAM handling and a child-safety contact/declaration. [Age restrictions](https://support.google.com/googleplay/android-developer/answer/16302250?hl=en) · [Child safety](https://support.google.com/googleplay/android-developer/answer/14747720?hl=en)
- Working UGC safety, applicable Play Billing and reusable reviewer access without inaccessible OTP/location dependencies. [UGC policy](https://support.google.com/googleplay/android-developer/answer/9876937?hl=en) · [Payments policy](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en) · [Reviewer access](https://support.google.com/googleplay/android-developer/answer/15748846?hl=en)

Google's optional Billing Choice program is available in the UK from June 30, 2026 and Australia from September 30, 2026. It requires enrollment, applicable APIs and a choice alongside Play Billing for alternative in-app billing or external web links. US alternatives use separate programs. Canada, New Zealand and UAE are not listed in these program markets; keep ordinary store billing unless an applicable exception is established. This is a feasibility option, not an authorised integration or a fee-free route. [Google Billing Choice](https://support.google.com/googleplay/android-developer/answer/17161464?hl=en)

**Tracking:** OA-ZYRA-268/286/302/303/304/305; OA-AIOS-392 REC-013.

## 7. Privacy, business and safety readiness

### UK baseline

**Operator and registrations.** Identify the real contracting service provider and controller now, including address/contact and processor responsibilities. UK law does not require every business to incorporate: sole trading is possible. Apple's sensitive-service seller rule, banking and the Founder's chosen structure still need resolving. Assess/pay the ICO fee or record a genuine exemption; this is not a GDPR certificate. Relevant duties can already apply to current real-data testing. [Sole trader guidance](https://www.gov.uk/become-sole-trader) · [ICO applicability](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/personal-information-what-is-it/who-does-the-uk-gdpr-apply-to/) · [ICO fee](https://ico.org.uk/for-organisations/data-protection-fee/data-protection-fee/)

**Data design.** Map account details, DOB, religious/ethnic answers, inferred compatibility, photos, Guardian links, messages, reports, purchases, notifications, device logs and verification evidence. Establish an Article 6 lawful basis and an Article 9 condition where special-category data is processed; contract or legitimate interests alone do not satisfy Article 9. If explicit consent is used, make it purpose-specific, evidenced and withdrawable—not hidden in generic terms. [Special-category basis](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/a-guide-to-lawful-basis/special-category-data/) · [Article 9 conditions](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/lawful-basis/special-category-data/what-are-the-conditions-for-processing/)

Complete a DPIA addressing sensitive matching, guardian coercion, stalking/location exposure, access after relationship changes, IDV/biometrics, exclusion and vulnerable people. Whether legally mandatory depends on the risk criteria; low user count is not automatic exemption. Record processors/contracts, international transfers, retention and any need for a DPO. A DPO is not universally required for every startup. [DPIA criteria](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/data-protection-impact-assessments-dpias/when-do-we-need-to-do-a-dpia/) · [Processor contracts](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/guide-to-accountability-and-governance/contracts/) · [Transfers](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/international-transfers/a-guide-to-international-transfers/what-is-an-international-transfer-of-personal-information/) · [DPO test](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/guide-to-accountability-and-governance/data-protection-officers/)

**Rights and response.** Publish accurate member and website notices, including indirect Guardian information, profiling, recipients, retention and rights. Operate access/correction/export/deletion and consent withdrawal; erasure exceptions must be justified, not used to retain everything. Keep investigation records without the current cascade loss. New UK data-protection complaint duties have applied since June 19, 2026, including a clear complaint route and acknowledgement within 30 days. Have a breach assessment/escalation process with 72-hour ICO notification where required. [Right to be informed](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/individual-rights/individual-rights/right-to-be-informed/) · [Erasure](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/individual-rights/individual-rights/right-to-erasure/) · [New complaints duty](https://ico.org.uk/about-the-ico/media-centre/news-and-blogs/2026/06/new-data-protection-complaints-law-now-in-force/) · [Breach reporting](https://ico.org.uk/for-organisations/report-a-breach/personal-data-breach)

**Online safety.** Assess UK Online Safety Act scope for the actual profile/message service; matrimonial branding is not an exemption. Document illegal-content risk and children's access, moderation, complaints and safety responses. Merely saying 18+ or asking DOB is not conclusive proof children cannot access it. From April 7, 2026, relevant providers have a duty to report detected, previously unreported CSEA content under the applicable rules; that is not a blanket duty to proactively detect every item. Establish the correct legal reporting route and trained escalation. New-service assessment windows do not justify launching without protections. [Dating/social-discovery guidance](https://www.ofcom.org.uk/online-safety/illegal-and-harmful-content/dating-and-social-discovery-know-the-online-safety-risks-rules-and-how-to-comply) · [Children's access](https://www.ofcom.org.uk/online-safety/illegal-and-harmful-content/childrens-access-assessment-duties-under-the-online-safety-act) · [Illegal-content compliance](https://www.ofcom.org.uk/online-safety/illegal-and-harmful-content/check-how-to-comply-with-the-illegal-content-rules) · [CSEA reporting duty](https://www.ofcom.org.uk/online-safety/illegal-and-harmful-content/duty-to-report-child-sexual-exploitation-and-abuse-csea-content-know-the-rules-and-how-to-comply)

**Consumer terms.** Show actual total/local price, recurring interval, renewal, trial conversion, cancellation and refund information before purchase. Distinguish service early-start rules from digital-content withdrawal exceptions; do not declare that all app purchases waive statutory rights. The new DMCCA subscription-contract regime is anticipated for spring 2027, not already in force on this review date; existing consumer obligations still apply. [Online selling](https://www.gov.uk/online-and-distance-selling-for-businesses/online-selling) · [Service early start](https://www.legislation.gov.uk/uksi/2013/3134/regulation/36) · [Digital-content rules](https://www.legislation.gov.uk/uksi/2013/3134/regulation/37) · [Government implementation response](https://www.gov.uk/government/consultations/consultation-on-the-implementation-of-the-new-subscription-contracts-regime/outcome/government-response-to-consultation-on-the-implementation-of-the-new-subscription-contracts-regime-web-accessible-version)

**Tracking:** OA-AIOS-381/386/392 REC-006–013; OA-ZYRA-237/253/263/266/293/305.

### Intended markets: additional applicability screen

| Market | Additional checks before opening that market | Primary starting evidence |
|---|---|---|
| US | Federal/state recurring-billing rules; sensitive/biometric privacy and notices; age/actual-knowledge issues; state-specific applicability. Do not cite the vacated 2024 click-to-cancel rule as settled current law. | [FTC recurring subscriptions](https://consumer.ftc.gov/articles/getting-and-out-free-trials-auto-renewals-and-negative-option-subscriptions), [COPPA guidance](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions) |
| Canada | PIPEDA/provincial applicability, meaningful sensitive-data consent, cross-border handling and CASL marketing consent. | [Privacy Commissioner consent guidance](https://www.priv.gc.ca/en/privacy-topics/collecting-personal-information/consent/), [CRTC CASL](https://crtc.gc.ca/eng/com500/faq500.htm/) |
| Australia | Privacy Act small-business exceptions are conditional; consumer renewal/price accuracy; eSafety age-restricted-platform applicability to the actual service. | [OAIC small business](https://www.oaic.gov.au/privacy/privacy-guidance-for-organisations-and-government-agencies/organisations/small-business), [eSafety scope](https://www.esafety.gov.au/about-us/industry-regulation/social-media-age-restrictions/which-platforms-are-age-restricted), [ACCC subscription enforcement](https://www.accc.gov.au/media-release/court-finds-eharmony-engaged-in-misleading-conduct-in-relation-to-automatic-renewal-and-pricing-of-its-subscriptions) |
| New Zealand | Overseas-business applicability, privacy officer, indirect collection notices under IPP3A from May 2026, and biometric code if provider processing falls within it. | [IPP3A](https://www.privacy.org.nz/privacy-principles/3a/), [Biometric code](https://www.privacy.org.nz/privacy-principles/codes-of-practice/biometric-processing-privacy-code/) |
| UAE | Federal PDPL/possible free-zone regime, overseas-controller applicability, sensitive data, transfers, local consumer/service and advertising requirements. Do not assume UK documents or company registration alone clear the UAE. | [UAE data-protection overview](https://u.ae/en/about-the-uae/digital-uae/data/data-protection-laws) |

Saudi incorporation is separate from these six markets. If Saudi residents are admitted or targeted, assess PDPL, sensitive data, identity-document handling, transfers and the actual service/licensing requirements separately. **OA-AIOS-386/392; no jurisdiction has been certified by this review.** [SDAIA PDPL resources](https://dgp.sdaia.gov.sa/wps/portal/pdp/knowledgecenter/details/PDPLCP)

## 8. Marketing, website and brand readiness

**ZYRA MARKETING** returned a read-only October 4 status. Its local command centre exists, with three drafts and nine placeholder account rows. Publishing/connections are disabled. Blank rows do not prove accounts are absent; historical handles need ownership/security reconciliation, not duplicate signups.

It reproduced approval-control defects in temporary stores: account changes preserve old approval; budget changes retain budget approval; rechecking a published record can make it editable; media fingerprints are optional and not checked against actual media. The earlier implementation summary overstated these controls. Repair and authenticated approval are required before automated external execution, **not as a prerequisite for manual, Founder-approved launch communication**. [Marketing handover](</Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SYSTEM/DOCUMENTS/ZYRA_MARKETING_COMMAND_CENTRE_HANDOVER_CURRENT_VERSION_V1.md>) · **OA-ZYRA-301; OA-AIOS-379/392.**

Before directing campaign traffic:

- Resolve the live/local price disagreement and actual terms, privacy, support and deletion routes. Do not claim provider verification, Network, shared Circle, compatibility privacy/Plus or commerce as live until their owning gates pass. **OA-AIOS-390/392; OA-ZYRA-193/247/248/253/255/266/283/284/285/292/293/296/298/302/303/305.**
- Decide contact-only versus a managed waitlist. The present CTA opens email and the API is a closed stub, not an operating consent ledger. Keep service messages separate from optional marketing; implement consent/unsubscribe evidence if collecting a marketing list. [ICO electronic-marketing guidance](https://ico.org.uk/for-organisations/direct-marketing-and-privacy-and-electronic-communications/guidance-on-direct-marketing-using-electronic-mail/) · **OA-AIOS-381/390/392 REC-008.**
- Test rendered network/storage behaviour. Static absence of tracking code is not a runtime audit. Not every non-essential technology now requires a blanket banner: current UK exceptions are conditional, including qualifying statistical/appearance uses with notice/objection. Advertising/cross-service tracking needs its own valid consent assessment. [Current storage/access exceptions](https://ico.org.uk/for-organisations/direct-marketing-and-privacy-and-electronic-communications/guidance-on-the-use-of-storage-and-access-technologies/what-are-the-exceptions/) · **OA-AIOS-392 REC-006/011.**
- Clear the brand and relevant trademark classes before major exposure; secure owned domains, renewals and relevant handles with recovery/MFA. The August 20 preliminary research is recorded complete under **OA-AIOS-310**, but professional ZYRA clearance/filing and applicant work under **OA-AIOS-316** were not thereby completed. No fresh accepted clearance was found. A company name, domain or social handle is not trademark clearance, nor can registration guarantee nobody infringes. Do not buy every variation or paid verification badge without a reason. [UK trademark search](https://www.gov.uk/search-for-trademark) · **OA-AIOS-392 REC-001/003/004/005/014/015.**
- Prepare media rights/provenance and exact claim/country/channel checks. Inspect platform permissions for matrimonial/social-discovery advertising before spending; do not build sensitive religious/relationship targeting merely because the app stores those answers. **OA-ZYRA-301; OA-AIOS-392 REC-009–011.**

All-social-channel completion, a blue badge, automated publishing, video introductions, billing pause and retention promotions are **not inherently required for app release**. Decide their launch scope honestly rather than treating every future idea as a blocker.

## 9. Coordination and release evidence protocol

This chat coordinates readiness; it does not take over authorised app builds or self-approve another chat's work. **Only the Founder approves.** ChatGPT is bounded support; Fable/Claude has no active role.

| Chat | Accountability in the release packet | Status from this review |
|---|---|---|
| ZYRA APP BUILD | Technical findings, source/backend compatibility, ordinary-user tests, device/archive/store evidence | Returned explicit non-closure of F01–F07/F19; newest local test receipt reviewed |
| ZYRA ADMIN | Operator/legal/ICO/markets, support/moderation procedures, accounts/security, bank/tax, recovery, governed action filing | Evidence request sent; complete release packet not yet returned. Separate Founder-authorised AIOS cleanup is active |
| ZYRA MARKETING | Public claims, live website/consent, brand/social ownership, assets and exact campaign controls | Returned October 4 evidence; price/routes and approval-control gaps recorded |
| ZYRA FINAL REALEASE | Combined gates, dependencies, reconciliation, unresolved-evidence challenge and Founder readout | This report; no production execution |

For every claimed closure require: owning OA/finding; intended invariant; exact source/backend/artifact identity; test environment/date; positive and denial cases; receipts; dependencies and remaining holds; rollback/monitoring; internal verification distinct from **Founder GO → execution → post-verification → Founder acceptance**. “Implemented,” “installed,” “tests pass,” “Apple approved” and “Founder accepted” are different states.

A public-release packet must cover both Seeker and Guardian, Basic/One/Family funded and expired states, dual-role switching, linked permission changes, active/paused/ended Journeys, request duplication, report/block, notifications, purchases/restoration/transfer, account rights/deletion and poor-network/restart recovery. Optional held features must remain truly inaccessible server-side and be absent from public promises. Push delivery can be deferred only if accepted scope and fallback work; its existing action is **OA-ZYRA-254**. No new recurring automation is created by this report.

## 10. Recommendations for the existing master action

These are review recommendations, **PENDING FOUNDER where action needs approval**, not execution instructions. Labels below are local report references, not new register identifiers. Preserve OA-AIOS-392's existing numbering when reconciled.

| Report reference | Recommendation / priority / reason | Owner and tracking | Status |
|---|---|---|---|
| R-01 | Define platform/countries and mandatory feature scope first; prevents false “all done” claims | Founder + all three chats · OA-AIOS-392 DECISION-004/006, REC-013 | Decision pending |
| R-02 | Prepare narrow security containment/repair packages for F01–F07/F19 before broader real-data testing; highest harm | App Build/Admin · OA-ZYRA-305 with specialist OAs | No repair GO from this review |
| R-03 | Resolve IDV/provider admission, photo safety and moderation; prevent unsafe early publication | App Build/Admin · OA-ZYRA-237/263/266/302/303/305 | Open evidence gates |
| R-04 | Complete authoritative products, receipts and lifecycle; reconcile Basic, intro offers and Family dual-role/commercial feasibility | App Build/Admin · OA-ZYRA-253/293/303; OA-AIOS-392 REC-004/013 | Checkout/activation held |
| R-05 | Finalise actual operator/controller, market applicability, notices, lawful basis, DPIA, rights/support and safety assessments | Admin · OA-AIOS-381/386/392 REC-007/012/013 | Fresh packet pending |
| R-06 | Obtain exact current store status; reconcile stale checklist/runbook statements rather than repeat uploads | App Build/Admin · OA-ZYRA-286/305; OA-AIOS-392 REC-013 | Not freshly measured |
| R-07 | Rehearse ordinary flows and restore/recovery on the exact production candidate; disposition visual/accessibility findings | App Build/Admin · OA-ZYRA-257/268/276/286/297/303/304/305 | Not accepted |
| R-08 | Correct live website, protect brand/accounts and verify consent/claims/assets before campaign traffic | Marketing/Admin · OA-AIOS-310/316/390/392; OA-ZYRA-301 | Confirmed gaps / decisions pending |
| R-09 | Repair authenticated exact-action marketing controls before connecting automation; manual publishing remains an option | Marketing/Admin · OA-ZYRA-301; OA-AIOS-379/392 | Automation disabled |
| R-10 | Preserve holds: no key revocation, blanket migrations, original-photo fallback, unapproved offer substitution, baseline promotion or assumed Basic funding | App Build/Admin · OA-AIOS-383/392; OA-ZYRA-253/286/302/305 | Standing boundaries retained |
| R-11 | Separate initial narrow launch from future Android/country/automation/retention expansions; do not spend just to complete a checklist | Founder + owners · OA-AIOS-392 REC-010/013/015 | Scope recommendation only |

**Actions:** No new implementation actions are authorised. Existing separately approved work retains its own authority. Report/OA cross-reference reconciliation is documentary coordination, not deployment or closure; authoritative-register amendments must use one writer and the governed verification/extraction process.

## 11. Founder decisions—not all required immediately

| Decision | Recommended answer / alternatives | When needed / consequence of deferral |
|---|---|---|
| First release scope | Consider iPhone-first, one cleared market before all six; alternative simultaneous supported platforms/markets with their full evidence | Before products/campaign/store availability. No broad launch clearance while undecided |
| Operator and seller | Choose the actual entity/jurisdiction and reconcile controller, store and bank/tax identity; a company recommendation is not an incorporation instruction | Before agreements, payment and final notices. Keep onboarding/purchases held |
| Ordinary introductory policy | Decide whether current trial remains or a first-month offer replaces it; specify Family unique-person/dual-role rules | Before public copy or checkout. Preview remains preview |
| Repair authority | Review exact containment/fix/migration artifacts with tests, rollback and acceptance before GO | Before production changes. Critical findings remain release blockers |
| iPhone / iPad / Android | Match advertised and store device scope to accepted QA; remove unsupported targets only under an approved change | Before archive submission. Current binary scope cannot be assumed supported |
| Marketing destination | Contact-only or real managed waitlist; choose exact campaign countries/channels/assets later | Before traffic/list collection. Do not claim an operational waitlist or approved campaign |

**Risks:** RISK-1 critical privacy/safety exposure; RISK-2 high mistaken live entitlement/admission; RISK-3 high unlawful or misleading public launch; RISK-4 high store rejection/artifact confusion; RISK-5 high unrecoverable data or unauthorised administrative execution. Mitigations and owners are the gates above; all remain open until evidenced.

**Post-report recommendations:** None. The recommendation table includes this review's technical, commercial, legal, operational, sequencing and “do not do” recommendations.

**Founder outcome:** Research and coordination authorised. Implementation, migrations, account/security changes, purchases, uploads, campaigns and production release are **not approved by this report**. Founder ratification/GO and acceptance remain separate.

## 12. Recommended sequence

1. Owners reconcile current evidence and Founder chooses initial scope/operator/commercial intent.
2. Prepare and obtain exact approval for critical repairs; internally verify and post-verify any approved deployment with denial cases.
3. Finish real admission, photos, moderation, payments and legal/support requirements for that scope. Measure and privacy-test before shipping photo changes; seeds and bucket limits follow the approved order.
4. Freeze an identified release candidate; run native ordinary-user, security, accessibility, purchase and recovery acceptance. Keep synthetic reviewer access isolated.
5. Correct public destinations/claims; assemble store disclosures/products/reviewer instructions and obtain submission GO.
6. After store approval, obtain Founder launch GO for the exact build, countries, rollout and campaign. Post-verify live service, store purchase authority and support readiness, with stop/rollback thresholds.
7. Monitor the agreed launch; expand countries/platforms/automation only with their own evidence and approval. Do not infer permission for scheduled monitoring from this one-off audit.

**Next safe move:** obtain the remaining Admin release packet, current Apple status and the bounded App Build remediation proposal. Do not launch real-member acquisition on the present evidence.

## Verification and handover trace

Report V1 was created as a new point-in-time file; no pre-existing file was overwritten. Codex re-read the report and checked its local file links. Three read-only research subagents checked the local product/evidence, store requirements and legal/applicability wording. Corrections applied: verified recovery-email authentication wording; Group rather than ZYRA trademark action identifiers; explicit Play Console minor restriction and deletion scope; precise Apple seller wording; current regional billing programs. This is **Codex internal report verification**, not independent legal/security acceptance or app certification.

No authoritative register was rewritten during concurrent Admin/App Build work. Existing OA mappings are retained for one-writer reconciliation; their statuses and Founder gates are not changed by this supplementary report. The report is handed to the three authorised chats for evidence reconciliation, not implementation. A later status packet must distinguish evidence newly supplied from the dated evidence retained here.
