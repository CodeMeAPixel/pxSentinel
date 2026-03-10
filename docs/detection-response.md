# Detection & Response

This page covers what happens when pxSentinel detects a backdoor signature, the kill-switch problem, and the recommended response workflow.

---

## What pxSentinel Does on Detection

When one or more signatures are matched, pxSentinel executes the following steps in order:

### 1. Console report

If `Config.ConsolePrint` is `true`, a structured report is printed to the server console grouped by resource:

```
──────────────────────────────────────────────────────────────
 !! 2 BACKDOOR SIGNATURE(S) DETECTED !!
──────────────────────────────────────────────────────────────
  Resource : redutzu-mdt
    File      : server/scanner.js
    Signature : while(!![]){try{
    File      : server/scanner.js
    Signature : eval(_0x

──────────────────────────────────────────────────────────────
  NEXT STEPS
  ──────────────────────────────────────────────────────────
  1. Note which resource(s) are listed above.
  2. Do NOT keep these resources on a live server.
  3. Remove or replace the infected resource(s) immediately.
  4. Audit your server files for any other unauthorised changes.
  5. Rotate your server license key and any API tokens.
  6. Identify and remove whoever added the infected resource.
──────────────────────────────────────────────────────────────
```

### 2. Discord alert

If `Config.Discord.Enabled` is `true` and a webhook URL is set, pxSentinel sends a formatted embed containing each detection's resource name, file path, and matched signature.

### 3. Stop resources (optional)

If `Config.StopResources` is `true`, pxSentinel calls `StopResource()` on each infected resource. **Read the kill-switch section below before enabling this.**

### 4. Halt server (optional)

If `Config.StopServer` is `true`, pxSentinel waits 3 seconds (to allow the Discord request to dispatch) then calls `os.exit(1)`.

---

## The Kill-Switch Problem

Some sophisticated backdoors hook the `onResourceStop` event and call `os.exit()` as a self-defense mechanism. When `Config.StopResources` is enabled, calling `StopResource()` on the infected resource fires that hook, terminates the server process, and causes txAdmin to interpret the exit as a crash — automatically restarting the server with the backdoor still present.

This is not hypothetical. This exact sequence was observed live during development (see [DEVELOPMENT.md](../.github/DEVELOPMENT.md)). It is the reason `Config.StopResources` defaults to `false`.

---

## Recommended Response Workflow

When pxSentinel fires a detection:

1. **Note the infected resource name** from the console output or Discord alert. Do not dismiss the alert.

2. **Stop the server via txAdmin** using the Stop button — not Restart. A restart would fire `onResourceStop` on the backdoor before it is removed, potentially triggering the kill-switch.

3. **Delete the infected resource** from your server's `resources` directory. Do not simply disable it — leave it in place and you will have no guarantee it cannot be re-enabled.

4. **Audit your server files** for any files that do not belong. Check `txData/` and the directories used by the `monitor` resource for unexpected files, particularly hidden agents or overwritten core files.

5. **Rotate credentials:**
   - FiveM server license key
   - Database credentials
   - txAdmin password
   - Discord webhook URLs
   - Any API tokens present in your server environment

6. **Identify how the resource was introduced.** Determine who added it, through what channel, and whether any other resources from the same source are present.

7. **Source a clean replacement** for any legitimate resource that was infected. Verify it against the original repository before running it again.

---

## Filesystem Permission Violations

pxSentinel also listens for `onResourceFsPermissionViolation`, which FiveM's Node.js runtime fires when a resource attempts a filesystem write outside its permitted scope. This event is treated as a detection:

```
──────────────────────────────────────────────────────────────
 !! FILESYSTEM PERMISSION VIOLATION DETECTED !!
──────────────────────────────────────────────────────────────
  Resource  : redutzu-mdt
  Permission: write
  Path      : txData/monitor-agent.js

  This resource attempted a filesystem operation outside its
  permitted scope. This is a strong indicator of a backdoor.
  Remove this resource immediately and audit your server files.
──────────────────────────────────────────────────────────────
```

Follow the same response workflow above. A filesystem permission violation is typically a sign of an active intrusion attempt — the backdoor is attempting to plant a persistent agent or overwrite a trusted file.

> This event only covers filesystem writes. Payloads delivered via HTTPS fetch and executed in memory using `eval()` will not trigger it. Both detection mechanisms are complementary.

---

## False Positives

If pxSentinel flags a resource you believe is legitimate:

1. Confirm the matched signature and the file path in the console output.
2. Inspect the flagged file manually to verify whether the match is a false positive.
3. If the resource is genuinely safe, add it to `Config.SafeResources` in `shared/allowed.lua` to exclude it from future scans.
4. If the signature is producing false positives against a broad class of legitimate code, consider whether it should be removed or made more specific, and open an issue on the repository.

Do not add resources to the allow list without inspecting them first. The allow list bypasses scanning entirely.
