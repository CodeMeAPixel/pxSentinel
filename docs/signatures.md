# Signatures

The signature list in `shared/blocked.lua` defines the plain-text strings that pxSentinel checks against the content of every server script file in every loaded resource.

---

## How Signatures Work

Each entry in `Config.Signatures` is a plain string. During scanning, pxSentinel uses:

```lua
string.find(content, signature, 1, true)
```

The `true` flag disables Lua pattern matching entirely. Every character in a signature is treated as a literal, including `.`, `*`, `+`, `(`, `%`, and all other Lua metacharacters. This means:

- `vac.sv` matches the exact string `vac.sv` — not "any character followed by sv"
- `eval(_0x` matches only that exact prefix — no pattern interpretation occurs
- Signatures will never produce false positives or missed matches due to special characters

---

## Signature Categories

The built-in list is organised into comment-delimited sections:

### Panel domains

Known hosting domains for backdoor control panels distributed through unofficial FiveM marketplaces. Each domain is paired with a hex-encoded variant to catch simple encoding evasion:

```lua
'cipher-panel',
'\x63\x69\x70\x68\x65\x72\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65',

'blum-panel',
'\x62\x6c\x75\x6d\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65',
```

### Obfuscator watermarks

Fingerprints left by specific obfuscation tools in output files. These strings appear in every file produced by the target tool, regardless of the payload content:

```lua
'luraph',
'ironbrew',
'lua_u obfuscator',
'while(!![]){try{',   -- obfuscator.io anti-tamper loop
'eval(_0x',           -- obfuscator.io variable-naming convention
```

### Exfiltration patterns

Strings associated with credential harvesting. Legitimate resources have no reason to reference these internal FiveM or txAdmin file names:

```lua
'sv_licenseKey',
'sv_master1',
'cl_playerlist.lua',
'cfx-server/citizen',
```

### C2 infrastructure

Known command-and-control domains and identifiers seen in real backdoor samples:

```lua
'vac.sv',
'skidrow.cc',
'fiveleaks.net',
'leakpanel',
'leak-panel',
```

---

## Adding Signatures

Append new entries to the bottom of the appropriate section in `shared/blocked.lua`. All entries must be plain strings enclosed in single or double quotes:

```lua
Config.Signatures = {
    -- existing entries ...

    -- ── my additions ──
    'my-malicious-domain.com',
    '\x6d\x79\x2d\x6d\x61\x6c\x69\x63\x69\x6f\x75\x73\x2d\x64\x6f\x6d\x61\x69\x6e\x2e\x63\x6f\x6d',
}
```

### Guidelines

- **Use the shortest unambiguous string.** A full domain name (`example-panel.me`) is better than a partial hostname fragment that could appear in legitimate code.
- **Include hex-encoded variants** for strings that are likely to be encoded as a basic evasion technique. You can generate them with any hex encoder, or use Lua's `\x` escape syntax directly.
- **Do not add generic strings** that are likely to appear in legitimate resources (e.g. `eval`, `require`, `http`). Signatures should be specific to known malicious infrastructure or obfuscation tools.
- **Document the category** with a comment above the entry, following the existing style.

---

## Contributing Signatures

To contribute a signature to the official list, open a pull request against [CodeMeAPixel/pxSentinel](https://github.com/CodeMeAPixel/pxSentinel) with:

1. The plain-text signature string
2. A short description of what it targets (domain, tool, pattern)
3. Hex-encoded variants if applicable
4. A reference to any public analysis or sample if available

New signatures are reviewed before merging to avoid false positives against common legitimate code patterns.

---

## Keeping Signatures Current

The built-in list targets threats known at the time of each release. New backdoor panels, C2 domains, and obfuscation tools emerge regularly. To stay current:

- Watch the repository for updates to `blocked.lua`
- Review the [Backdoor Catalogue](../.github/BACKDOORS.md) for detailed analysis of real samples detected in the wild
- Submit new findings via pull request
