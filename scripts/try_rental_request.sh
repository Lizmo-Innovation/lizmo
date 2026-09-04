#!/usr/bin/env bash
#
# Walks the whole tenant-asks-for-a-bed flow against a running local API.
#
#   bash scripts/try_rental_request.sh
#
# Creates a landlord with a property, a bedspace room and a whole unit, then a
# tenant who tries to ask for a bed too early, fixes their profile, and asks
# again. Every account is stamped with the current epoch so the script can be
# run repeatedly without colliding on an email address.
#
# Needs the whole compose stack, not just the API. Signing up and being invited
# are emailed now, so the codes come back out of Mailpit the way a person reads
# their inbox. Being a Lizmo admin is a row in the database, which is the only
# way one is ever granted -- no endpoint hands out admin, deliberately -- so the
# script inserts it, which is what an operator would do.
set -euo pipefail

API="${LIZMO_API:-http://localhost:8082}"
MAILPIT="${LIZMO_MAILPIT:-http://localhost:8026}"
STAMP=$(date +%s)

# Meets the password rule: at least eight characters, with a capital, a small
# letter, a number and a symbol.
PASSWORD="Sunrise2Bed!"

say()   { printf '\n\033[1;36m== %s\033[0m\n' "$1"; }
show()  { python -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d,indent=2)[:700])"; }
field() { python -c "import json,sys; print(json.load(sys.stdin)$1)"; }

# The six digits Lizmo just emailed, taken from the subject line.
code_for() {
  curl -s "$MAILPIT/api/v1/search?query=to:$1" \
    | python -c "import json,sys,re; print(re.search(r'[0-9]{6}', json.load(sys.stdin)['messages'][0]['Subject']).group(0))"
}

# The invitation token, out of the most recent email to an address.
invite_token_for() {
  local id
  id=$(curl -s "$MAILPIT/api/v1/search?query=to:$1" | field "['messages'][0]['ID']")
  curl -s "$MAILPIT/api/v1/message/$id" \
    | python -c "import json,sys,re; print(re.findall(r'invite/([^\s]+)', json.load(sys.stdin)['Text'])[0])"
}

# Signs somebody up the way the app does -- ask for a code, read it, finish --
# and prints their access token.
sign_up() {
  local email="$1" name="$2"
  curl -s -X POST "$API/api/v1/auth/register/start" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$email\"}" > /dev/null
  curl -s -X POST "$API/api/v1/auth/register/complete" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$email\",\"code\":\"$(code_for "$email")\",\"name\":\"$name\",\"password\":\"$PASSWORD\"}" \
    | field "['accessToken']"
}

# --- a landlord with somewhere to let ---------------------------------------

say "Making a Lizmo admin (a row, because nothing else grants it)"
ADMIN="admin$STAMP@lizmo.test"
sign_up "$ADMIN" "Lizmo Staff" > /dev/null
ADMIN_ID=$(curl -s -X POST "$API/api/v1/auth/login" -H 'Content-Type: application/json' \
  -d "{\"identifier\":\"$ADMIN\",\"password\":\"$PASSWORD\"}" | field "['userId']")
docker compose exec -T postgres psql -U lizmo -d lizmo -q \
  -c "INSERT INTO platform_admins (user_id, created_at) VALUES ('$ADMIN_ID', now());"
# Signed in again: the profiles are baked into an access token when it is
# issued, and the one from before the insert says TENANT.
AT=$(curl -s -X POST "$API/api/v1/auth/login" -H 'Content-Type: application/json' \
  -d "{\"identifier\":\"$ADMIN\",\"password\":\"$PASSWORD\"}" | field "['accessToken']")
echo "ok"

say "Inviting a landlord"
ELENA="elena$STAMP@example.com"
curl -s -X POST "$API/api/v1/admin/landlord-invitations" -H "Authorization: Bearer $AT" \
  -H 'Content-Type: application/json' -d "{\"email\":\"$ELENA\",\"name\":\"Elena\"}" | show

say "Accepting the invitation -- the only way a landlord is made"
LT=$(curl -s -X POST "$API/api/v1/auth/invitations/accept" -H 'Content-Type: application/json' \
  -d "{\"token\":\"$(invite_token_for "$ELENA")\",\"name\":\"Elena Bautista\",\"password\":\"$PASSWORD\"}" \
  | field "['accessToken']")
echo "ok"

say "Creating a property"
PROPERTY=$(curl -s -X POST "$API/api/v1/properties" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"name":"Sunrise Apartments","address":"12 Mabini St","type":"BOARDING_HOUSE","usage":"RESIDENTIAL"}')
PID=$(echo "$PROPERTY" | python -c "import json,sys; print(json.load(sys.stdin)['id'])")
CODE=$(echo "$PROPERTY" | python -c "import json,sys; print(json.load(sys.stdin)['code'])")
echo "property code: $CODE   <- this is what goes on the gate"

