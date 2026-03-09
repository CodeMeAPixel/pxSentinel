-- pxSentinel — Blocked Signatures
-- Plain-text strings only — no Lua patterns.
-- Each entry is scanned against the content of every server script file.
-- https://github.com/CodeMeAPixel/pxSentinel

Config.Signatures = {
    -- ── cipher-panel / cipher-panel.me ───────────────────────────────────
    'cipher-panel',
    '\x63\x69\x70\x68\x65\x72\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65',   -- cipher-panel.me (hex)

    -- ── blum-panel.me ─────────────────────────────────────────────────────
    'blum-panel',
    '\x62\x6c\x75\x6d\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65',           -- blum-panel.me (hex)

    -- ── ketamin.cc ────────────────────────────────────────────────────────
    'ketamin.cc',
    '\x6b\x65\x74\x61\x6d\x69\x6e\x2e\x63\x63',                       -- ketamin.cc (hex)

    -- ── miscellaneous known malware strings ───────────────────────────────
    'Enchanced_Tabs',       -- common misspelling used in malware loaders
    'helperServer',         -- trojanised helper module pattern
    'MpWxwQeLMRJaDFLKmxVIFNeVfzVKaTBiVRvjBoePYciqfpJzxjNPIXedbOtvIbpDxqdoJR',

    -- ── known malicious C2 / panel domains ────────────────────────────────
    -- ── gfxpanel.org ──────────────────────────────────────────────────────
    'gfxpanel.org',
    '\x67\x66\x78\x70\x61\x6e\x65\x6c\x2e\x6f\x72\x67',               -- gfxpanel.org (hex)

    'vac.sv',
    'skidrow.cc',
    'fiveleaks.net',
    'leakpanel',
    'leak-panel',
    'cracked-scripts',
    'nulledscripts',

    -- ── common exfiltration / RAT patterns ────────────────────────────────
    -- These strings appear in scripts that phone home or steal data.
    -- NOTE: GetPlayerTokens is a legitimate FiveM server native used by
    -- txAdmin/monitor and other trusted resources. It has been intentionally
    -- excluded to prevent false positives. Add it back only if you are certain
    -- none of your safe resources call it.
    'sv_licenseKey',        -- attempting to read the server license key
    'sv_master1',           -- attempting to read master server address
    'svMain',               -- common malware entrypoint alias

    -- ── filesystem infiltration / privilege escalation ────────────────────
    -- Patterns used by backdoors that attempt to tamper with the host
    -- filesystem, overwrite core server files, or plant persistent agents.
    -- FiveM's fs permission system will log and block these at runtime, but
    -- catching the source code early prevents them from ever executing.
    --
    -- NOTE: fs.writeFile is a standard Node.js API used by webpack, yarn, and
    -- many legitimate build tools. It has been intentionally excluded to prevent
    -- false positives. The runtime onResourceFsPermissionViolation handler
    -- catches actual unauthorised write attempts without needing this signature.
    'monitoring-agent',     -- hidden Node.js agent file planted in txData
    'data-processor',       -- alternate hidden agent filename pattern
    'system_resources',     -- no legitimate resource should reference this path
    'cl_playerlist.lua',    -- attempting to overwrite a core monitor file
    'cfx-server/citizen',   -- hardcoded path to server internals

    -- ── known obfuscator watermarks ───────────────────────────────────────
    'luraph',               -- Luraph obfuscator (frequently used to hide malware)
    'ironbrew',             -- IronBrew obfuscator watermark strings
    'lua_u obfuscator',

    -- ── JavaScript obfuscator / RCE patterns ──────────────────────────────
    -- These patterns appear in server-side .js backdoors and are not present
    -- in any legitimate FiveM resource.
    --
    -- obfuscator.io anti-tamper loop — emitted verbatim by the tool and found
    -- in no legitimate code. Catching this cuts off the entire class of
    -- obfuscator.io-generated malware in one signature.
    'while(!![]){try{',
    --
    -- Remote code execution via eval of an obfuscated payload.
    -- obfuscator.io names all generated variables with the _0x prefix. Passing
    -- one of those identifiers directly to eval() means the resource is
    -- evaluating code that was either obfuscated locally or fetched remotely.
    -- No legitimate FiveM resource eval()s an _0x-prefixed expression.
    'eval(_0x',             -- evaluating obfuscated/remote payload
}
