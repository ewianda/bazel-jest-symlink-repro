#!/usr/bin/env bash
set -euo pipefail

echo "=== Step 1: Install deps ==="
pnpm install --frozen-lockfile

echo ""
echo "=== Step 2: Test with host node_modules (should PASS) ==="
bazel test //src:hook.test --test_output=short || true

echo ""
echo "=== Step 3: Delete host node_modules ==="
rm -rf node_modules

echo ""
echo "=== Step 4: Test without host node_modules (should FAIL) ==="
bazel test //src:hook.test --test_output=short || true

echo ""
echo "=== Step 5: Restore ==="
pnpm install --frozen-lockfile
