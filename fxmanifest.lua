fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'pxSentinel'
author 'Pixel <https://codemeapixel.dev>'
description 'Real-time backdoor and malware scanner for FiveM servers. Detects known signatures across all loaded resources and takes immediate, configurable action.'
repository 'https://github.com/CodeMeAPixel/pxSentinel'
license 'AGPL-3.0-or-later'
version '1.0.0-beta.1'

shared_scripts {
    'shared/config.lua',
    'shared/blocked.lua',
    'shared/allowed.lua'
}

server_scripts {
    'server/version.lua',
    'server/main.lua'
}   