-- pxSentinel — General Configuration
-- https://github.com/CodeMeAPixel/pxSentinel

Config = {}

Config.Enable = true

Config.ConsolePrint = true

Config.StopResources = false

Config.StopServer = false

Config.ScanDelay = 5000

Config.Discord = {
    Enabled = true,
    Webhook = GetConvar('pxSentinel:webhook', ''),
}
