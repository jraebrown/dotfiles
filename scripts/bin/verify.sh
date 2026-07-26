#!/usr/bin/env zsh
set -e

echo "🔍 Generating file manifest…"
find . -type f -exec shasum {} \; > manifest.sha

echo "📦 Verifying files…"
shasum -c manifest.sha
