#!/bin/bash

# Script to credit a user with 100 points for a referral activity
# Usage: ./script/credit_referral.sh [user_email] [optional: host]
# Example: ./script/credit_referral.sh alice@example.com
# Example: ./script/credit_referral.sh alice@example.com localhost:3001

set -e

USER_EMAIL="${1:-alice@example.com}"
HOST="${2:-localhost:3000}"
API_BASE="http://${HOST}"

# Test Partner API Key (seeded in db/seeds.rb)
PARTNER_API_KEY="partner_a_secret_key_123"

echo "Crediting referral activity for: $USER_EMAIL"
echo "Host: $HOST"
echo ""

# Call the webhook endpoint with referral activity
RESPONSE=$(curl -s -X POST "${API_BASE}/webhooks/activity" \
  -H "Authorization: Bearer ${PARTNER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"partner_user_id\": \"$(echo $USER_EMAIL | cut -d@ -f1)\",
    \"activity_type\": \"referral\",
    \"external_id\": \"ref_$(date +%s)_$(shuf -i 1000-9999 -n 1)\",
    \"occurred_at\": \"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\"
  }")

echo "Response:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

# Check if successful
if echo "$RESPONSE" | grep -q '"status"'; then
  echo " Referral activity recorded successfully!"
  echo " User $USER_EMAIL has been credited with 100 points"
else
  echo " Failed to record referral activity"
  exit 1
fi