say "Adding a bedspace room (3 beds) and a whole unit"
UNIT_BEDS=$(curl -s -X POST "$API/api/v1/properties/$PID/units" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"unitNumber":"2B","floor":"2","rentalMode":"BEDSPACE","capacity":3,"rent":2500.00}')
UBID=$(echo "$UNIT_BEDS" | python -c "import json,sys; print(json.load(sys.stdin)['id'])")

curl -s -X POST "$API/api/v1/properties/$PID/units" -H "Authorization: Bearer $LT" \
  -H 'Content-Type: application/json' \
  -d '{"unitNumber":"101","floor":"1","rentalMode":"WHOLE_UNIT","rent":12000.00}' > /dev/null

BED=$(curl -s "$API/api/v1/units/$UBID/beds" -H "Authorization: Bearer $LT" \
  | python -c "import json,sys; print(json.load(sys.stdin)[0]['id'])")
echo "ok"

# --- a tenant finds the place ------------------------------------------------

say "Signing a tenant up (address, code, then a password)"
TT=$(sign_up "ana$STAMP@example.com" "Ana")
echo "ok"

say "Looking the property up by its code (what the tenant sees)"
curl -s "$API/api/v1/properties/lookup?code=$CODE" -H "Authorization: Bearer $TT" | show

say "Asking for a bed with an unfinished profile -- expect 409, naming what is missing"
curl -s -X POST "$API/api/v1/me/rental-requests" -H "Authorization: Bearer $TT" \
  -H 'Content-Type: application/json' \
  -d "{\"unitId\":\"$UBID\",\"bedId\":\"$BED\"}" | show

# --- the tenant finishes their profile --------------------------------------

say "Filling in the profile"
curl -s -X PUT "$API/api/v1/me/tenant-profile" -H "Authorization: Bearer $TT" \
  -H 'Content-Type: application/json' \
  -d '{"emergencyContactName":"Rosa Dela Cruz","emergencyContactPhone":"09171234567","idType":"PHILSYS","idNumber":"1234-5678-9012","occupation":"Nurse","birthdate":"1998-04-12"}' > /dev/null

say "Uploading an ID photo and a 1x1"
PHOTO=$(mktemp -u).jpg
python - "$PHOTO" <<'PY'
import sys, struct, zlib
# A tiny valid JPEG is fiddly to hand-roll; a 1x1 PNG is accepted too and the
# API re-encodes whatever arrives to a stripped JPEG anyway.
path = sys.argv[1].replace('.jpg', '.png')
def chunk(t, d):
    c = t + d
    return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c))
png = (b'\x89PNG\r\n\x1a\n'
       + chunk(b'IHDR', struct.pack('>IIBBBBB', 8, 8, 8, 2, 0, 0, 0))
       + chunk(b'IDAT', zlib.compress(b''.join(b'\x00' + b'\x80\x80\x80' * 8 for _ in range(8))))
       + chunk(b'IEND', b''))
open(path, 'wb').write(png)
print(path)
PY
PHOTO="${PHOTO%.jpg}.png"

for KIND in VALID_ID TENANT_PHOTO; do
  curl -s -X POST "$API/api/v1/me/tenant-profile/documents?docType=$KIND" \
    -H "Authorization: Bearer $TT" -F "file=@$PHOTO" > /dev/null
  echo "uploaded $KIND"
done

say "The profile now reports itself ready"
curl -s "$API/api/v1/me/tenant-profile" -H "Authorization: Bearer $TT" \
  | python -c "import json,sys; print('readyForALease:', json.load(sys.stdin)['readyForALease'])"

# --- and asks -----------------------------------------------------------------

say "Asking for the bed again -- expect 201 PENDING"
REQ=$(curl -s -X POST "$API/api/v1/me/rental-requests" -H "Authorization: Bearer $TT" \
  -H 'Content-Type: application/json' \
  -d "{\"unitId\":\"$UBID\",\"bedId\":\"$BED\"}")
echo "$REQ" | show
RID=$(echo "$REQ" | python -c "import json,sys; print(json.load(sys.stdin)['id'])")

say "Asking a second time -- expect 409 ALREADY_REQUESTED"
curl -s -X POST "$API/api/v1/me/rental-requests" -H "Authorization: Bearer $TT" \
  -H 'Content-Type: application/json' \
  -d "{\"unitId\":\"$UBID\",\"bedId\":\"$BED\"}" | show

say "Asking for the bedspace room whole -- expect 409, 'let bed by bed'"
curl -s -X POST "$API/api/v1/me/rental-requests" -H "Authorization: Bearer $TT" \
  -H 'Content-Type: application/json' -d "{\"unitId\":\"$UBID\"}" | show

say "What the tenant has asked for so far"
curl -s "$API/api/v1/me/rental-requests" -H "Authorization: Bearer $TT" | show

say "Withdrawing it"
curl -s -X POST "$API/api/v1/me/rental-requests/$RID/withdraw" -H "Authorization: Bearer $TT" | show

rm -f "$PHOTO"
printf '\n\033[1;32mDone. Property code was %s\033[0m\n' "$CODE"
