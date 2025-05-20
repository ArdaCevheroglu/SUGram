#!/bin/bash
# Script to deploy Firebase rules

echo "Deploying Firebase Storage rules..."

# You need to have Firebase CLI installed for this to work
# If you don't have it installed, you can comment this out and handle the deployment manually

# Deploy storage rules
firebase deploy --only storage

echo "Rules deployment complete!"