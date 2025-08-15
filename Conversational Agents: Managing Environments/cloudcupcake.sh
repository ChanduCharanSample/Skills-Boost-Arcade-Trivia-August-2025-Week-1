#!/bin/bash
set -e

# Auto-detect configuration
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
  echo "No project set. Use 'gcloud config set project PROJECT_ID'."
  exit 1
fi
REGION=$(gcloud compute regions list --limit=1 --format="value(name)")
TIMEZONE=$(curl -s http://worldtimeapi.org/api/timezone/Etc/UTC | jq -r '.utc_offset' || echo "GMT")

ENDPOINT="${REGION}-dialogflow.googleapis.com"
AUTH_HDR="Authorization: Bearer $(gcloud auth print-access-token)"
CONTENT_HDR="Content-Type: application/json; charset=utf-8"

echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Timezone: $TIMEZONE"

# Step 1: Create Agent
echo "Creating agent..."
AGENT_PAYLOAD=$(jq -n \
  --arg dn "Flight Booker - Env Mgt" \
  --arg tz "$TIMEZONE" \
  '{
    displayName: $dn,
    defaultLanguageCode: "en",
    timeZone: $tz
  }')

AGENT_CREATE_URL="https://${ENDPOINT}/v3/projects/${PROJECT_ID}/locations/${REGION}/agents"
AGENT_RESPONSE=$(curl -s -X POST -H "$AUTH_HDR" -H "$CONTENT_HDR" -d "$AGENT_PAYLOAD" "$AGENT_CREATE_URL")
AGENT_NAME=$(echo "$AGENT_RESPONSE" | jq -r '.name')
echo "Created agent: $AGENT_NAME"

# Step 2: Restore .blob agent
if [ -f "./gsp929-start-agent.blob" ]; then
  echo "Restoring agent blob..."
  RESTORE_URL="https://${ENDPOINT}/v3/${AGENT_NAME}:restore"
  curl -X POST -H "$AUTH_HDR" -F "agentContent=@./gsp929-start-agent.blob" "$RESTORE_URL"
  echo "Restore API call sent."
else
  echo "Blob file not found: gsp929-start-agent.blob"
fi

echo "Done!"
