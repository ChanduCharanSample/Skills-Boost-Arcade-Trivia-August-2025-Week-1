#!/bin/bash
# Conversational Agents: Managing Environments - Task 1 automation
# Cloudcupcake script 🍰

set -e

echo "=============================="
echo " Conversational Agents Lab Setup "
echo "=============================="

# Detect project
PROJECT_ID=$(gcloud config get-value project)
REGION="global"

echo "Using Project: $PROJECT_ID"
echo "Region: $REGION"
echo "=============================="

# 1. Enable Dialogflow API
echo "1. Enabling Dialogflow CX API..."
gcloud services enable dialogflow.googleapis.com

# 2. Create CX agent
echo "2. Creating Flight Booker Agent..."
AGENT_NAME="flight-booker-agent"
LOCATION="global"

gcloud alpha dialogflow cx agents create \
  --display-name="$AGENT_NAME" \
  --default-language-code="en" \
  --time-zone="America/Los_Angeles" \
  --location="$LOCATION"

echo "Agent [$AGENT_NAME] created."

# 3. Restore agent from provided blob
# (Lab usually provides a blob file: `agent.blob`)
# If file is missing, download from lab instructions

if [ -f "agent.blob" ]; then
  echo "3. Restoring agent from agent.blob..."
  AGENT_ID=$(gcloud alpha dialogflow cx agents list --location=$LOCATION \
              --format="value(name)" | grep "$AGENT_NAME" | cut -d/ -f6)

  gcloud alpha dialogflow cx agents restore $AGENT_ID \
    --location=$LOCATION \
    --agent-content-file="agent.blob"

  echo "Agent restored successfully."
else
  echo "⚠️ agent.blob not found. Please download from lab instructions."
fi

echo "=============================="
echo "Task 1 setup complete ✅"
echo "=============================="
