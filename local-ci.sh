#!/bin/bash
set -euo pipefail

echo "=== Swift Build ==="
swift build --package-path Speakeasy

echo "=== Swift Tests ==="
swift test --package-path Speakeasy

echo "=== All checks passed ==="
