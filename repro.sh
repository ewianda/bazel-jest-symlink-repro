#!/usr/bin/env bash
set -euo pipefail

echo "=== Bazel + Jest Symlink Dual-React Reproduction ==="
echo ""
echo "This demonstrates how jest.mock() in a Bazel sandbox causes"
echo "two React instances, breaking useContext/hooks."
echo ""

# Step 1: Ensure deps are installed
echo "--- Step 1: Installing dependencies ---"
pnpm install --frozen-lockfile 2>&1 | tail -1

# Step 2: Clean bazel cache
echo ""
echo "--- Step 2: Cleaning Bazel cache ---"
bazel clean 2>&1 | tail -1

# Step 3: Run the test
echo ""
echo "--- Step 3: Running test ---"
echo "    The test does jest.mock('./store') which forces Jest to resolve"
echo "    store.ts via symlink → host path → host node_modules/react."
echo "    Meanwhile @testing-library/react uses sandbox node_modules/react."
echo "    Two React instances → useContext returns null."
echo ""

TEST_OUTPUT=$(bazel test //src:hook.test --test_output=all 2>&1)
if echo "$TEST_OUTPUT" | grep -q "PASSED"; then
  echo "    ✅ PASSED"
  echo ""
  echo "    The test passed because host node_modules/react and sandbox"
  echo "    node_modules/react resolved to the same physical files."
  echo "    Try deleting node_modules to see the failure:"
  echo "      rm -rf node_modules && bazel test //src:hook.test"
elif echo "$TEST_OUTPUT" | grep -q "useContext"; then
  echo "    ❌ FAILED: TypeError: Cannot read properties of null (reading 'useContext')"
  echo ""
  echo "    This is the dual-React bug. Two React instances are loaded:"
  echo "    1. Sandbox: runfiles/_main/node_modules/react (via Bazel deps)"
  echo "    2. Host: /host/path/node_modules/react (via symlink resolution)"
  echo ""
  echo "    React context set by instance #1 is invisible to instance #2."
elif echo "$TEST_OUTPUT" | grep -q "Cannot find module"; then
  echo "    ❌ FAILED: Cannot find module"
  echo "$TEST_OUTPUT" | grep "Cannot find module" | head -1
  echo ""
  echo "    The symlinked source file resolved to the host path,"
  echo "    but node_modules doesn't exist there."
else
  echo "    ❌ FAILED with unexpected error:"
  echo "$TEST_OUTPUT" | grep -E "error|Error|FAIL" | head -5
fi

# Step 4: Show proof
echo ""
echo "--- Step 4: Symlink proof ---"
RUNFILES=$(find "$(bazel info output_base 2>/dev/null)" -path "*/hook.test.runfiles/_main/src/hook.ts" 2>/dev/null | head -1)
if [ -n "$RUNFILES" ]; then
  echo "    Runfiles: $RUNFILES"
  echo "    Target:   $(readlink "$RUNFILES" 2>/dev/null || echo 'not a symlink')"
  echo ""
  if [ -L "$RUNFILES" ]; then
    echo "    ⚠ Source file is a SYMLINK in runfiles."
    echo "    Node's require() resolves modules from the symlink target's"
    echo "    directory, not the runfiles directory."
  fi
else
  echo "    (Could not find runfiles — run the test first)"
fi

echo ""
echo "=== Workaround ==="
echo "Add to jest.config.js:"
echo '  const bazelRunfilesDir = process.env.RUNFILES_DIR'
echo '    ? require("path").join(process.env.RUNFILES_DIR, "_main") : null'
echo '  moduleDirectories: ['
echo '    "node_modules",'
echo '    ...(bazelRunfilesDir ? [path.join(bazelRunfilesDir, "node_modules")] : []),'
echo '  ]'
