#!/bin/bash
# Uploads the 20 fake Browse-candidate profile photo sets (10 male, 10
# female, 5 photos each) to Supabase Storage, then writes the matching
# profile_photos SQL insert to run afterward.
#
# Run this ON YOUR MAC — it needs real network access to reach
# Supabase's Storage API.
#
# Usage:
#   chmod +x upload_fake_photos.sh
#   ./upload_fake_photos.sh

set -u
BASE="https://sxoaxonzjqkgajmlagyk.supabase.co"
ANON="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4b2F4b256anFrZ2FqbWxhZ3lrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQzOTEyOTUsImV4cCI6MjA5OTk2NzI5NX0.wPgj5yuDZGig_ESE4hTzLD6Ec2X-gz8NPW1qyztGu3U"
PASS="ZyraFake!2026"
PHOTO_DIR="/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/dev_test_photos"
OUT_SQL="/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/supabase/insert_dev_photos.sql"

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

  resp=$(curl -s -X POST "$BASE/auth/v1/token?grant_type=password" \
    -H "apikey: $ANON" -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"$PASS\"}")
  token=$(echo "$resp" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

  if [ -z "$token" ]; then
    echo "FAILED sign-in: $email -> $resp"
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
      -H "apikey: $ANON" -H "Authorization: Bearer $token" \
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
echo "Tell Claude it's done — it can read that file directly."
