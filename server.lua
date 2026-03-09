-- pxSentinel - Server-side backdoor signature detection
-- https://github.com/CodeMeAPixel/pxSentinel
-- Config is loaded from: config.lua, blocked.lua, allowed.lua

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │                              Internals                                  │
-- └─────────────────────────────────────────────────────────────────────────┘

local selfName = GetCurrentResourceName()

-- Build an O(1) lookup set from the SafeResources list.
local safeResourceSet = {}
for _, name in ipairs(Config.SafeResources) do
    safeResourceSet[name] = true
end

local function isSafe(resource)
    return resource == selfName or safeResourceSet[resource]
end

local function log(color, msg)
    print(('^%d[pxSentinel]^0 %s'):format(color, msg))
end

--- Scan a single resource's server scripts for known backdoor signatures.
--- Returns an empty table without scanning if the resource is on the safe list.
--- Covers 'server_script', 'server_only_script', and 'shared_script' manifest
--- entries. For Node.js resources it also probes common secondary .js filenames
--- that backdoors frequently require() without declaring in the manifest.
--- @param resource string
--- @return table detections  List of { resource, file, signature } entries.

-- Common secondary .js filenames that backdoors load via require() without
-- listing them in the manifest. LoadResourceFile returns nil for paths that
-- do not exist, so probing all of them on every Node.js resource is safe.
local JS_PROBE_PATHS = {
    'index.js', 'server.js', 'main.js', 'app.js',
    'src/index.js', 'src/server.js', 'src/main.js',
    'lib/index.js', 'lib/server.js',
}

local function scanResource(resource)
    if isSafe(resource) then return {} end
    local detections = {}
    local scannedPaths = {}   -- deduplicate across metadata keys

    local function checkContent(filePath, content)
        if scannedPaths[filePath] or not content then return end
        scannedPaths[filePath] = true

        for _, signature in ipairs(Config.Signatures) do
            -- Pass true as the 4th argument for plain-text matching.
            -- This prevents any Lua pattern metacharacters inside a signature
            -- string from being interpreted as regex, which could cause
            -- incorrect results or unexpected behaviour.
            if string.find(content, signature, 1, true) then
                detections[#detections + 1] = {
                    resource  = resource,
                    file      = filePath,
                    signature = signature,
                }
            end
        end
    end

    -- Track whether this resource has any declared .js files so we know
    -- whether to run the Node.js secondary-path probes below.
    local hasJS = false

    -- Scan server_script, server_only_script, and shared_script manifest entries.
    -- shared_script files run on both the client and the server; malicious code
    -- is just as easily embedded there as in a server-only entry.
    for _, metaKey in ipairs({ 'server_script', 'server_only_script', 'shared_script' }) do
        local numFiles = GetNumResourceMetadata(resource, metaKey) or 0

        for i = 0, numFiles - 1 do
            local filePath = GetResourceMetadata(resource, metaKey, i)
            if not filePath then goto continue end

            if filePath:sub(-3) == '.js' then
                hasJS = true
            end

            checkContent(filePath, LoadResourceFile(resource, filePath))

            ::continue::
        end
    end

    -- For Node.js resources, also probe common secondary .js paths that do not
    -- always appear in the manifest. Backdoors frequently split themselves into
    -- a thin declared loader and a heavier payload that is require()'d at
    -- runtime. The declared entry point alone does not reveal the payload.
    if hasJS then
        for _, probePath in ipairs(JS_PROBE_PATHS) do
            checkContent(probePath, LoadResourceFile(resource, probePath))
        end
    end

    return detections
end

