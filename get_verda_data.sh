#!/bin/bash

TOKEN_RESPONSE=$(curl -s -X POST https://api.verda.com/v1/oauth2/token \
  --header 'Content-Type: application/json' \
  --data "{
    \"grant_type\": \"client_credentials\",
    \"client_id\": \"$VERDA_CLIENT_ID\",
    \"client_secret\": \"$VERDA_CLIENT_SECRET\"
  }")

TOKEN=$(echo "$TOKEN_RESPONSE" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

curl -s "https://api.verda.com/v1/instance-types?currency=eur" \
  --header 'Accept: */*' \
  --header "Authorization: Bearer $TOKEN" > instance-types.json

curl -s "https://api.verda.com/v1/container-types?currency=eur" \
  --header 'Accept: */*' \
  --header "Authorization: Bearer $TOKEN" > container-types.json

curl https://api.verda.com/v1/volume-types \
  --header 'Accept: */*' \
  --header 'Authorization: Bearer '$TOKEN > volume-types.json