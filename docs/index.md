# pxSentinel Documentation

**pxSentinel** is a server-side FiveM resource that scans all loaded resources for known backdoor and malware signatures. When a match is found, it logs a detailed report to the console, alerts your team via Discord, and takes configurable containment actions.

---

## Documentation

| Page | Description |
|---|---|
| [Installation](installation.md) | How to install and configure pxSentinel on your server. |
| [Configuration](configuration.md) | Full reference for `config.lua`, `blocked.lua`, and `allowed.lua`. |
| [How It Works](how-it-works.md) | Scanning architecture, detection flow, and runtime behaviour. |
| [Signatures](signatures.md) | Understanding the signature list and adding new entries. |
| [Safe Resources](safe-resources.md) | Managing the allow list to exclude trusted resources from scanning. |
| [Detection & Response](detection-response.md) | What to do when pxSentinel fires — including the kill-switch warning. |

---

## Quick Start

1. Place the `pxSentinel` folder in your `resources` directory.
2. Add `ensure pxSentinel` at the **end** of `server.cfg`.
3. Set your Discord webhook:
   ```
   set pxSentinel:webhook "https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE"
   ```
4. Start your server. pxSentinel will run automatically.

See [Installation](installation.md) for full setup instructions.

---

## Repository

| Resource | Link |
|---|---|
| GitHub | [CodeMeAPixel/pxSentinel](https://github.com/CodeMeAPixel/pxSentinel) |
| Backdoor Catalogue | [.github/BACKDOORS.md](../.github/BACKDOORS.md) |
| Development Notes | [.github/DEVELOPMENT.md](../.github/DEVELOPMENT.md) |
| Security Policy | [.github/SECURITY.md](../.github/SECURITY.md) |
| Changelog | [CHANGELOG.md](../CHANGELOG.md) |
| License | [AGPL-3.0-or-later](../LICENSE) |
