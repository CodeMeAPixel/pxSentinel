-- pxSentinel — Version check
-- https://github.com/CodeMeAPixel/pxSentinel

local REPO_API = 'https://api.github.com/repos/CodeMeAPixel/pxSentinel/releases/latest'

local function log(color, msg)
    print(('^%d[pxSentinel]^0 %s'):format(color, msg))
end

local function stripV(tag)
    return tag and tag:match('^v?(.+)$') or tag
end

CreateThread(function()
    Wait(2000)

    local current = stripV(GetResourceMetadata(GetCurrentResourceName(), 'version', 0))
    if not current or current == '' then
        log(3, 'Version check skipped — could not read version from fxmanifest.')
        return
    end

    PerformHttpRequest(REPO_API, function(status, body)
        if status ~= 200 or not body then
            log(3, ('Version check failed — GitHub API returned status %d.'):format(status))
            return
        end

        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= 'table' then
            log(3, 'Version check failed — could not parse GitHub API response.')
            return
        end

        local latest = stripV(data.tag_name)
        if not latest then
            log(3, 'Version check failed — release tag not found in API response.')
            return
        end

        if current == latest then
            log(2, ('Version %s — up to date.'):format(current))
        else
            log(3, ('Update available: %s → %s'):format(current, latest))
            log(3, 'Download the latest release at: https://github.com/CodeMeAPixel/pxSentinel/releases/latest')
        end
    end, 'GET', '', { ['User-Agent'] = 'pxSentinel/' .. current })
end)
