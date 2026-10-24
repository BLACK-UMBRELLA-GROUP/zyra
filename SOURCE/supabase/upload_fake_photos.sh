#!/bin/bash
# Uploads the 20 fake Browse-candidate profile photo sets (10 male, 10
# female, 5 photos each) to Supabase Storage, then writes the matching
# profile_photos SQL insert to run afterward.
#
# HISTORICAL UTILITY. Its former production-era use is not authority to run it
# against production again. It may target only the separately approved ZYRA
# Test staging project, and is deliberately inert while that pin is unassigned.
#
# Usage:
#   Supply ZYRA_STAGING_PROJECT_REF,
#   ZYRA_STAGING_SUPABASE_PUBLISHABLE_KEY, and
#   ZYRA_DEV_ACCOUNT_PASSWORD in the caller environment, then run this file.
# Never save those values in this repository or shell history.

set -euo pipefail

readonly APPROVED_STAGING_PROJECT_REF="UNASSIGNED_STAGING_PROJECT_REF"
readonly PRODUCTION_PROJECT_REF="sxoaxonzjqkgajmlagyk"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

: "${ZYRA_STAGING_PROJECT_REF:?ZYRA_STAGING_PROJECT_REF is required}"
: "${ZYRA_STAGING_SUPABASE_PUBLISHABLE_KEY:?ZYRA_STAGING_SUPABASE_PUBLISHABLE_KEY is required}"
: "${ZYRA_DEV_ACCOUNT_PASSWORD:?ZYRA_DEV_ACCOUNT_PASSWORD is required}"

[[ "$APPROVED_STAGING_PROJECT_REF" != "UNASSIGNED_STAGING_PROJECT_REF" ]] || \
  fail "photo upload is disabled until the approved staging project ref is pinned"
[[ "$APPROVED_STAGING_PROJECT_REF" != "$PRODUCTION_PROJECT_REF" ]] || \
  fail "the compiled staging pin must never be production"
[[ "$ZYRA_STAGING_PROJECT_REF" != "$PRODUCTION_PROJECT_REF" ]] || \
  fail "photo upload refuses the production project"
[[ "$ZYRA_STAGING_PROJECT_REF" == "$APPROVED_STAGING_PROJECT_REF" ]] || \
  fail "target project ref does not match the separately approved staging pin"
[[ "$ZYRA_STAGING_PROJECT_REF" =~ ^[a-z0-9]{20}$ ]] || \
  fail "target project ref is malformed"
[[ "$ZYRA_STAGING_SUPABASE_PUBLISHABLE_KEY" != "UNASSIGNED" ]] || \
  fail "staging publishable key is unassigned"
