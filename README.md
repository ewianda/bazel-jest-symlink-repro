# Bazel + Jest Symlink Dual-React Reproduction

## Problem

When running Jest tests via `rules_jest` in Bazel's local sandbox, source files
are symlinks to the host filesystem. Node's `require()` follows the symlink and
resolves `node_modules` from the host path instead of the sandbox. This causes
**two React instances** to be loaded:

1. **Sandbox React** — from `$RUNFILES/_main/node_modules/react` (via Bazel deps)
2. **Host React** — from `$HOST_PROJECT/node_modules/react` (via symlink resolution)

React context (`useContext`) returns `null` because the provider and consumer
use different React instances.

## Reproduction

```bash
# Install deps
pnpm install

# Run the test — PASSES (host node_modules available)
bazel test //src:hook.test

# Delete host node_modules to see the sandbox-only behavior
rm -rf node_modules

# Run again — FAILS with "Cannot find module 'react'"
bazel test //src:hook.test

# Reinstall
pnpm install

# The test passes but only because Jest escapes the sandbox via symlinks
# and finds react from the host. In the sandbox, the source files are
# symlinks, and require() resolves from the symlink's real path.
```

## Root Cause

In `rules_jest`, the test runner's runfiles contain:
- `node_modules/react` — the Bazel-managed copy
- `src/hook.ts` — a **symlink** to `/host/path/src/hook.ts`

When Jest loads `src/hook.ts`, Node resolves the symlink to the host path.
Then `require('react')` inside the imported module walks up from the host
path looking for `node_modules/react`, finding the host copy instead of
the sandbox copy.

Two React instances → `useContext` returns `null` → tests fail.

## Expected Behavior

Source files in runfiles should either:
1. Be real files (copies), not symlinks
2. Or Jest/Node should resolve modules from the runfiles path, not the symlink target

## Workaround

Add `moduleDirectories` to `jest.config.js` to include the runfiles `node_modules`:

```js
const bazelRunfilesDir = process.env.RUNFILES_DIR
  ? require('path').join(process.env.RUNFILES_DIR, '_main')
  : null

module.exports = {
  rootDir: bazelRunfilesDir || process.cwd(),
  moduleDirectories: [
    'node_modules',
    ...(bazelRunfilesDir ? [require('path').join(bazelRunfilesDir, 'node_modules')] : []),
  ],
}
```
