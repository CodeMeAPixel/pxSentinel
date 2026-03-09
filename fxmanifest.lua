fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'pxSentinel'
author 'Pixel <https://codemeapixel.dev>'
description 'Real-time backdoor and malware scanner for FiveM servers. Detects known signatures across all loaded resources and takes immediate, configurable action.'
repository 'https://github.com/CodeMeAPixel/pxSentinel'
license 'AGPL-3.0-or-later'
version '1.0.0-beta.1'

tags { 'security', 'backdoor', 'scanner', 'malware', 'protection', 'server-side', 'anticheat', 'detection', 'safeguard' }

server_scripts {
    'config.lua',
    'blocked.lua',
    'allowed.lua',
    'server.lua',
}