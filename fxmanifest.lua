fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'pxSentinel'
author 'Pixel <https://codemeapixel.dev>'
description 'Scans server scripts for known backdoor signatures and takes configurable action upon detection.'
repository 'https://github.com/CodeMeAPixel/pxSentinel'
license 'AGPL-3.0-or-later'
version '1.0.0-beta.1'

server_scripts {
    'config.lua',
    'blocked.lua',
    'allowed.lua',
    'server.lua',
}