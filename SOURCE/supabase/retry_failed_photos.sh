#!/bin/bash
# HISTORICAL UTILITY. Retries the 5 photos that failed with a transient network
# error (HTTP 000) during upload_fake_photos.sh's old run. That production-era
# run is history, not authority to run this against production again. This file
# is deliberately inert until the exact approved ZYRA Test staging ref is
# pinned below.

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
  fail "photo retry is disabled until the approved staging project ref is pinned"
[[ "$APPROVED_STAGING_PROJECT_REF" != "$PRODUCTION_PROJECT_REF" ]] || \
  fail "the compiled staging pin must never be production"
[[ "$ZYRA_STAGING_PROJECT_REF" != "$PRODUCTION_PROJECT_REF" ]] || \
  fail "photo retry refuses the production project"
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
readonly OUT_SQL="${ZYRA_DEV_PHOTO_SQL_OUTPUT:-$SCRIPT_DIR/insert_retry_photos.sql}"

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

# email:user_id:filename:order
RETRIES=(
  "fake.female.08@zyra.test:07dc54c0-fba1-4319-b10f-af8dde2b68ea:Female Portrait 8 (3).png:2"
  "fake.male.04@zyra.test:b8332572-7db3-468d-8200-ebb090db0e72:Male Portrait 4 (4).png:3"
  "fake.male.05@zyra.test:4b2fff7c-29d1-4532-9886-32b0bb0443c8:Male Portrait 5.png:0"
  "fake.male.07@zyra.test:80f6ff65-498f-4314-8038-4559940f788e:Male Portrait 7 (3).png:2"
  "fake.male.09@zyra.test:12421707-fe06-4604-94bb-771ccd8ae30a:Male Portrait 9.png:0"
)

echo "insert into public.profile_photos (user_id, storage_path, display_order) values" > "$OUT_SQL"
ROWS=()
OK_COUNT=0
FAIL_COUNT=0

for entry in "${RETRIES[@]}"; do
  IFS=':' read -r email uid fname order <<< "$entry"
  fpath="$PHOTO_DIR/$fname"

  if ! token="$(sign_in "$email" | read_access_token)"; then
    echo "FAILED sign-in: $email"
    FAIL_COUNT=$((FAIL_COUNT+1))
    continue
  fi

  code=$(curl -s -o /dev/null -w "%{http_code}" --retry 3 --retry-delay 2 -X PUT \
      "$BASE/storage/v1/object/profile-photos/$uid/$order.png" \
    -H "apikey: $PUBLISHABLE_KEY" -H "Authorization: Bearer $token" \
    -H "Content-Type: image/png" -H "x-upsert: true" \
    --data-binary "@$fpath")

  if [ "$code" = "200" ] || [ "$code" = "201" ]; then
    ROWS+=("  ('$uid', '$uid/$order.png', $order)")
    OK_COUNT=$((OK_COUNT+1))
    echo "OK   $fname"
  else
    echo "STILL FAILED: $fname -> HTTP $code"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi
done

(IFS=$',\n'; echo "${ROWS[*]}") >> "$OUT_SQL"
echo ";" >> "$OUT_SQL"

echo ""
echo "Retry done. Uploaded: $OK_COUNT, Still failed: $FAIL_COUNT"
echo "SQL written to: $OUT_SQL"
echo "The generated SQL remains staging-only and requires separate review before use."