--- Scan all currently running resources except pxSentinel itself.
--- @return table detections  Flat list of all detections across all resources.
local function scanAllResources()
    local allDetections = {}

    for i = 0, GetNumResources() - 1 do
        local res = GetResourceByFindIndex(i)
        if res and not isSafe(res) then
            for _, detection in ipairs(scanResource(res)) do
                allDetections[#allDetections + 1] = detection
            end
        end
        -- Yield every iteration to avoid blocking the server thread while
        -- reading potentially large files across many resources.
        Wait(0)
    end

    return allDetections
end

local function sendDiscordAlert(detections)
    local webhook = Config.Discord.Webhook
    if not Config.Discord.Enabled or not webhook or webhook == '' then return end

    local lines = {}
    for _, d in ipairs(detections) do
        lines[#lines + 1] = ('**Resource:** `%s/%s`\n**Signature:** `%s`'):format(
            d.resource, d.file, d.signature
        )
    end

    local payload = json.encode({
        username = 'pxSentinel',
        embeds = {
            {
                color       = 15158332, -- red
                title       = '\226\154\160\239\184\143 Backdoor Signature Detected',
                description = table.concat(lines, '\n\n'),
                footer      = { text = 'pxSentinel \226\128\162 github.com/CodeMeAPixel/pxSentinel' },
            },
        },
    })

    PerformHttpRequest(webhook, function(status)
        if status ~= 200 and status ~= 204 then
            log(3, ('Discord webhook returned unexpected status %d'):format(status))
        end
    end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

local function handleDetections(detections)
    if #detections == 0 then return end

    -- Group detections by resource so we can act on each one individually.
    local byResource = {}
    for _, d in ipairs(detections) do
        if not byResource[d.resource] then
            byResource[d.resource] = {}
        end
        byResource[d.resource][#byResource[d.resource] + 1] = d
    end

    if Config.ConsolePrint then
        local bar = string.rep('─', 62)
        log(1, bar)
        log(1, (' !! %d BACKDOOR SIGNATURE(S) DETECTED !!'):format(#detections))
        log(1, bar)

        for resource, hits in pairs(byResource) do
            log(1, ('  Resource : ^3%s^1'):format(resource))
            for _, d in ipairs(hits) do
                log(1, ('    File      : ^3%s^1'):format(d.file))
                log(1, ('    Signature : ^3%s^1'):format(d.signature))
            end
            log(1, '')
        end

        log(1, bar)
        log(3, '  NEXT STEPS')
        log(3, '  ──────────────────────────────────────────────────────')
        log(3, '  1. Note which resource(s) are listed above.')
        log(3, '  2. Do NOT keep these resources on a live server.')
        log(3, '  3. Remove or replace the infected resource(s) immediately.')
        log(3, '  4. Audit your server files for any other unauthorised changes.')
        log(3, '  5. Rotate your server license key and any API tokens.')
        log(3, '  6. Identify and remove whoever added the infected resource.')
        log(1, bar)        if Config.StopResources then
            log(1, '')
            log(3, '  WARNING: StopResources is enabled. If the infected resource has a')
            log(3, '  kill-switch hooked to onResourceStop it will call os.exit() when')
            log(3, '  stopped, causing txAdmin to restart the server automatically.')
            log(1, bar)
        end    end

    if Config.Discord.Enabled then
        sendDiscordAlert(detections)
    end

    if Config.StopResources then
        for resource in pairs(byResource) do
            log(1, ('Stopping infected resource: ^3%s'):format(resource))
            StopResource(resource)
        end
    end

    if Config.StopServer then
        log(1, 'Halting server due to detected backdoor signature(s)...')
        -- Allow time for the Discord webhook and StopResource calls to dispatch.
        Wait(3000)
        os.exit(1)
    end
end

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │                            Event Handlers                               │
-- └─────────────────────────────────────────────────────────────────────────┘

-- Track whether the initial full scan has already run so that resources
-- started during the settle delay are not double-scanned.
local initialScanDone = false

AddEventHandler('onResourceStart', function(res)
    if not Config.Enable then return end

    if res == selfName then
        -- Wait for the configured settle delay before scanning so that all
        -- resources started before pxSentinel have time to fully register
        -- their file metadata. Place 'ensure pxSentinel' last in server.cfg
        -- for best results.
        CreateThread(function()
            if Config.ScanDelay > 0 then
                log(2, ('Waiting %ds for all resources to settle before scanning...'):format(Config.ScanDelay / 1000))
                Wait(Config.ScanDelay)
            end

            log(2, 'Starting full resource scan...')
            local detections = scanAllResources()
            initialScanDone = true

            if #detections == 0 then
                log(2, ('Scan complete — %d resource(s) checked, no backdoor signatures found.'):format(GetNumResources()))
            else
                handleDetections(detections)
            end
        end)
    elseif initialScanDone then
        -- Only scan resources that start dynamically *after* the initial full
        -- scan has completed. Resources that start during the settle window are
        -- already covered by scanAllResources().
        local detections = scanResource(res)
        handleDetections(detections)
    end
end)

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │                     Filesystem Permission Violations                    │
-- └─────────────────────────────────────────────────────────────────────────┘

-- FiveM's Node.js scripting runtime emits this event when a resource attempts
-- a filesystem operation it is not permitted to perform.
--
-- IMPORTANT: this handler only fires for *filesystem write* operations that
-- the runtime blocks. It does NOT cover in-memory RCE delivered via HTTPS
-- fetch + eval(), which executes entirely without touching the filesystem.
-- Those payloads must be caught earlier by the static signature scan.
AddEventHandler('onResourceFsPermissionViolation', function(resourceName, permission, path)
    if not Config.Enable then return end
    if isSafe(resourceName) then return end

    local detection = {
        {
            resource  = resourceName,
            file      = '(runtime)',
            signature = ('fs permission violation: %s on %s'):format(permission, path),
        }
    }

    if Config.ConsolePrint then
        local bar = string.rep('─', 62)
        log(1, bar)
        log(1, ' !! FILESYSTEM PERMISSION VIOLATION DETECTED !!')
        log(1, bar)
        log(1, ('  Resource  : ^3%s^1'):format(resourceName))
        log(1, ('  Permission: ^3%s^1'):format(permission))
        log(1, ('  Path      : ^3%s^1'):format(path))
        log(1, '')
        log(1, bar)
        log(3, '  This resource attempted a filesystem operation outside its')
        log(3, '  permitted scope. This is a strong indicator of a backdoor.')
        log(3, '  Remove this resource immediately and audit your server files.')
        log(1, bar)
    end

    if Config.Discord.Enabled then
        sendDiscordAlert(detection)
    end

    if Config.StopResources then
        log(1, ('Stopping resource due to filesystem violation: ^3%s'):format(resourceName))
        StopResource(resourceName)
    end

    if Config.StopServer then
        log(1, 'Halting server due to filesystem permission violation...')
        Wait(3000)
        os.exit(1)
    end
end)
