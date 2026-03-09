# pxSentinel

[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![FiveM](https://img.shields.io/badge/Platform-FiveM-orange)](https://fivem.net)
[![Version](https://img.shields.io/badge/Version-1.0.0--beta.1-green)](https://github.com/CodeMeAPixel/pxSentinel/releases)

pxSentinel is a server-side FiveM resource that scans all loaded resources for known backdoor and malware signatures. When a match is found, it logs a detailed report to the console with remediation guidance, stops the infected resource, and optionally halts the server entirely.

---

## Features

* Performs a full scan of every loaded resource after the server finishes starting
* Continues scanning any resource that is started dynamically at runtime
* Stops infected resources immediately without requiring a full server shutdown
* Sends a formatted Discord embed alert via webhook on any detection
* Configurable allow list so trusted resources are never unnecessarily scanned
* Uses plain-text signature matching — Lua pattern characters in signatures are always treated as literals

---

## Requirements

* FiveM server running artifact 5181 or newer
* Lua 5.4 (`lua54 'yes'` in `fxmanifest.lua`)

---

## Installation

1. Download or clone this repository into your server's `resources` directory.
2. Ensure the folder is named `pxSentinel`.
3. Add the following line to the **end** of your `server.cfg`, after all other resources:
   ```
   ensure pxSentinel
   ```
   Placing it last gives all other resources time to register before the scan runs.

4. Set your Discord webhook via a server convar (recommended — keeps the URL out of source files):
   ```
   set pxSentinel:webhook "https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE"
   ```

5. Review `config.lua`, `blocked.lua`, and `allowed.lua` and adjust them to suit your server.

---

## Configuration

Configuration is split across three files to keep concerns separate.

### config.lua

General behaviour settings.

| Option | Type | Default | Description |
|---|---|---|---|
| `Config.Enable` | `boolean` | `true` | Enable or disable the scanner entirely. |
| `Config.ConsolePrint` | `boolean` | `true` | Print a formatted detection report and remediation steps to the server console. |
| `Config.StopResources` | `boolean` | `false` | Stop each infected resource immediately upon detection. **Disabled by default** — see warning below. |
| `Config.StopServer` | `boolean` | `false` | Halt the entire server after handling detections. Use only if you require zero tolerance. |
| `Config.ScanDelay` | `number` | `5000` | Milliseconds to wait before the initial full scan runs. Allows all resources time to register their file metadata. Increase this for servers with very large resource lists. |
| `Config.Discord.Enabled` | `boolean` | `true` | Send a Discord alert when a detection occurs. |
| `Config.Discord.Webhook` | `string` | `""` | Webhook URL. Prefer setting this via the `pxSentinel:webhook` convar rather than hardcoding it. |

> **Warning — kill-switch backdoors:** Some sophisticated backdoors hook the `onResourceStop` event and call `os.exit()` as a self-defence mechanism when they detect they are being stopped. Enabling `Config.StopResources` causes pxSentinel to call `StopResource()` on the infected resource, which fires that hook, kills the server process, and causes txAdmin to interpret the exit as a crash and automatically restart the server — potentially with the backdoor still present.
>
> **Recommended workflow when a detection fires:**
> 1. Note which resource is infected (console output + Discord alert).
> 2. Use txAdmin to **stop** the server (not restart).
> 3. Delete the infected resource from your server folder.
> 4. Start the server again.
>
> Set `Config.StopResources = true` only if you have confirmed no kill-switch is present, or if you accept the risk of an automatic txAdmin restart.

**Note:** If both `Config.StopResources` and `Config.StopServer` are `true`, pxSentinel stops each infected resource first and then halts the server after the Discord alert has been dispatched.

---

### blocked.lua

Defines `Config.Signatures`, a list of plain-text strings that are scanned against the contents of every server script file in every loaded resource.

Entries are grouped by category — known panel domains, C2 infrastructure, exfiltration patterns, and common obfuscator watermarks.

To add your own signatures, append them to the list:

```lua
Config.Signatures = {
    -- existing entries ...
    'my-malicious-string',
}
```

All entries must be plain strings. Lua pattern metacharacters such as `.`, `%`, `(`, and `)` are always treated as literals and will never cause false positives or matching errors.

---

### allowed.lua

Defines `Config.SafeResources`, a list of resource folder names that pxSentinel will never scan. Any resource on this list is skipped entirely, without reading any of its files.

The list includes the CFx platform resources, the ox stack, QBCore, ESX, and a set of common trusted standalone resources out of the box. Add your own trusted resources at the bottom of the list:

```lua
Config.SafeResources = {
    -- existing entries ...
    'my-trusted-resource',
}
```

Use the exact resource folder name. Wildcards are not supported.

---

## How It Works

When pxSentinel starts, it waits for `Config.ScanDelay` milliseconds to allow all other resources to finish registering their metadata. It then iterates every loaded resource, reads each declared server script file, and checks the file content against every entry in `Config.Signatures` using plain-text matching.

Resources listed in `Config.SafeResources` are excluded from scanning entirely.

On a positive detection, pxSentinel:

1. Groups all findings by resource and prints a formatted report to the console, including the resource name, file path, matched signature, and a numbered list of recommended remediation steps.
2. Sends a Discord embed alert to the configured webhook.
3. Calls `StopResource()` on each infected resource if `Config.StopResources` is enabled. Note that backdoors with an `onResourceStop` kill-switch will call `os.exit()` at this point — see the warning in the configuration table above.
4. Calls `os.exit(1)` to halt the server if `Config.StopServer` is enabled.

After the initial scan completes, pxSentinel listens for the `onResourceStart` event and scans any resource that starts dynamically at runtime. Resources that start during the initial settle window are already covered by the full scan and are not scanned twice.

---

## Keeping Signatures Up to Date

The built-in signature list covers known backdoor panels, C2 domains, exfiltration patterns, and obfuscator watermarks at the time of release. As new threats emerge, `blocked.lua` will be updated in the repository.

To contribute a new signature, open a pull request with the string, a short description of what it targets, and any hex-encoded variants you are aware of.

---

## Further Reading

| Document | Description |
|---|---|
| [`.github/BACKDOORS.md`](.github/BACKDOORS.md) | A running catalogue of real backdoor samples observed in the wild, with structural analysis, the signatures that detect each one, and remediation steps. Start here if you want to understand what pxSentinel is actually protecting against. |
| [`.github/DEVELOPMENT.md`](.github/DEVELOPMENT.md) | Architecture decisions, design rationale, and a detailed account of how pxSentinel was hardened against a live backdoor during development. Useful if you want to extend the scanner or understand why specific choices were made. |
| [`.github/SECURITY.md`](.github/SECURITY.md) | Security policy — supported versions and the responsible disclosure process for reporting vulnerabilities in pxSentinel itself. |

---

## License

This project is licensed under the [AGPL-3.0-or-later](LICENSE) license.
