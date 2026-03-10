# Configuration Reference

pxSentinel's configuration is split across three files in the `shared/` directory. Each file is loaded by `fxmanifest.lua` before the main server script runs, so all values are available at startup.

---

## `shared/config.lua` — General Settings

```lua
Config = {}

Config.Enable = true
Config.ConsolePrint = true
Config.StopResources = false
Config.StopServer = false
Config.ScanDelay = 5000

Config.Discord = {
    Enabled = true,
    Webhook = GetConvar('pxSentinel:webhook', ''),
}
```

### Options

| Option | Type | Default | Description |
|---|---|---|---|
| `Config.Enable` | `boolean` | `true` | Master switch. Set to `false` to disable all scanning and event handling. |
| `Config.ConsolePrint` | `boolean` | `true` | Print a structured detection report to the server console when a signature is matched. Includes the resource name, file path, matched signature, and a numbered remediation checklist. |
| `Config.StopResources` | `boolean` | `false` | Call `StopResource()` on each infected resource immediately after detection. See the [kill-switch warning](detection-response.md#the-kill-switch-problem) before enabling. |
| `Config.StopServer` | `boolean` | `false` | Call `os.exit(1)` to halt the server after all detections have been handled and the Discord alert has been dispatched. |
| `Config.ScanDelay` | `number` | `5000` | Milliseconds to wait from self-start before running the initial full scan. This allows other resources time to register their file metadata. Increase this value if your server has a very large number of resources. |
| `Config.Discord.Enabled` | `boolean` | `true` | Send a Discord embed alert when a detection occurs. Requires a valid webhook URL. |
| `Config.Discord.Webhook` | `string` | `""` | The Discord webhook URL. Reads from the `pxSentinel:webhook` server convar by default. Hardcoding a URL here works but is not recommended. |

### Notes on containment options

When both `Config.StopResources` and `Config.StopServer` are `true`, pxSentinel stops each infected resource first and then halts the server. The Discord alert is sent before either action.

`Config.StopResources` defaults to `false` because sophisticated backdoors hook `onResourceStop` and call `os.exit()` as a self-defense mechanism. See [Detection & Response](detection-response.md) for the full explanation and the recommended manual workflow.

---

## `shared/blocked.lua` — Malware Signatures

Defines `Config.Signatures`, a list of plain-text strings. Every string in this list is checked against the content of every server script file in every loaded resource.

```lua
Config.Signatures = {
    'cipher-panel',
    'blum-panel',
    'ketamin.cc',
    -- ...
}
```

Signatures are plain strings. **Lua pattern metacharacters (`.`, `*`, `+`, `(`, `%`, etc.) are always treated as literals** — never as pattern syntax. This is enforced by passing `true` as the fourth argument to `string.find` on every match call.

This means domain-style signatures like `vac.sv` match the literal string `vac.sv`, not "any character followed by sv".

The list is organised into comment-delimited sections:

| Section | What it covers |
|---|---|
| Panel domains | Known hosting domains for backdoor control panels |
| Obfuscator watermarks | Fingerprints left by specific obfuscation tools (Luraph, IronBrew, obfuscator.io) |
| Exfiltration patterns | Strings associated with credential harvesting and data exfiltration |
| C2 infrastructure | Known command-and-control domains and identifiers |
| JavaScript RCE patterns | Obfuscated JS patterns common in Node.js-based payloads |

Hex-encoded variants of domain signatures (e.g. `\x63\x69\x70\x68\x65\x72`) are included alongside their plain-text equivalents to catch basic encoding evasion attempts.

See [Signatures](signatures.md) for guidance on adding and maintaining entries.

---

## `shared/allowed.lua` — Safe Resources

Defines `Config.SafeResources`, a list of resource folder names that pxSentinel will never scan. Any resource on this list is skipped entirely — no files are read.

```lua
Config.SafeResources = {
    'chat',
    'spawnmanager',
    'ox_lib',
    'qb-core',
    'es_extended',
    -- ...
}
```

The default list includes:
- CFx / Cfx.re platform resources (`chat`, `spawnmanager`, `mapmanager`, etc.)
- txAdmin / monitor
- Build system resources (`webpack`, `yarn`)
- The ox stack (`ox_lib`, `ox_inventory`, `ox_target`, etc.)
- QBCore resources
- ESX resources
- Common trusted standalone resources (`oxmysql`, `pma-voice`, `saltychat`, etc.)
- CodeMeAPixel resources

pxSentinel itself (`pxSentinel`) is always excluded from scanning regardless of this list.

See [Safe Resources](safe-resources.md) for guidance on managing this list.
