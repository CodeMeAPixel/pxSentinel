# How It Works

This page describes the scanning architecture, detection flow, and runtime behaviour of pxSentinel in detail.

---

## Startup Sequence

When the server starts, pxSentinel is loaded last (by design — see [Installation](installation.md)). It listens for its own `onResourceStart` event, then:

1. Waits `Config.ScanDelay` milliseconds for other resources to finish registering their file metadata.
2. Runs a full scan of every loaded resource.
3. Begins listening for `onResourceStart` events to scan any resource started dynamically after that point.

The settle delay exists because `GetNumResourceMetadata` returns zero for resources that are still in the process of starting. Without the delay, resources that start in parallel with pxSentinel would appear to have no files.

---

## The Allow List

Before any file reading occurs, pxSentinel checks whether a resource is on the allow list. The `Config.SafeResources` list is converted to a hash set at startup:

```lua
local safeResourceSet = {}
for _, name in ipairs(Config.SafeResources) do
    safeResourceSet[name] = true
end
```

The `isSafe()` check is O(1) regardless of list size. Any resource on this list — or pxSentinel itself — is skipped entirely, without reading any files.

---

## File Discovery

For each resource that is not on the allow list, pxSentinel reads files from three manifest metadata keys:

| Metadata key | What it covers |
|---|---|
| `server_script` | Files compiled for and delivered to the server |
| `server_only_script` | Files explicitly excluded from client delivery |
| `shared_script` | Files compiled for both client and server |

All three are scanned to prevent evasion through less common manifest declarations.

### Node.js resource probing

If any declared file for a resource ends in `.js`, pxSentinel additionally probes a list of common secondary filenames that are frequently used by Node.js payloads but are not declared in the manifest:

```
index.js, server.js, main.js, app.js,
src/index.js, src/server.js, src/main.js,
lib/index.js, lib/server.js
```

This catches cases where the declared entry point is a thin loader that `require()`s the actual payload from an undeclared file.

### Deduplication

Each file path is tracked in a `scannedPaths` table so that files declared under multiple metadata keys are not read or scanned more than once.

---

## Signature Matching

Each file's content is checked against every entry in `Config.Signatures` using:

```lua
string.find(content, signature, 1, true)
```

The fourth argument (`true`) forces plain-text matching. Lua pattern metacharacters in signature strings are always treated as literals. This is essential for domain-style signatures that contain dots, which Lua would otherwise interpret as "any character" in pattern mode.

---

## Thread Yielding

The full scan loop yields with `Wait(0)` between each resource:

```lua
for i = 0, GetNumResources() - 1 do
    -- scan resource
    Wait(0)
end
```

This releases the main server thread between iterations. Without this yield, scanning a large resource list causes server thread hitch warnings of several seconds.

---

## Runtime Scanning

After the initial scan completes, pxSentinel listens for `onResourceStart`. When a new resource starts:

- If the initial scan has not yet finished (resource started during the settle window), no additional scan is run — the upcoming full scan will cover it.
- If the initial scan is complete, the newly started resource is scanned immediately.

This ensures no resource escapes detection by starting after the initial scan.

---

## Detection Flow

When one or more detections are found, pxSentinel calls `handleDetections()`:

1. **Console report** — If `Config.ConsolePrint` is `true`, prints a formatted report grouped by resource. Each entry includes the resource name, file path, matched signature, and a numbered remediation checklist.

2. **Discord alert** — If `Config.Discord.Enabled` is `true` and a webhook URL is configured, sends a formatted embed containing all detections.

3. **Stop resources** — If `Config.StopResources` is `true`, calls `StopResource()` on each infected resource. See the [kill-switch warning](detection-response.md#the-kill-switch-problem).

4. **Halt server** — If `Config.StopServer` is `true`, waits 3 seconds (to allow the Discord request to complete) and calls `os.exit(1)`.

---

## Filesystem Permission Violations

FiveM's Node.js runtime fires `onResourceFsPermissionViolation` when a resource attempts a filesystem write outside its permitted scope. pxSentinel subscribes to this event and treats any violation as a detection — logging to the console, sending a Discord alert, and optionally stopping the resource.

> **Important:** This event only covers filesystem writes. In-memory RCE delivered via HTTPS fetch and `eval()` executes without any filesystem interaction and does not trigger this event. That class of payload must be caught by the static signature scan.

---

## What pxSentinel Does Not Cover

- **Client-side scripts** — Only server-side and shared script files are scanned. Client-side backdoors require a different detection approach.
- **Runtime-fetched payloads** — If a malicious resource fetches and executes code dynamically via `fetch` or `PerformHttpRequest` after startup, that code is not visible to the static scanner. The `onResourceFsPermissionViolation` handler partially mitigates this by catching filesystem write attempts that typically follow RCE.
- **Encrypted or obfuscated content with no known signatures** — The scanner matches against known strings. Novel or heavily obfuscated payloads without any signature entries will not be detected.
