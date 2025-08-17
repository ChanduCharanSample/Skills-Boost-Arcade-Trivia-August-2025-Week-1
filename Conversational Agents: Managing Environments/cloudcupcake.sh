#!/bin/bash
# cloudcupcake.sh - Automating Conversational Agents: Environment Management (GSP929)
# Includes automated testing, retry until version is READY, and auto-detected timezone

set -e

PROJECT_ID=$(gcloud config get-value project)
REGION="global"   # Change if lab specifies

# Auto-detect GMT offset and format for Dialogflow CX
RAW_TZ=$(date +%:z)         # e.g., +05:30
TIMEZONE="GMT${RAW_TZ}"     # e.g., GMT+05:30

SESSION_ID="test-$(date +%s)"   # unique session for testing

echo "=============================="
echo " Using Project: $PROJECT_ID"
echo " Region: $REGION"
echo " Auto-detected Timezone: $TIMEZONE"
echo " Session: $SESSION_ID"
echo "=============================="

echo "1. Enabling Dialogflow CX API..."
gcloud services enable dialogflow.googleapis.com

echo "2. Creating Flight Booker Agent..."
gcloud dialogflow cx agents create \
  --display-name="Flight Booker - Env Mgt" \
  --default-language-code="en" \
  --time-zone=$TIMEZONE \
  --location=$REGION || true

AGENT_ID=$(gcloud dialogflow cx agents list --location=$REGION --format="value(name)" | head -n1)
echo "Agent created: $AGENT_ID"

echo "3. Restoring agent from provided blob..."
curl -s -o gsp929-start-agent.blob https://raw.githubusercontent.com/ChanduCharanSample/Level-1-Application-Design-and-Delivery---2025/main/gsp929-start-agent.blob
gcloud dialogflow cx agents restore $AGENT_ID \
  --location=$REGION \
  --agent-content-file=gsp929-start-agent.blob

# -------------------------------
# Function to wait until version is READY
wait_for_version_ready () {
  local VERSION=$1
  echo "Waiting for version $VERSION to be READY..."
  STATUS="NOT_READY"
  for i in {1..20}; do
    STATUS=$(gcloud dialogflow cx versions describe $VERSION --location=$REGION --format="value(state)")
    echo "Attempt $i: Status = $STATUS"
    if [[ "$STATUS" == "READY" ]]; then
      echo "✅ Version $VERSION is READY"
      return 0
    fi
    sleep 10
  done
  echo "❌ Version $VERSION not ready after waiting"
  exit 1
}
# -------------------------------

echo "4. Creating version v1..."
FLOW_ID=$(gcloud dialogflow cx flows list --agent=$AGENT_ID --location=$REGION --format="value(name)" | head -n1)
VERSION1=$(gcloud dialogflow cx versions create \
  --flow=$FLOW_ID \
  --display-name="Flight booker main v1 chat bot" \
  --description="Initial version from lab" \
  --format="value(name)")

wait_for_version_ready $VERSION1

echo "5. Creating environment QA..."
gcloud dialogflow cx environments create \
  --agent=$AGENT_ID \
  --display-name="QA" \
  --description="QA environment" \
  --version-config=$FLOW_ID=$VERSION1

echo "6. Creating version v2..."
VERSION2=$(gcloud dialogflow cx versions create \
  --flow=$FLOW_ID \
  --display-name="Flight booker main v2 chat bot" \
  --description="Version 2 adds greeting message" \
  --format="value(name)")

wait_for_version_ready $VERSION2

echo "7. Creating environment Dev..."
gcloud dialogflow cx environments create \
  --agent=$AGENT_ID \
  --display-name="Dev" \
  --description="Dev environment with v2" \
  --version-config=$FLOW_ID=$VERSION2

echo "=============================="
echo " Automated Tests (detect-intent)"
echo "=============================="

echo "Testing Draft environment..."
gcloud dialogflow cx sessions detect-intent \
  --session=$SESSION_ID \
  --query-input="text='i want to book a flight',language-code=en" \
  --agent=$AGENT_ID \
  --location=$REGION

echo "Testing QA environment..."
gcloud dialogflow cx sessions detect-intent \
  --session=$SESSION_ID \
  --query-input="text='i want to book a flight',language-code=en" \
  --environment="QA" \
  --agent=$AGENT_ID \
  --location=$REGION

echo "Testing Dev environment..."
gcloud dialogflow cx sessions detect-intent \
  --session=$SESSION_ID \
  --query-input="text='i want to book a flight',language-code=en" \
  --environment="Dev" \
  --agent=$AGENT_ID \
  --location=$REGION

echo "=============================="
echo " ✅ Script completed!"
echo " Agent tested in Draft, QA, and Dev."
echo " Now return to Qwiklabs and click 'Check my progress'."
echo "=============================="
