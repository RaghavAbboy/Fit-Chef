#!/bin/bash

# Check if a commit message was provided
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "❌ Error: Please provide a commit message, and optionally a target branch name."
    echo "Usage: ./git_push.sh "your commit message" [target_branch_name]"
    exit 1
fi

# Store the commit message
COMMIT_MESSAGE="$1"
# Store the target branch if specified, otherwise it will be determined later
SPECIFIED_TARGET_BRANCH=""
if [ "$#" -eq 2 ]; then
    SPECIFIED_TARGET_BRANCH="$2"
fi

echo "🚀 Starting git operations..."

# Fetch the latest state from the remote
echo "📡 Fetching latest state from origin..."
git fetch origin

# Determine the remote's default branch
echo "🤔 Determining remote's default branch..."
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

if [ -z "$default_branch" ]; then
  echo "❌ Error: Could not determine the remote's default branch. Aborting."
  exit 1
fi
echo "ℹ️ Remote's default branch is '$default_branch'."

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ -z "$current_branch" ]; then
    echo "❌ Error: Not in a git repository or no current branch. Aborting."
    exit 1
fi
echo "ℹ️ Current local branch is '$current_branch'."

# Switch to the default branch if not already on it
if [ "$current_branch" != "$default_branch" ]; then
  echo "🔄 Switching to the default branch ('$default_branch')..."
  if git checkout "$default_branch"; then
    echo "✅ Successfully switched to branch '$default_branch'."
    # Update current_branch variable after successful checkout
    current_branch="$default_branch"
  else
    echo "❌ Error: Failed to switch to branch '$default_branch'. Please check for uncommitted changes or other issues. Aborting."
    exit 1
  fi
else
  echo "👍 Already on the default branch ('$default_branch')."
fi

# Determine the final branch to push to
branch_to_push_to="$current_branch" # Default to the current (default) branch
if [ ! -z "$SPECIFIED_TARGET_BRANCH" ]; then
    branch_to_push_to="$SPECIFIED_TARGET_BRANCH"
    echo "ℹ️ Will attempt to push to specified branch: '$branch_to_push_to'"
else
    echo "ℹ️ Will push to the current default branch: '$branch_to_push_to'"
fi

echo "🚀 Starting git push process on local branch '$current_branch', targeting remote branch '$branch_to_push_to'..."

# Stash any current changes
echo "📦 Stashing current changes..."
git stash

# Pull latest changes first (for the current local default branch)
echo "⬇️  Pulling latest changes for local branch '$current_branch' from origin..."
git pull origin "$current_branch"

# Pop the stashed changes
echo "📦 Restoring current changes..."
git stash pop

# Add all files
echo "📦 Adding all files..."
git add .

# Commit with the provided message
echo "💬 Committing with message: $COMMIT_MESSAGE"
git commit -m "$COMMIT_MESSAGE"

# Push to origin with the determined branch name
echo "⬆️  Pushing to origin '$branch_to_push_to'..."
git push origin "$branch_to_push_to"

echo "✅ Done! Changes have been pushed to remote repository" 