#!/bin/bash
# Automated Dialogflow CX Lab: Flight Booker Agent
# Works in Cloud Shell with alpha commands
# Author: CloudCupcake 🍰

set -e

# ---------- AUTO-DETECT CONFIG ----------
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
  echo "No GCP project set. Run 'gcloud config set project PROJECT_ID' first."
  exit 1
fi

REGION=$(gcloud compute regions list --limit=1 --format="value(name)")
TIMEZONE=$(curl -s http://worldtimeapi.org/api/timezone/Etc/UTC | jq -r '.utc_offset') || TIMEZONE="GMT"

AGENT_NAME="Flight Booker - Env Mgt"
BLOB_FILE="./gsp929-start-agent.blob"
QA_ENV="QA"
DEV_ENV="Dev"
V1_NAME="Flight booker main v1 chat bot"
V2_NAME="Flight booker main v2 chat bot"

echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Timezone: $TIMEZONE"

# ---------- ENABLE APIS ----------
echo "Enabling Dialogflow API..."
gcloud services enable dialogflow.googleapis.com --project $PROJECT_ID

# ---------- CREATE AGENT ----------
echo "Creating Dialogflow CX agent..."
AGENT_ID=$(gcloud alpha dialogflow agents create \
  --project="$PROJECT_ID" \
  --display-name="$AGENT_NAME" \
  --default-language-code="en" \
  --time-zone="$TIMEZONE" \
  --location="$REGION" \
  --description="Automated Flight Booker agent" \
  --format="value(name)")
echo "Agent created: $AGENT_ID"

# ---------- ENABLE LOGGING ----------
echo "Enabling Cloud Logging and Conversation History..."
gcloud alpha dialogflow agents update $AGENT_ID \
  --enable-logging \
  --enable-conversation-history \
  --project $PROJECT_ID

# ---------- RESTORE .BLOB FILE ----------
echo "Restoring .blob agent..."
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -F "agentContent=@$BLOB_FILE" \
  "https://${REGION}-dialogflow.googleapis.com/v3/projects/${PROJECT_ID}/locations/${REGION}/agents/${AGENT_ID}:restore"

echo "Waiting 60s for restore to complete..."
sleep 60

# ---------- CREATE VERSION V1 ----------
echo "Creating Version V1..."
FLOW_ID=$(gcloud alpha dialogflow flows list \
  --agent=$AGENT_ID \
  --location=$REGION \
  --project=$PROJECT_ID \
  --filter="displayName='Default Start Flow'" \
  --format="value(name)")

gcloud alpha dialogflow versions create "$V1_NAME" \
  --flow="$FLOW_ID" \
  --description="Initial version of Flight Booker agent" \
  --project=$PROJECT_ID

# ---------- CREATE QA ENVIRONMENT ----------
echo "Creating QA environment..."
gcloud alpha dialogflow environments create $QA_ENV \
  --agent=$AGENT_ID \
  --flow-version="$FLOW_ID@1" \
  --project=$PROJECT_ID

# ---------- ADD FRIENDLY GREETING FOR V2 ----------
echo "Adding friendly greeting for V2..."
ENTRY_FULFILLMENT=$(gcloud alpha dialogflow pages describe "Ticket information" \
  --agent=$AGENT_ID --location=$REGION --flow=$FLOW_ID --format=json)

UPDATED_FULFILLMENT=$(echo $ENTRY_FULFILLMENT | jq '.entryFulfillment.messages += [{"text":{"text":["I\'ll be happy to assist you with that."]},"messageType":"TEXT"}]')

gcloud alpha dialogflow pages update "Ticket information" \
  --agent=$AGENT_ID --location=$REGION --flow=$FLOW_ID \
  --entry-fulfillment="$UPDATED_FULFILLMENT"

# ---------- CREATE VERSION V2 ----------
echo "Creating Version V2..."
gcloud alpha dialogflow versions create "$V2_NAME" \
  --flow="$FLOW_ID" \
  --description="Version 2 adds a friendly greeting before prompting for flight details" \
  --project=$PROJECT_ID

# ---------- CREATE DEV ENVIRONMENT ----------
echo "Creating Dev environment..."
gcloud alpha dialogflow environments create $DEV_ENV \
  --agent=$AGENT_ID \
  --flow-version="$FLOW_ID@2" \
  --project=$PROJECT_ID

echo "Automation complete! Your agent is ready with QA and Dev environments."
