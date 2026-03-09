-- pxSentinel — General Configuration
-- https://github.com/CodeMeAPixel/pxSentinel

Config = {}

-- Enable or disable the detection system entirely.
Config.Enable = true

-- Print detections to the server console.
Config.ConsolePrint = true

-- Stop individual infected resources as soon as they are detected.
--
-- WARNING: Sophisticated backdoors hook the 'onResourceStop' event and call
-- os.exit() as a kill-switch when they sense they are being stopped. With
-- this option enabled, pxSentinel triggering StopResource() on an infected
-- resource would fire that kill-switch, causing txAdmin to interpret the
-- server process death as a crash and restart the server automatically.
--
-- The recommended workflow when a detection fires:
--   1. Note which resource is infected (logged to console + Discord).
--   2. Use txAdmin to gracefully STOP the server (not restart).
--   3. Remove the infected resource from your server folder.
--   4. Start the server again.
--
-- Set to true only if you have confirmed that no kill-switch is present, or
-- if you accept the risk of an automatic txAdmin restart.
Config.StopResources = false

-- Halt the entire server when a backdoor is detected.
-- Use this if you want zero tolerance and a hard shutdown.
-- WARNING: Ensure your signature lists are accurate to avoid false positives
--          that could unexpectedly halt your server.
-- If both StopResources and StopServer are true, infected resources are
-- stopped first, then the server is halted after the Discord alert fires.
Config.StopServer = false

-- Milliseconds to wait after pxSentinel itself starts before performing
-- the initial full scan. This gives all resources that were started
-- before pxSentinel time to fully register their file metadata.
-- Increase this if you have a very large resource list (~200+).
-- Tip: place 'ensure pxSentinel' at the END of your server.cfg so that
-- all other resources are already running when this timer elapses.
Config.ScanDelay = 5000

Config.Discord = {
    -- Send alerts to a Discord channel via webhook.
    Enabled = true,

    -- Recommended: set your webhook via server convar to keep it out of source code.
    --   In server.cfg: set pxSentinel:webhook "https://discord.com/api/webhooks/..."
    -- Alternatively, paste your webhook URL directly in the string below.
    Webhook = GetConvar('pxSentinel:webhook', ''),
}
