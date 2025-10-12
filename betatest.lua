function OnTextOverlay(text)
    sendVariant({
        [0] = "OnTextOverlay",
        [1] = text,
    }, -1, 0)
end

local discord_id = getDiscordID()

-- Fetch HWID table
local hwid_url = "https://raw.githubusercontent.com/Erza-Proxy/GetHWID.lua/main/CPHWID.lua"
local res = makeRequest(hwid_url, "GET", {}, "", 5000).content

if not res or res == "" then
    OnTextOverlay("`4[ERROR] Failed to load HWID table")
    logToConsole("`4[ERROR] Failed to load HWID table")
    return
end

-- Load HWID table
local fn, err = load(res)
if not fn then
    OnTextOverlay("`4[ERROR] Failed to parse HWID table: " .. tostring(err))
    logToConsole("`4[ERROR] Failed to parse HWID table: " .. tostring(err))
    return
end

local hwid_table = fn()
local entry = hwid_table[tostring(discord_id)]

if not entry then
    OnTextOverlay("`4[ERROR] Discord ID not found")
    logToConsole("`4[ERROR] Discord ID not found")
    return
end

-- Check expiration
local function isExpired(expires)
    if not expires then return false end
    local currentTime = getCurrentTimeInternal()
    return currentTime > tonumber(expires)
end

if isExpired(entry.expires) then
    OnTextOverlay("`4[ERROR] Proxy expired")
    logToConsole("`4[ERROR] Proxy expired")
    return
end

-- Map version to URL for mobile
local version_map = {
    mp = "mp",
    betatest = "betatest"
}

local version = version_map[entry.version]
if not version then
    OnTextOverlay("`4[ERROR] Unsupported proxy version: " .. tostring(entry.version))
    logToConsole("`4[ERROR] Unsupported proxy version: " .. tostring(entry.version))
    return
end

-- Fetch Lua code from your Flask server using makeRequest
local response = makeRequest(
    "https://erza.pythonanywhere.com/get_lua_file?version=" .. version,
    "GET",
    { {"User-Agent", "ErzaProxyOnTop"} },
    "",
    5000
)

if not response or not response.content or response.content:find("Unauthorized") then
    OnTextOverlay("`4[ERROR] Unauthorized or failed to fetch proxy Lua code")
    logToConsole("`4[ERROR] Unauthorized or failed to fetch proxy Lua code")
    return
end

-- Load and run fetched Lua code
local fn, err = load(response.content)
if not fn then
    OnTextOverlay("`4[ERROR] Failed to load Lua code: " .. tostring(err))
    logToConsole("`4[ERROR] Failed to load Lua code: " .. tostring(err))
    return
end

fn()