[[ ${#ZYRA_DEV_ACCOUNT_PASSWORD} -ge 16 ]] || \
  fail "developer account password must be at least 16 characters"
command -v curl >/dev/null 2>&1 || fail "curl is required"
command -v python3 >/dev/null 2>&1 || fail "python3 is required"

readonly BASE="https://${ZYRA_STAGING_PROJECT_REF}.supabase.co"
readonly PUBLISHABLE_KEY="$ZYRA_STAGING_SUPABASE_PUBLISHABLE_KEY"
readonly DEV_ACCOUNT_PASSWORD="$ZYRA_DEV_ACCOUNT_PASSWORD"
unset ZYRA_DEV_ACCOUNT_PASSWORD

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PHOTO_DIR="${ZYRA_DEV_PHOTO_DIR:-$SCRIPT_DIR/dev_test_photos}"
readonly OUT_SQL="${ZYRA_DEV_PHOTO_SQL_OUTPUT:-$SCRIPT_DIR/insert_dev_photos.sql}"

sign_in() {
  local email="$1"

  # JSON is encoded without placing the credential in a process argument.
  printf '%s\0%s' "$email" "$DEV_ACCOUNT_PASSWORD" |
    python3 -c 'import json, sys; email, password = sys.stdin.buffer.read().split(b"\0", 1); sys.stdout.write(json.dumps({"email": email.decode(), "password": password.decode()}))' |
    curl -sS -X POST "$BASE/auth/v1/token?grant_type=password" \
      -H "apikey: $PUBLISHABLE_KEY" \
      -H "Content-Type: application/json" \
      --data-binary @-
}

read_access_token() {
  python3 -c 'import json, sys; value = json.load(sys.stdin).get("access_token"); valid = isinstance(value, str) and len(value) >= 20; sys.stdout.write(value if valid else ""); raise SystemExit(0 if valid else 1)'
}

# email:user_id:GenderWord:PortraitNumber
USERS=(
  "fake.female.01@zyra.test:b96daf45-e619-4d9a-894f-940a7932b2d8:Female:1"
  "fake.female.02@zyra.test:39dee4ca-a60c-4435-9abe-a6af57026730:Female:2"
  "fake.female.03@zyra.test:1531370a-99fb-44c2-981b-49482522744f:Female:3"
  "fake.female.04@zyra.test:761657eb-e675-4657-ac27-c02a52675e76:Female:4"
  "fake.female.05@zyra.test:07599948-9f00-4a64-adca-ad8d2deb08e8:Female:5"
  "fake.female.06@zyra.test:607577f8-be03-42c8-bb8b-2834d56adc60:Female:6"
  "fake.female.07@zyra.test:c9fd085c-f9ba-4045-877a-b061fde30b6f:Female:7"
  "fake.female.08@zyra.test:07dc54c0-fba1-4319-b10f-af8dde2b68ea:Female:8"
  "fake.female.09@zyra.test:e5bcbf1b-ff6e-4997-b69d-02e54f8f8b52:Female:9"
  "fake.female.10@zyra.test:c75c01ca-6dde-4ae0-8b5e-89f9e18a445c:Female:10"
  "fake.male.01@zyra.test:1e16657e-80cc-4644-929a-b9276d2e824c:Male:1"
  "fake.male.02@zyra.test:62badf17-db60-4be6-b7d8-e3e8d11fc37d:Male:2"
  "fake.male.03@zyra.test:b3006ac6-0ad2-46e6-9e8c-7d5ff987e50b:Male:3"
  "fake.male.04@zyra.test:b8332572-7db3-468d-8200-ebb090db0e72:Male:4"
  "fake.male.05@zyra.test:4b2fff7c-29d1-4532-9886-32b0bb0443c8:Male:5"
  "fake.male.06@zyra.test:607a6108-1de1-4f1d-997b-f077b35a9be3:Male:6"
  "fake.male.07@zyra.test:80f6ff65-498f-4314-8038-4559940f788e:Male:7"
  "fake.male.08@zyra.test:7e030c51-925d-47a5-8069-75da5350ad00:Male:8"
  "fake.male.09@zyra.test:12421707-fe06-4604-94bb-771ccd8ae30a:Male:9"
  "fake.male.10@zyra.test:fa846b99-0212-4b3e-ae55-ede02a6d9e0f:Male:10"
)

echo "insert into public.profile_photos (user_id, storage_path, display_order) values" > "$OUT_SQL"
ROWS=()
OK_COUNT=0
FAIL_COUNT=0

for entry in "${USERS[@]}"; do
  IFS=':' read -r email uid gender n <<< "$entry"

  if ! token="$(sign_in "$email" | read_access_token)"; then
    echo "FAILED sign-in: $email"
    FAIL_COUNT=$((FAIL_COUNT+1))
    continue
  fi

  order=0
  for suffix in "" " (2)" " (3)" " (4)" " (5)"; do
    fname="${gender} Portrait ${n}${suffix}.png"
    fpath="$PHOTO_DIR/$fname"
    if [ ! -f "$fpath" ]; then
      echo "MISSING file: $fname"
      FAIL_COUNT=$((FAIL_COUNT+1))
      order=$((order+1))
      continue
    fi
    code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
      "$BASE/storage/v1/object/profile-photos/$uid/$order.png" \
      -H "apikey: $PUBLISHABLE_KEY" -H "Authorization: Bearer $token" \
      -H "Content-Type: image/png" -H "x-upsert: true" \
      --data-binary "@$fpath")
    if [ "$code" = "200" ] || [ "$code" = "201" ]; then
      ROWS+=("  ('$uid', '$uid/$order.png', $order)")
      OK_COUNT=$((OK_COUNT+1))
      echo "OK  $email  order $order"
    else
      echo "FAILED upload $fname -> HTTP $code"
      FAIL_COUNT=$((FAIL_COUNT+1))
    fi
    order=$((order+1))
  done
done

(IFS=$',\n'; echo "${ROWS[*]}") >> "$OUT_SQL"
echo ";" >> "$OUT_SQL"

echo ""
echo "Done. Uploaded: $OK_COUNT, Failed: $FAIL_COUNT"
echo "SQL written to: $OUT_SQL"
echo "The generated SQL remains staging-only and requires separate review before use."
