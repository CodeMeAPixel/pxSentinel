# Installation

## Requirements

- FiveM server artifact `22934` or newer
- Lua 5.4 (`lua54 'yes'` declared in `fxmanifest.lua` — already set)

---

## Steps

### 1. Add the resource

Clone or download this repository into your server's `resources` directory. The folder must be named `pxSentinel`.

```
resources/
└── pxSentinel/
    ├── fxmanifest.lua
    ├── shared/
    │   ├── config.lua
    │   ├── blocked.lua
    │   └── allowed.lua
    └── server/
        └── main.lua
```

---

### 2. Ensure the resource last

Add the following line to the **end** of your `server.cfg`, after all other `ensure` statements:

```
ensure pxSentinel
```

Placing pxSentinel last gives all other resources time to register their file metadata with the runtime before the scan begins. If pxSentinel starts too early, `GetNumResourceMetadata` may return zero for resources that are still initialising.

---

### 3. Configure the Discord webhook

Set your webhook URL via a server convar. This keeps the URL out of your source files and git history:

```
set pxSentinel:webhook "https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE"
```

Add this line anywhere in `server.cfg` before the `ensure pxSentinel` line. If the convar is not set, Discord alerts are silently skipped — no error is produced, but you will not receive notifications.

> Alternatively, you can set `Config.Discord.Webhook` directly in `shared/config.lua`, but this is not recommended as the URL may end up in version control or leaked source archives.

---

### 4. Review the configuration files

Before going live, review these three files and adjust them to your server:

| File | Purpose |
|---|---|
| `shared/config.lua` | General behaviour — enable/disable scanner, Discord, containment actions, scan delay. |
| `shared/blocked.lua` | Malware signatures — plain-text strings matched against server script content. |
| `shared/allowed.lua` | Safe resources — resource folder names excluded from scanning entirely. |

See [Configuration](configuration.md) for a full reference.

---

## Verifying Installation

Start your server and check the console for pxSentinel output. If everything is working, you should see:

```
[pxSentinel] Waiting 5s for all resources to settle before scanning...
[pxSentinel] Starting full resource scan...
[pxSentinel] Scan complete — N resource(s) checked, no backdoor signatures found.
```

If the scan delay message does not appear, confirm that `ensure pxSentinel` is present in `server.cfg` and that the resource name matches the folder name exactly.

---

## Updating

To update pxSentinel, replace the resource folder with the new version. Your configuration is held in `shared/config.lua`, `shared/blocked.lua`, and `shared/allowed.lua` — review the [Changelog](../CHANGELOG.md) before updating to check for any changes to these files.
