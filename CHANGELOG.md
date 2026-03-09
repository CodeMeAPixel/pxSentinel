# Changelog

All notable changes to pxSentinel will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-beta.1] - 2026-03-09

### Added

- **Signature scanning**: Performs a full scan of every resource loaded at server start, checking each declared server script file against the signature list in `blocked.lua`
- **Runtime scanning**: Listens for `onResourceStart` and scans any resource started dynamically after the initial scan completes
- **Plain-text matching**: All signatures are matched as literal strings. Lua pattern metacharacters are never interpreted, eliminating false positives caused by special characters in signatures
- **Discord alerts**: Sends a formatted embed to a configured webhook on any detection, including the resource name, matched file path, and matched signature
- **Console reporting**: Prints a structured detection report to the server console with the resource name, file path, matched signature, and a numbered list of remediation steps
- **Configurable actions**: `Config.StopResources` stops each infected resource immediately upon detection. `Config.StopServer` halts the server after all detections have been handled
- **Allow list**: `Config.SafeResources` in `allowed.lua` defines a list of resource folder names that are never scanned. Includes CFx platform resources, the ox stack, QBCore, ESX, and a set of common trusted standalone resources out of the box
- **Scan delay**: `Config.ScanDelay` controls how long pxSentinel waits before running the initial scan, giving all resources time to register their file metadata
- **Webhook convar**: The Discord webhook URL can be set via the `pxSentinel:webhook` server convar rather than being hardcoded in `config.lua`
- **Signature catalogue**: Initial `blocked.lua` covers known backdoor panel domains, C2 infrastructure, exfiltration patterns, obfuscator watermarks, and credential harvesting strings, including hex-encoded variants to catch basic evasion attempts
- **Kill-switch documentation**: Detailed warning in the README explaining how sophisticated backdoors use `onResourceStop` to call `os.exit()` as a self-defence mechanism, and the recommended safe remediation workflow
- **Security policy**: `.github/SECURITY.md` defines the responsible disclosure process for vulnerabilities in pxSentinel itself
- **Backdoor catalogue**: `.github/BACKDOORS.md` provides a running catalogue of real backdoor samples observed in the wild with structural analysis and the signatures that detect each one
- **Development notes**: `.github/DEVELOPMENT.md` documents architecture decisions, design rationale, and the hardening process undertaken against a live backdoor during development

[1.0.0-beta.1]: https://github.com/CodeMeAPixel/pxSentinel/releases/tag/v1.0.0-beta.1
