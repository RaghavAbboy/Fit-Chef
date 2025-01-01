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

# Get the current branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
if [ -z "$BRANCH_NAME" ]; then
    # If no branch exists, create main branch
    echo "📝 Initializing main branch..."
    git checkout -b main
    BRANCH_NAME="main"
fi

# Add all files
echo "📦 Adding all files..."
git add .

# Commit with the provided message
echo "💬 Committing with message: $COMMIT_MESSAGE"
git commit -m "$COMMIT_MESSAGE"

# Push to origin with the current branch name
echo "⬆️  Pushing to origin $BRANCH_NAME..."
git push origin $BRANCH_NAME

echo "✅ Done! Changes have been pushed to remote repository" 