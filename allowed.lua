-- pxSentinel — Allowed (Safe) Resources
-- Resources listed here will never be scanned.
-- Plain resource folder names only — no wildcards.
-- https://github.com/CodeMeAPixel/pxSentinel

Config.SafeResources = {
    -- ── CFx / Cfx.re platform ────────────────────────────────────────────
    'chat',
    'spawnmanager',
    'mapmanager',
    'sessionmanager',
    'hardcap',
    'baseevents',
    'basic-gamemode',
    'fivem-map-hipster',
    'fivem-map-skater',

    -- ── txAdmin / monitor ─────────────────────────────────────────────────
    -- monitor is a core fxserver system resource bundled with txAdmin.
    -- It legitimately uses natives such as GetPlayerTokens for player tracking.
    'monitor',
    'txAdmin',

    -- ── fxserver build system resources ──────────────────────────────────
    -- These are system resources used to build UI assets (webpack, yarn).
    -- They legitimately call Node.js fs APIs as part of the build pipeline.
    'webpack',
    'yarn',

    -- ── ox stack ──────────────────────────────────────────────────────────
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'ox_fuel',
    'ox_doorlock',
    'ox_banking',
    'ox_vehicledealer',

    -- ── QBCore ────────────────────────────────────────────────────────────
    'qb-core',
    'qb-inventory',
    'qb-hud',
    'qb-policejob',
    'qb-ambulancejob',
    'qb-garages',
    'qb-phone',
    'qb-vehicleshop',
    'qb-menu',
    'qb-target',
    'qb-clothing',
    'qb-banking',
    'qb-multicharacter',

    -- ── ESX ───────────────────────────────────────────────────────────────
    'es_extended',
    'esx_menu_default',
    'esx_menu_dialog',
    'esx_menu_list',
    'esx_identity',
    'esx_skin',
    'esx_vehicleshop',
    'esx_banking',
    'esx_policejob',
    'esx_ambulancejob',
    'esx_society',

    -- ── common trusted standalone resources ───────────────────────────────
    'screenshot-basic',
    'oxmysql',
    'mysql-async',
    'ghmattimysql',
    'pma-voice',
    'saltychat',
    'mumble-voip',
    'evidence-camera',

    -- ── CodeMeAPixel resources ────────────────────────────────────────────
    -- Remove any you don't use or want scanned.
    'pxSentinel',
    'pxLoadingScreen',
    'pxMechanic',
    '[pixel]',
}
