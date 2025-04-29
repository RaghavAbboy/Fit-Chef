#!/bin/bash

# Amplify App ID
APP_ID="d1k4ggaq86w9ev"
BRANCH="main"

echo "Starting deployment to AWS Amplify..."
echo "App ID: $APP_ID"
echo "Branch: $BRANCH"

# Start the deployment job
aws amplify start-job --app-id $APP_ID --branch-name $BRANCH --job-type RELEASE

echo "Deployment job started. Check AWS Amplify Console for build status." 