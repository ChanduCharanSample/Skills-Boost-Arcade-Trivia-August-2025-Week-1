#!/bin/bash
# Conversational Agents: Managing Environments - Full Automation
# Author: cloudcupcake
# Works inside Qwiklabs Cloud Shell

echo "=============================="
echo " Conversational Agents: Managing Environments "
echo "=============================="

# ----------------------------
# 0. Environment Setup
# ----------------------------
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
AGENT_NAME="flight-booker-agent"
AGENT_DISPLAY="Flight Booker Agent"
AGENT_LOCATION="global"
SERVICE_ACCOUNT="$(gcloud config get-value account)"

echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "User: $SERVICE_ACCOUNT"
echo "=============================="

# Enable required APIs
echo "Enabling APIs..."
gcloud services enable dialogflow.googleapis.com \
    cloudbuild.googleapis.com \
    storage.googleapis.com

# ----------------------------
# 1. Create Dialogflow CX Agent
# ----------------------------
echo "Creating Dialogflow CX Agent..."
gcloud alpha dialogflow cx agents create "$AGENT_NAME" \
  --display-name="$AGENT_DISPLAY" \
  --default-language-code="en" \
  --time-zone="America/Los_Angeles" \
  --location="$REGION"

# Fetch agent ID
AGENT_ID=$(gcloud alpha dialogflow cx agents list --location="$REGION" \
  --format="value(name)" --filter="displayName=$AGENT_DISPLAY")

echo "Agent created: $AGENT_ID"

# ----------------------------
# 2. Import/Restore Prebuilt Agent Blob
# ----------------------------
echo "Restoring agent with lab-provided blob..."
# In Qwiklabs the JSON blob is pre-provided, but equivalent action is:
gsutil cp gs://cloud-training/dialogflowcx/flight-booker-agent.blob ./agent.blob

gcloud alpha dialogflow cx agents restore "$AGENT_ID" \
  --location="$REGION" \
  --agent-content-file="./agent.blob" \
  --quiet

echo "Agent restored successfully."

# ----------------------------
# 3. Create Draft Environment
# ----------------------------
ENV_NAME="test-environment"
echo "Creating environment: $ENV_NAME"

gcloud alpha dialogflow cx environments create \
  --agent="$AGENT_ID" \
  --location="$REGION" \
  --display-name="$ENV_NAME" \
  --description="Test environment for lab automation" \
  --deployment-strategy="ALLOW_CONCURRENT" \
  --quiet

# ----------------------------
# 4. Set Environment Variables
# ----------------------------
echo "Setting environment variables..."
cat > env.yaml <<EOF
variables:
  airline: "Delta"
  location: "SFO"
  confirmation_code: "ABC123"
EOF

ENV_ID=$(gcloud alpha dialogflow cx environments list \
  --agent="$AGENT_ID" \
  --location="$REGION" \
  --format="value(name)" \
  --filter="displayName=$ENV_NAME")

gcloud alpha dialogflow cx environments patch "$ENV_ID" \
  --location="$REGION" \
  --update-mask="variables" \
  --file=env.yaml

echo "Environment variables updated."

# ----------------------------
# 5. Deploy Draft Flow to Environment
# ----------------------------
echo "Deploying draft flow to environment..."
gcloud alpha dialogflow cx environments deploy-flow "$ENV_ID" \
  --flow="$AGENT_ID/flows/start_flow" \
  --location="$REGION" \
  --quiet

echo "Deployment completed."

# ----------------------------
# 6. Verification
# ----------------------------
echo "Verifying agent and environment..."
gcloud alpha dialogflow cx agents describe "$AGENT_ID" --location="$REGION"
gcloud alpha dialogflow cx environments describe "$ENV_ID" --location="$REGION"

echo "=============================="
echo " 🎉 Lab Automated Successfully! Subscribe to cloudcupcake "
echo "=============================="
