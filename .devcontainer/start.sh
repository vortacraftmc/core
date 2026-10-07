#!/bin/bash
# postStartCommand: runs every time the Codespace starts (even without a rebuild).
set -e

echo "🔄 Running post-start initialization..."

# 1. Show the current Git branch and working tree status
echo "📊 Git Status Check:"
if git rev-parse --is-inside-work-tree &>/dev/null; then
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo "  Current branch: $CURRENT_BRANCH"
  git status -s
else
  echo "  Not a git repository."
fi

# 2. Make sure the Gradle wrapper is executable
if [ -f "gradlew" ]; then
  chmod +x gradlew
  echo "🐘 Gradle wrapper permissions verified."
fi

# 3. Check the GitHub CLI authentication state
if command -v gh &>/dev/null; then
  if gh auth status &>/dev/null; then
    echo "🔑 GitHub CLI: Authenticated successfully."
  else
    echo "⚠️ GitHub CLI: Not authenticated or token expired."
  fi
fi

echo "✨ Post-start tasks completed successfully!"
