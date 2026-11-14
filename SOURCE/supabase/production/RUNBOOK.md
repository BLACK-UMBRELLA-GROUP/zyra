# Apply the clean ZYRA production baseline

Line 110 prepares the database and two Edge Functions. The SQL includes line 109's shared-code lookup under Q154 and the Q152 rules for Journey eligibility and expiry. Live apply requires the Founder's instruction **“apply the clean server”**. See [Owner-rights routine access](RPC_ACCESS.md#q152-journey-callers).

## 1. Create the production project

The Founder creates **ZYRA production** in ZYRA's existing Supabase organisation and chooses the region. London is closest to the intended members. In the dashboard, confirm the target is the newly created PostgreSQL 17 project with an empty ZYRA application schema. The baseline uses the project's built-in Auth and Storage schemas and `pgcrypto` in the `extensions` schema. Confirm `pgcrypto` is enabled under Database → Extensions before applying.

## 2. Apply the baseline

**Preferred.** Once the Founder says “apply the clean server”, Fable verifies the target in the Supabase connector and applies `001_baseline.sql` as `zyra_clean_production_baseline`. Check the connector's migration list afterward and record the applied version and repository commit. This route uses the connector's existing access.

**Founder CLI alternative.** With the CLI already signed in, set the shell variable `ZYRA_PRODUCTION_PROJECT` to the new project's reference from the dashboard. From the ZYRA repository root, run this command and record the commit whose SQL was applied.

```sh
supabase db query --linked --project-ref "${ZYRA_PRODUCTION_PROJECT:?Set the new production project reference}" --file SOURCE/supabase/production/001_baseline.sql
```

After either route, confirm the ZYRA tables and storage buckets exist and the application tables have row-level security enabled. Confirm `public.zyra_resolve_code_link(text)` is callable by `authenticated` and inaccessible to `anon` and `service_role`. Inspect the new project's security advisors before connecting the app. The production apply uses the SQL in this directory. `SOURCE/supabase/migrations/` contains the historical replay for the lab.

### Fixed reference data

The baseline starts with empty member, Journey, message and upload data. These four sets of fixed rows are present immediately after apply.

| Table | Rows | Purpose |
|---|---:|---|
| `public.zyra_onboarding_questions` | 105 | Current onboarding and Compatibility option definitions. |
| `private.zyra_question_area` | 110 | Maps Compatibility answers to the approved areas. |
| `private.zyra_unlock_release_gate` | 1 | Keeps Plus credit spending disabled until its separate release. |
| `storage.buckets` | 3 | Private display-photo, original-photo and profile-video buckets. |

## 3. Configure sign-in

The Founder sets **Confirm email** to **ON** under Authentication and configures the Apple and Google providers with the production applications. Set the **Site URL** and exact approved production callback URLs in Authentication → URL Configuration. Use the provider callback displayed by the new project in the Apple and Google consoles.

Set **Leaked password protection** to **ON** under Authentication. Supabase makes this setting available on Pro and higher. If ZYRA is still on Free, the Founder enables it after moving the ZYRA organisation to a paid plan, before the first real member.

## 4. Deploy the Edge Functions

In the production project's **Edge Functions** dashboard, create each function via the editor and use its checked-in `index.ts`.

| Function | Source | Request authentication |
|---|---|---|
| `zyra-photo-cleanup` | `functions/zyra-photo-cleanup/index.ts` | Requires the project's service-role bearer value. Keep gateway JWT verification enabled. Invoke only from trusted server infrastructure. |
| `zyra-profile-video-submit` | `functions/zyra-profile-video-submit/index.ts` | Disable the gateway's legacy JWT verification in the function details so current member sessions can reach the handler. The handler validates every bearer token with Supabase Auth and checks member entitlement and upload ownership before using service access. |

Both copies use the credentials supplied by Supabase's hosted runtime. After deployment, check refusal of an unauthenticated request to both functions. Check that the cleanup worker accepts an authorised service request and can read its queue. Check the profile video member flow with an authorised test account before enabling it for members.

Follow the [Line 94 photo cleanup handover](../../../PRODUCT/APPROVED/SERVER/RECORD/TIME_RULES_FOR_SERVER_1_2026-11-12.md#photo-cleanup-and-signing) to configure hourly invocation with `pg_cron` and `pg_net`. Check worker results and the service-only `zyra_photo_cleanup_failures` view for the 24-hour deletion deadline and exhausted retries. Confirm queue capacity against the worker's 12-path batch size under OA-ZYRA-317.

The trusted Journey request expiry entry point, `private.zyra_expire_due_journey_requests_all()`, is available for the Jobs specification (audit F-07). Line 110 installs the routine. The Jobs work owns scheduling it. Connections can continue to expire the signed-in member's due requests when opened.

## 5. Keep the lab and production separate

Today's project remains the lab with its existing test accounts, data, objects and lab-only shortcuts. The app continues using the lab until its separate production switch. The Founder completes the paid-plan and Auth steps before the first real member.
