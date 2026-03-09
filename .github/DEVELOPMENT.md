# pxSentinel — Development & Testing Log

This document describes how pxSentinel was built, how its architecture evolved, and how each design decision was validated against real backdoor activity observed on a live FiveM server.

---

## Origin

pxSentinel began as `pxSkidDetector` — a minimal single-file resource containing a hardcoded signature list and a basic `onResourceStart` handler. While functional in concept, it had several problems that made it unsuitable for production use:

- Discord webhook URL was hardcoded directly in source code
- `string.find` calls lacked the plain-text flag, meaning any Lua metacharacter in a signature string would be silently misinterpreted as a pattern
- Scanning happened only at self-start with no coverage of post-startup dynamic resource loads
- No threading yield, which caused server thread hitches on large resource lists
- No allowlist, so system resources and legitimate frameworks produced false positives

The resource was fully rewritten under the name `pxSentinel`, retaining none of the original code.

---

## Architecture Decisions

### Config split across four files

All configuration, signatures, and allowlist entries were separated into dedicated files (`config.lua`, `blocked.lua`, `allowed.lua`) rather than inlined in `server.lua`. This makes signature maintenance and allowlist management possible without touching the core logic file. Files are listed in `fxmanifest.lua` in load order so `Config` is fully populated before `server.lua` executes.

### Plain-text signature matching

Every `string.find` call uses the fourth argument `true` to force plain-text matching:

```lua
string.find(content, signature, 1, true)
```

Without this flag, any signature containing a Lua pattern metacharacter (`.`, `*`, `+`, `(`, etc.) would not match what it was written to match. Domain names like `vac.sv` contain dots that Lua treats as "any character" in pattern mode, meaning the signature would silently match more than intended.

### Convar-based webhook

The Discord webhook is read from a server convar (`pxSentinel:webhook`) rather than stored in source. This prevents the webhook URL from appearing in git history or leaked source archives.

```
set pxSentinel:webhook "https://discord.com/api/webhooks/..."
```

### Scan timing and thread yield

The initial scan runs after a configurable settle delay (`Config.ScanDelay`, default 5000ms) to allow all resources that start before pxSentinel to fully register their file metadata with the runtime. Without this delay, `GetNumResourceMetadata` would return zero for resources still in the process of starting.

Because `LoadResourceFile` reads from disk and a server may have hundreds of resources, the scan loop yields with `Wait(0)` between iterations to release the main thread:

```lua
for i = 0, GetNumResources() - 1 do
    -- ... scan ...
    Wait(0)
end
```

Omitting this caused server thread hitch warnings of up to 4–5 seconds in testing.

### O(1) allowlist lookup

The `Config.SafeResources` list is converted to a hash set at startup:

```lua
local safeResourceSet = {}
for _, name in ipairs(Config.SafeResources) do
    safeResourceSet[name] = true
end
```

This makes the `isSafe()` check O(1) regardless of list size, compared to O(n) for an `ipairs` scan on every resource check.

### Coverage of all manifest script types

Early versions only scanned `server_script` metadata entries. This missed:

- Resources using `server_only_script` (files explicitly excluded from client delivery)
- Resources using `shared_script` (files compiled for both client and server)
- Node.js resources whose declared entry point is a thin loader that `require()`s a larger payload file not listed in the manifest at all

The scanner now iterates all three metadata keys and additionally probes a list of common secondary filenames (`index.js`, `server.js`, `main.js`, etc.) for any resource that declares at least one `.js` file.

### `onResourceFsPermissionViolation` handler

FiveM's Node.js runtime fires this event when a resource attempts a filesystem write outside its permitted scope. pxSentinel subscribes to it and treats any violation as a detection event — logging to console, sending a Discord alert, and optionally stopping the resource.

Importantly, this handler only covers filesystem writes. In-memory RCE delivered via HTTPS fetch and `eval()` executes without any filesystem interaction and will not trigger it. That class of payload must be caught at the static scan stage.

---

## Testing Against a Live Backdoor

Development occurred alongside active server operation. During this process, `redutzu-mdt` — a resource distributed through unofficial FiveM marketplace channels was discovered to contain a server-side backdoor. The following events were observed and used to harden pxSentinel iteratively.

