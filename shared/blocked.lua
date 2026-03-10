-- pxSentinel — Blocked Signatures
-- Plain-text strings only — no Lua patterns.
-- Each entry is scanned against the content of every server script file.
-- https://github.com/CodeMeAPixel/pxSentinel

Config.Signatures = {
    -- ── cipher-panel and respective hex(es) ──
    'cipher-panel',
    '\x63\x69\x70\x68\x65\x72\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65',

    -- ── blum-panel.me and respective hex(es) ──
    'blum-panel',
    '\x62\x6c\x75\x6d\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65',

    -- ── ketamin.cc and respective hex(es) ──
    'ketamin.cc',
    '\x6b\x65\x74\x61\x6d\x69\x6e\x2e\x63\x63',

    -- ── miscellaneous known malware strings ──
    'Enchanced_Tabs',
    'helperServer',
    'MpWxwQeLMRJaDFLKmxVIFNeVfzVKaTBiVRvjBoePYciqfpJzxjNPIXedbOtvIbpDxqdoJR',

    -- ── gfxpanel.org and respective hex(es) ──
    'gfxpanel.org',
    '\x67\x66\x78\x70\x61\x6e\x65\x6c\x2e\x6f\x72\x67',

    'vac.sv',
    'skidrow.cc',
    'fiveleaks.net',
    'leakpanel',
    'leak-panel',
    'cracked-scripts',
    'nulledscripts',

    -- ── common exfiltration / RAT patterns ──
    'sv_licenseKey',
    'sv_master1',
    'svMain',
    'monitoring-agent',
    'data-processor',
    'system_resources',
    'cl_playerlist.lua',
    'cfx-server/citizen',

    -- ── known obfuscator watermarks ──
    'luraph',
    'ironbrew',
    'lua_u obfuscator',

    -- ── JavaScript obfuscator / RCE patterns ──
    'while(!![]){try{',
    'eval(_0x',
}
