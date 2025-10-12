function OnTextOverlay(text)
    sendVariant({
        [0] = "OnTextOverlay",
        [1] = text,
    }, -1, 0)
end

-- Helper to log errors
local function logError(msg)
    logToConsole("`4[ERROR] `0" .. msg)
    OnTextOverlay("`4[ERROR] `0" .. msg)
end

-- Get Discord ID (used as HWID)
local discord_id = getDiscordID()

-- Fetch the HWID table from raw GitHub link
local hwid_url = "https://raw.githubusercontent.com/Erza-Proxy/GetHWID.lua/refs/heads/main/CPHWID.lua"
local res_response = makeRequest(hwid_url, "GET", {}, "", 5000)
local res = res_response and res_response.content

if not res or res == "" then
    logError("No response from HWID API")
    return
end

-- Load HWID table safely
local fn, err = load(res)
if not fn then
    logError("Failed to load HWID table: " .. tostring(err))
    return
end

local hwid_table = fn()
if type(hwid_table) ~= "table" then
    logError("HWID table is invalid")
    return
end

-- Check HWID in table
local entry = hwid_table[discord_id]
if not entry then
    logError("Discord ID not found")
    return
end

-- Check expiration
local function isExpired(expires)
    if not expires then return false end
    local current_time = getCurrentTimeInternal() -- milliseconds
    return current_time > expires
end

if isExpired(entry.expires) then
    logError("Proxy expired")
    return
end

-- Only support "mp" and "betatest"
local version_map = {
    mp = "mp",
    betatest = "betatest",
}

local version = version_map[entry.version:lower()]
if not version then
    logError("Unsupported proxy version: " .. tostring(entry.version))
    return
end

-- Fetch Lua script for this version using makeRequest
local lua_response = makeRequest(
    "https://erza.pythonanywhere.com/get_lua_file?version=" .. version,
    "GET",
    { "User-Agent: ErzaProxyOnTop" },
    "",
    5000
)
local code = lua_response and lua_response.content

if not code or code == "" then
    logError("Failed to retrieve Lua code from server")
    return
end

if code:find("Unauthorized") then
    logError("Unauthorized: Your HWID is not registered for " .. version)
    return
end

-- Load and run the Lua script
local fn2, err2 = load(code)
if not fn2 then
    logError("Failed to load Lua code: " .. tostring(err2))
    return
end

fn2()
