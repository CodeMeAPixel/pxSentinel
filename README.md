# pxSentinel

[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![FiveM](https://img.shields.io/badge/Platform-FiveM-orange)](https://fivem.net)
[![Version](https://img.shields.io/badge/Version-1.0.0--beta.1-green)](https://github.com/CodeMeAPixel/pxSentinel/releases)

**Server-side malware scanner for FiveM.** pxSentinel scans all loaded resources for known backdoor and malware signatures, logs detailed detection reports with remediation guidance to the console, alerts your team via Discord, and optionally stops infected resources or halts the server.

---

## Features

| | |
|---|---|
| **Full startup scan** | Scans every loaded resource once the server finishes starting. |
| **Runtime detection** | Monitors dynamically started resources throughout the session. |
| **Immediate containment** | Stops infected resources without requiring a full server restart. |
| **Discord alerting** | Sends a formatted embed to a configured webhook on any detection. |
| **Allow list** | Trusted resources are excluded from scanning entirely. |
| **Safe matching** | Plain-text signature matching — Lua pattern characters are always treated as literals. |

---

## Requirements

- FiveM server artifact `22934` or newer
- Lua 5.4 (`lua54 'yes'` in `fxmanifest.lua`)

---

## Installation

1. Clone or download this repository into your server's `resources` directory and name the folder `pxSentinel`.

2. Add the following line to the **end** of your `server.cfg`, after all other resources:
   ```
   ensure pxSentinel
   ```
   > Placing pxSentinel last ensures all other resources have registered before the scan runs.

3. Configure your Discord webhook via a server convar (recommended — keeps credentials out of source files):
   ```
   set pxSentinel:webhook "https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE"
   ```

4. Review `config.lua`, `blocked.lua`, and `allowed.lua` and adjust them to suit your server.

---

## Configuration

Configuration is split across three files to keep concerns separate.

### `config.lua` — General settings

| Option | Type | Default | Description |
|---|---|---|---|
| `Config.Enable` | `boolean` | `true` | Enable or disable the scanner entirely. |
| `Config.ConsolePrint` | `boolean` | `true` | Print a formatted detection report and remediation steps to the console. |
| `Config.StopResources` | `boolean` | `false` | Stop each infected resource immediately upon detection. See warning below. |
| `Config.StopServer` | `boolean` | `false` | Halt the server after all detections are handled. |
| `Config.ScanDelay` | `number` | `5000` | Milliseconds to wait before the initial scan runs. Increase for large resource lists. |
| `Config.Discord.Enabled` | `boolean` | `true` | Send a Discord alert on detection. |
| `Config.Discord.Webhook` | `string` | `""` | Webhook URL. Prefer the `pxSentinel:webhook` convar over hardcoding. |

> [!WARNING]
> **Kill-switch backdoors** — Some backdoors hook `onResourceStop` and call `os.exit()` as a self-defense mechanism. When `Config.StopResources` is enabled, pxSentinel calls `StopResource()` on infected resources, which fires that hook, terminates the server process, and causes txAdmin to treat it as a crash — automatically restarting with the backdoor potentially still in place.
>
> **Recommended response when a detection fires:**
> 1. Note the infected resource name from the console output or Discord alert.
> 2. Use txAdmin to **stop** the server (not restart).
> 3. Delete the infected resource from your server directory.
> 4. Start the server again.
>
> Enable `Config.StopResources` only if you have confirmed no kill-switch is present, or if you accept the risk of an automatic txAdmin restart.

> [!NOTE]
> When both `Config.StopResources` and `Config.StopServer` are enabled, pxSentinel stops each infected resource first, then halts the server after the Discord alert has been dispatched.

---

### `blocked.lua` — Malware signatures

Defines `Config.Signatures`, a list of plain-text strings matched against every server script in every loaded resource. Entries are grouped by category: known panel domains, C2 infrastructure, exfiltration patterns, and obfuscator watermarks.

To add a signature, append it to the list:

```lua
Config.Signatures = {
    -- existing entries ...
    'my-malicious-string',
}
```

All entries must be plain strings. Lua pattern metacharacters (`.`, `%`, `(`, `)`, etc.) are always treated as literals.

---

### `allowed.lua` — Safe resources

Defines `Config.SafeResources`, a list of resource folder names that pxSentinel will never scan. Any listed resource is skipped without reading any of its files.

The default list covers CFx platform resources, the ox stack, QBCore, ESX, and common trusted standalone resources. Add your own at the bottom:

```lua
Config.SafeResources = {
    -- existing entries ...
    'my-trusted-resource',
}
```

> Use the exact resource folder name. Wildcards are not supported.

---

## How It Works

On start, pxSentinel waits `Config.ScanDelay` milliseconds for all resources to finish registering, then iterates every loaded resource, reads each declared server script file, and checks its content against every signature in `Config.Signatures` using plain-text matching. Resources listed in `Config.SafeResources` are skipped entirely.

**On a positive detection, pxSentinel:**

1. Groups findings by resource and prints a report to the console — resource name, file path, matched signature, and recommended remediation steps.
2. Sends a Discord embed alert to the configured webhook.
3. Calls `StopResource()` on the infected resource if `Config.StopResources` is enabled.
4. Calls `os.exit(1)` to halt the server if `Config.StopServer` is enabled.

After the initial scan, pxSentinel listens for `onResourceStart` and scans any resource started dynamically at runtime. Resources that start within the settle window are covered by the full scan and are not scanned twice.

---

## Keeping Signatures Up to Date

The built-in signature list targets known backdoor panels, C2 domains, exfiltration patterns, and obfuscator watermarks at the time of release. `blocked.lua` is updated in the repository as new threats are identified.

To contribute a signature, open a pull request with the string, a brief description of what it targets, and any known hex-encoded variants.

---

## Further Reading

| Document | Description |
|---|---|
| [BACKDOORS.md](.github/BACKDOORS.md) | Catalogue of real backdoor samples with structural analysis, detection signatures, and remediation steps. |
| [DEVELOPMENT.md](.github/DEVELOPMENT.md) | Architecture decisions, design rationale, and an account of how pxSentinel was hardened against a live backdoor during development. |
| [SECURITY.md](.github/SECURITY.md) | Supported versions and the responsible disclosure process for reporting vulnerabilities in pxSentinel itself. |

---

## License

[AGPL-3.0-or-later](LICENSE)
