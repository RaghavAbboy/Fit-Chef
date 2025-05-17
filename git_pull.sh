#!/bin/bash

# NEW: Check for arguments and set the target branch for operation
# Usage: ./git_pull.sh [target_branch_name]
if [ "$#" -gt 1 ]; then
    echo "❌ Error: Too many arguments."
    echo "Usage: ./git_pull.sh [target_branch_name]"
    exit 1
fi

SPECIFIED_TARGET_BRANCH=""
if [ "$#" -eq 1 ]; then
    SPECIFIED_TARGET_BRANCH="$1"
fi

echo "🚀 Starting git operations..."

# Fetch the latest state from the remote
echo "📡 Fetching latest state from origin..."
git fetch origin --prune # Added prune to clean up stale remote-tracking refs

TARGET_OPERATION_BRANCH="" # This will be the branch we intend to checkout and pull

if [ ! -z "$SPECIFIED_TARGET_BRANCH" ]; then
  TARGET_OPERATION_BRANCH="$SPECIFIED_TARGET_BRANCH"
  echo "ℹ️ Will operate on specified branch: '$TARGET_OPERATION_BRANCH'."
else
  # Determine the remote's default branch if no specific branch is provided
  echo "🤔 Determining remote's default branch..."
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
  if [ -z "$default_branch" ]; then
    echo "❌ Error: Could not determine the remote's default branch. Aborting."
    exit 1
  fi
  TARGET_OPERATION_BRANCH="$default_branch"
  echo "ℹ️ Will operate on remote's default branch: '$TARGET_OPERATION_BRANCH'."
fi

# Get the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ -z "$current_branch" ]; then
    echo "❌ Error: Not in a git repository or no current branch. Aborting."
    exit 1
fi
echo "ℹ️ Current local branch is '$current_branch'."

# Switch to the TARGET_OPERATION_BRANCH if not already on it
if [ "$current_branch" != "$TARGET_OPERATION_BRANCH" ]; then
  echo "🔄 Switching to target branch ('$TARGET_OPERATION_BRANCH')..."
  if git checkout "$TARGET_OPERATION_BRANCH"; then
    echo "✅ Successfully switched to branch '$TARGET_OPERATION_BRANCH'."
    # Update current_branch variable after successful checkout
    current_branch="$TARGET_OPERATION_BRANCH"
  else
    echo "❌ Error: Failed to switch to branch '$TARGET_OPERATION_BRANCH'. Please ensure the branch exists locally or on the remote (origin). Aborting."
    exit 1
  fi
else
  echo "👍 Already on the target branch ('$TARGET_OPERATION_BRANCH')."
fi

echo "🚀 Starting git pull process on branch '$current_branch'..."

# Stash any local changes
echo "📦 Stashing local changes (if any)..."
git stash

# Pull the latest changes (from origin, for the current_branch)
echo "⬇️  Pulling latest changes from origin for branch '$current_branch'..."
git pull origin "$current_branch"

# Pop the stashed changes
echo "📦 Restoring local changes (if any)..."
git stash pop

echo "✅ Done! Latest changes have been pulled for branch '$current_branch' from remote repository" 