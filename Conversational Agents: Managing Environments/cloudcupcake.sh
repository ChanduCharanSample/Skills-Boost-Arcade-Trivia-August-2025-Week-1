#!/bin/bash
# cloudcupcake.sh - Full automation for Conversational Agents: Managing Environments (Task 1)

echo "=============================="
echo "🚀 Starting Lab Setup..."
echo "Project ID: $DEVSHELL_PROJECT_ID"
echo "Region: global"
echo "Session: test-$RANDOM"
echo "=============================="

# 1. Set default project
echo "1️⃣ Setting default project..."
gcloud config set project $DEVSHELL_PROJECT_ID

# 2. Enable required APIs
echo "2️⃣ Enabling required APIs..."
gcloud services enable dialogflow.googleapis.com

# 3. Download provided agent blob (replace with correct lab blob URL)
echo "3️⃣ Downloading agent blob..."
curl -s -o agent-blob.json \
  https://raw.githubusercontent.com/ChanduCharanSample/Skills-Boost-Arcade-Trivia-August-2025-Week-1/main/Conversational%20Agents:%20Managing%20Environments/agent-blob.json

if [[ ! -f agent-blob.json ]]; then
  echo "❌ Agent blob download failed. Please check URL."
  exit 1
fi

# 4. Create Flight Booker Agent
echo "4️⃣ Creating Flight Booker Agent..."
AGENT_ID=$(gcloud alpha dialogflow agents create \
  --display-name="Flight Booker Agent" \
  --default-language-code="en" \
  --time-zone="America/Los_Angeles" \
  --location="global" \
  --project="$DEVSHELL_PROJECT_ID" \
  --format="value(name)")

echo "✅ Agent created: $AGENT_ID"

# 5. Restore agent from the blob
echo "5️⃣ Restoring agent configuration..."
gcloud alpha dialogflow agents restore \
  --agent="$AGENT_ID" \
  --agent-content-file=agent-blob.json \
  --project="$DEVSHELL_PROJECT_ID"

# 6. Confirmation
echo "=============================="
echo "🎉 Task 1 Complete: Agent setup done!"
echo "You can now continue with the Dialogflow CX lab."
echo "=============================="
