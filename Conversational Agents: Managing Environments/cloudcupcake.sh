#!/bin/bash
# Conversational Agents: Managing Environments - ES version
set -e

echo "=============================="
echo " Conversational Agents Lab Setup "
echo "=============================="

PROJECT_ID=$(gcloud config get-value project)
REGION="global"

echo "Your active configuration is: $(gcloud config configurations list --filter=is_active:true --format="value(name)")"
echo "Using Project: $PROJECT_ID"
echo "Region: $REGION"
echo "=============================="

# 1. Enable Dialogflow API
echo "1. Enabling Dialogflow API..."
gcloud services enable dialogflow.googleapis.com

# 2. Create Flight Booker Agent (Dialogflow ES)
echo "2. Creating Flight Booker Agent..."
gcloud alpha dialogflow agent create \
  --project=$PROJECT_ID \
  --display-name="Flight Booker" \
  --default-language-code="en" \
  --time-zone="America/Los_Angeles"

echo "Agent created."

# 3. Import intents/entities from sample blob
echo "3. Restoring agent from provided blob..."
gsutil cp gs://cloud-training/dialogflow/es/flight-booker-agent.zip ./agent.zip

gcloud alpha dialogflow agent import \
  --source=./agent.zip \
  --project=$PROJECT_ID \
  --quiet

echo "Agent imported successfully."

# 4. Training Agent
echo "4. Training the agent..."
gcloud alpha dialogflow agent train --project=$PROJECT_ID

echo "=============================="
echo " 🎉 Lab Automation Complete for Dialogflow ES "
echo "=============================="
