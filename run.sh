#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building and running Speakeasy..."
swift run --package-path Speakeasy
