#!/bin/bash
# Retries the 5 photos that failed with a transient network error
# (HTTP 000) during upload_fake_photos.sh's run.

set -u
BASE="https://sxoaxonzjqkgajmlagyk.supabase.co"
ANON="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4b2F4b256anFrZ2FqbWxhZ3lrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQzOTEyOTUsImV4cCI6MjA5OTk2NzI5NX0.wPgj5yuDZGig_ESE4hTzLD6Ec2X-gz8NPW1qyztGu3U"
PASS="ZyraFake!2026"
PHOTO_DIR="/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/dev_test_photos"
OUT_SQL="/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/insert_retry_photos.sql"

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

  resp=$(curl -s -X POST "$BASE/auth/v1/token?grant_type=password" \
    -H "apikey: $ANON" -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"$PASS\"}")
  token=$(echo "$resp" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

  if [ -z "$token" ]; then
    echo "FAILED sign-in: $email -> $resp"
    FAIL_COUNT=$((FAIL_COUNT+1))
    continue
  fi

  code=$(curl -s -o /dev/null -w "%{http_code}" --retry 3 --retry-delay 2 -X PUT \
    "$BASE/storage/v1/object/profile-photos/$uid/$order.png" \
    -H "apikey: $ANON" -H "Authorization: Bearer $token" \
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
echo "Tell Claude it's done."
