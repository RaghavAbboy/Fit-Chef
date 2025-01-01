#!/bin/bash

# Check if a commit message was provided
if [ "$#" -ne 1 ]; then
    echo "❌ Error: Please provide a commit message"
    echo "Usage: ./git_push.sh \"your commit message\""
    exit 1
fi

# Store the commit message
COMMIT_MESSAGE="$1"

echo "🚀 Starting git push process..."

# Add all files
echo "📦 Adding all files..."
git add .

# Commit with the provided message
echo "💬 Committing with message: $COMMIT_MESSAGE"
git commit -m "$COMMIT_MESSAGE"

# Push to origin master
echo "⬆️  Pushing to origin master..."
git push origin master

echo "✅ Done! Changes have been pushed to remote repository" 