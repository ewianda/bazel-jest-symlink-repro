#!/usr/bin/env bash
set -euo pipefail

echo "=== Bazel + Jest Symlink Dual-React Reproduction ==="
echo ""

# Step 1: Ensure deps are installed
echo "--- Step 1: Installing dependencies ---"
pnpm install --frozen-lockfile 2>&1 | tail -1

# Step 2: Test with host node_modules present
echo ""
echo "--- Step 2: Running test WITH host node_modules (should PASS) ---"
echo "    Host node_modules acts as fallback when symlinks escape sandbox."
if bazel test //src:hook.test --test_output=short 2>&1 | grep -q "PASSED"; then
  echo "    ✅ PASSED (as expected — Jest resolves react from host node_modules)"
else
  echo "    ❌ FAILED (unexpected)"
fi

# Step 3: Delete host node_modules
echo ""
echo "--- Step 3: Deleting host node_modules ---"
rm -rf node_modules

# Step 4: Test without host node_modules
echo ""
echo "--- Step 4: Running test WITHOUT host node_modules (should FAIL) ---"
echo "    Without host node_modules, symlink escape has nowhere to resolve."
if bazel test //src:hook.test --test_output=short 2>&1 | grep -q "PASSED"; then
  echo "    ✅ PASSED (unexpected — sandbox isolation is working correctly)"
else
  echo "    ❌ FAILED (as expected — Cannot find module 'react')"
  echo ""
  echo "    Root cause: src/hook.ts in runfiles is a symlink to the source tree."
  echo "    Node's require() follows the symlink to the host path, then walks up"
  echo "    looking for node_modules/react from there. Without host node_modules,"
  echo "    it can't find react. The sandbox's node_modules is never checked."
fi

# Step 5: Restore
echo ""
echo "--- Step 5: Restoring node_modules ---"
pnpm install --frozen-lockfile 2>&1 | tail -1

# Step 6: Show the symlink
echo ""
echo "--- Step 6: Proof — source file is a symlink in runfiles ---"
RUNFILES=$(find $(bazel info output_base 2>/dev/null) -path "*/hook.test.runfiles/_main/src/hook.ts" 2>/dev/null | head -1)
if [ -n "$RUNFILES" ]; then
  echo "    Runfiles path: $RUNFILES"
  echo "    Symlink target: $(readlink -f "$RUNFILES")"
  echo ""
  echo "    The file is a symlink to the host source tree."
  echo "    require('react') resolves from the symlink target's directory,"
  echo "    not from the runfiles directory where node_modules lives."
else
  echo "    (Run 'bazel test //src:hook.test' first to populate runfiles)"
fi

echo ""
echo "=== Done ==="
echo ""
echo "Workaround: Add moduleDirectories to jest.config.js pointing to"
echo "the runfiles node_modules via RUNFILES_DIR environment variable."
