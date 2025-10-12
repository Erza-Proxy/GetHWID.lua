-- Function to show overlay messages
function OnTextOverlay(text)
    sendVariant({
        [0] = "OnTextOverlay",
        [1] = text,
    }, -1, 0)
end

-- Get Discord ID (or HWID equivalent)
local discord_id = getDiscordID()

-- URL to raw Lua file containing HWID data
local hwid_table_url = "https://raw.githubusercontent.com/Erza-Proxy/GetHWID.lua/refs/heads/main/CPHWID.lua"

-- Fetch HWID table
local response = makeRequest(hwid_table_url, "GET", {}, "", 5000)
if not response or not response.content or response.content == "" then
    OnTextOverlay("`4[ERROR] `0Failed to fetch HWID table")
    logToConsole("[ERROR] Failed to fetch HWID table")
    return
end

local hwid_table_code = response.content

-- Check for HTML response
if hwid_table_code:match("^<") then
    OnTextOverlay("`4[ERROR] `0HWID table response is HTML, not Lua")
    logToConsole("[ERROR] HWID table response is HTML, not Lua")
    return
end

-- Load HWID table safely
local fn, err = load(hwid_table_code)
if not fn then
    OnTextOverlay("`4[ERROR] `0Failed to load HWID table: " .. tostring(err))
    logToConsole("[ERROR] Failed to load HWID table: " .. tostring(err))
    return
end

local ok, hwid_table = pcall(fn)
if not ok or type(hwid_table) ~= "table" then
    OnTextOverlay("`4[ERROR] `0HWID table is invalid")
    logToConsole("[ERROR] HWID table is invalid")
    return
end

-- Get encoded HWID (Discord ID) from table
local entry = hwid_table[tostring(discord_id)]
if not entry then
    OnTextOverlay("`4[ERROR] `0HWID / Discord ID not found")
    logToConsole("[ERROR] HWID / Discord ID not found")
    return
end

-- Check expiration
local function isExpired(expires)
    if not expires then return false end
    local current_time = getCurrentTimeInternal()  -- milliseconds
    return current_time > tonumber(expires)
end

if isExpired(entry.expires) then
    OnTextOverlay("`4[ERROR] `0Proxy expired")
    logToConsole("[ERROR] Proxy expired")
    return
end

-- Map version to Lua script
local version_map = {
    mp = "mp.lua",
    betatest = "betatest.lua",
}

local script_file = version_map[entry.version]
if not script_file then
    OnTextOverlay("`4[ERROR] `0Unsupported proxy version: " .. tostring(entry.version))
    logToConsole("[ERROR] Unsupported proxy version: " .. tostring(entry.version))
    return
end

-- Fetch actual Lua code for the proxy
local lua_url = "https://raw.githubusercontent.com/Erza-Proxy/GetHWID.lua/refs/heads/main/" .. script_file
local lua_resp = makeRequest(lua_url, "GET", {["User-Agent"] = "ErzaProxyOnTop"}, "", 5000)

if not lua_resp or not lua_resp.content or lua_resp.content == "" then
    OnTextOverlay("`4[ERROR] `0Failed to fetch Lua proxy script")
    logToConsole("[ERROR] Failed to fetch Lua proxy script")
    return
end

-- Check for HTML
if lua_resp.content:match("^<") then
    OnTextOverlay("`4[ERROR] `0Lua proxy script response is HTML, not Lua")
    logToConsole("[ERROR] Lua proxy script response is HTML, not Lua")
    return
end

-- Execute Lua proxy
local fn_proxy, err_proxy = load(lua_resp.content)
if not fn_proxy then
    OnTextOverlay("`4[ERROR] `0Failed to load Lua proxy: " .. tostring(err_proxy))
    logToConsole("[ERROR] Failed to load Lua proxy: " .. tostring(err_proxy))
    return
end

local ok_proxy, proxy_result = pcall(fn_proxy)
if not ok_proxy then
    OnTextOverlay("`4[ERROR] `0Error running Lua proxy: " .. tostring(proxy_result))
    logToConsole("[ERROR] Error running Lua proxy: " .. tostring(proxy_result))
end
