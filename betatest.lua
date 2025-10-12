-- Helper to display overlay
function OnTextOverlay(text)
    sendVariant({
        [0] = "OnTextOverlay",
        [1] = text,
    }, -1, 0)
end

-- Get Discord ID as HWID
local discord_id = getDiscordID()

-- Fetch the HWID table from raw GitHub
local hwid_url = "https://raw.githubusercontent.com/Erza-Proxy/GetHWID.lua/refs/heads/main/CPHWID.lua"
local res_table = makeRequest(hwid_url, "GET", {}, "", 5000).content

if not res_table or res_table == "" then
    OnTextOverlay("`4[ERROR] `0Failed to fetch HWID table")
    logToConsole("[ERROR] Failed to fetch HWID table")
    return
end

-- Load the table safely
local hwid_table
local fn, err = load(res_table)
if fn then
    hwid_table = fn()
else
    OnTextOverlay("`4[ERROR] `0Failed to load HWID table: " .. tostring(err))
    logToConsole("[ERROR] Failed to load HWID table: " .. tostring(err))
    return
end

-- Get the HWID entry
local entry = hwid_table[discord_id]
if not entry then
    OnTextOverlay("`4[ERROR] `0Discord ID not found")
    logToConsole("[ERROR] Discord ID not found in HWID table")
    return
end

-- Check expiration (timestamps in ms)
local function isExpired(expires)
    if not expires then return false end
    return getCurrentTimeInternal() > tonumber(expires)
end

if isExpired(entry.expires) then
    OnTextOverlay("`4[ERROR] `0Proxy expired")
    logToConsole("[ERROR] Proxy expired for this HWID")
    return
end

-- Only allow "mp" or "betatest"
local version = entry.version:lower()
if version ~= "mp" and version ~= "betatest" then
    OnTextOverlay("`4[ERROR] `0Unsupported proxy version: " .. entry.version)
    logToConsole("[ERROR] Unsupported proxy version: " .. entry.version)
    return
end

-- Fetch the actual Lua code from your server
local lua_url = "https://erza.yourserver.com/get_lua_file?version=" .. version
local lua_code = makeRequest(lua_url, "GET", {{"User-Agent", "ErzaProxyOnTop"}}, "", 5000).content

if not lua_code or lua_code == "" then
    OnTextOverlay("`4[ERROR] `0Failed to fetch Lua code for version: " .. version)
    logToConsole("[ERROR] Failed to fetch Lua code for version: " .. version)
    return
end

-- Run the Lua code safely
local fn_code, err_code = load(lua_code)
if fn_code then
    fn_code()
else
    OnTextOverlay("`4[ERROR] `0Failed to load Lua code: " .. tostring(err_code))
    logToConsole("[ERROR] Failed to load Lua code: " .. tostring(err_code))
end