### Initial filesystem infiltration attempt

Server logs showed `redutzu-mdt` triggering `onResourceFsPermissionViolation` with write attempts targeting:

- `txData/` — the txAdmin data directory, used to plant a persistent Node.js monitoring agent
- Core txAdmin internal files including `cl_playerlist.lua` — likely an attempt to replace a trusted file with a trojanised version

This informed the first set of filesystem-specific signatures added to `blocked.lua`:

```lua
'monitoring-agent',
'data-processor',
'system_resources',
'cl_playerlist.lua',
'cfx-server/citizen',
```

It also confirmed that `onResourceFsPermissionViolation` works as a real-time backstop for this class of attack.

### Static scan detection of `server/scanner.js`

After the filesystem signatures were added, pxSentinel's initial scan flagged `redutzu-mdt` a second time — this time for a file called `server/scanner.js` that was not the resource's declared entry point. The file contained:

1. The obfuscator.io anti-tamper loop: `while(!![]){try{`
2. An `eval()` call operating on an `_0x`-prefixed obfuscated identifier: `eval(_0x...)`

Both are signatures that are mechanically emitted by [obfuscator.io](https://obfuscator.io) and have no equivalent in any legitimate FiveM resource. They were added to `blocked.lua`:

```lua
'while(!![]){try{',
'eval(_0x',
```

The file was reached because pxSentinel probes common secondary `.js` filenames on any Node.js resource, not just declared manifest entries. `server/scanner.js` was not listed in the resource's `fxmanifest.lua` — it was injected alongside the declared files.

### Kill-switch causing server restart

When pxSentinel called `StopResource('redutzu-mdt')` on detection, the server process exited and txAdmin restarted it automatically. Investigation confirmed that the backdoor hooked the `onResourceStop` event and called `os.exit()` as a self-defence mechanism — a pattern designed to bait administrators into a restart loop.

This is a known technique: a backdoor that can resist being stopped forces administrators to either tolerate its presence or take the server fully offline to remove it. Calling `StopResource()` on an infected resource is therefore unsafe as a default response.

As a result, `Config.StopResources` was changed to default to `false`. The correct remediation procedure when pxSentinel fires is:

1. Note the infected resource from the console output or Discord alert.
2. Use txAdmin to **stop** the server entirely (not restart — a restart also fires `onResourceStop`).
3. Delete the infected resource from disk.
4. Start the server.

A console warning is printed when `StopResources = true` is set, advising of this risk.

---

## False Positives Encountered and Resolved

| Resource | Trigger | Resolution |
|---|---|---|
| `monitor` (txAdmin) | Contained `GetPlayerTokens` | Added to allowlist; removed `GetPlayerTokens` from signatures (legitimate FiveM native) |
| `webpack` / `yarn` | Contained `fs.writeFile` | Added to allowlist; removed `fs.writeFile` from signatures (standard Node.js build API) |
| All resources | Server thread hitch (up to 4.8s) | Added `Wait(0)` yield per resource in scan loop |

Each false positive was identified from live server logs and resolved by either adding the resource to `Config.SafeResources` or removing the overly-broad signature and replacing it with more specific alternatives.

---

## Signature Evaluation Criteria

Before any signature is added to `blocked.lua`, it is evaluated against two questions:

1. **Does it appear in any legitimate FiveM resource?** If yes, it is excluded or replaced with a more specific alternative.
2. **Is it unique enough to be meaningful?** A signature that matches common patterns in normal code produces noise and erodes trust in detections.

Signatures that were considered and rejected:

- `GetPlayerTokens` — legitimate FiveM native used by txAdmin
- `fs.writeFile` — standard Node.js API used by webpack and yarn
- `on('data',` — standard Node.js HTTP streaming callback, present in many legitimate resources
- `require('https')` — standard Node.js stdlib import, far too broad

---

## Versioning

pxSentinel follows semantic versioning. The resource is currently at `1.0.0-beta.1`, reflecting that the signature list and scanner behaviour are stable but subject to further refinement as new threats emerge. A `1.0.0` stable release will be cut once the signature list has been validated over a longer operational period.
