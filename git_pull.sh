#!/bin/bash

echo "🚀 Starting git pull process..."

# Get the current branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
if [ -z "$BRANCH_NAME" ]; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Stash any local changes
echo "📦 Stashing local changes (if any)..."
git stash

# Pull the latest changes
echo "⬇️  Pulling latest changes from origin $BRANCH_NAME..."
git pull origin $BRANCH_NAME

# Pop the stashed changes
echo "📦 Restoring local changes (if any)..."
git stash pop

echo "✅ Done! Latest changes have been pulled from remote repository" 