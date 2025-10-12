-- Utility to show overlay text
function OnTextOverlay(text)
    sendVariant({
        [0] = "OnTextOverlay",
        [1] = text,
    }, -1, 0)
end

-- Your HWID identifier (replace with your actual function)
local discord_id = getDiscordID()  
if not discord_id or discord_id == "" then
    OnTextOverlay("`4[ERROR] `0Failed to get Discord ID")
    logToConsole("Failed to get Discord ID")
    return
end

-- Version you want to fetch: "mp" or "betatest"
local version = "mp"

-- Fetch Lua code from server
local res_obj = makeRequest(
    "https://erza.pythonanywhere.com/get_lua_file?version=" .. version,
    "GET",
    { {"User-Agent", "ErzaProxyOnTop"} },
    "",
    5000
)

-- Debug logs
logToConsole("HTTP response received")
logToConsole("Response length: " .. tostring(#res_obj.content or 0))
logToConsole("Response preview: " .. tostring(res_obj.content):sub(1, 200))  -- first 200 chars

-- Validate response
if not res_obj or not res_obj.content or res_obj.content:find("Unauthorized") then
    OnTextOverlay("`4[ERROR] `0Unauthorized or no response from server")
    logToConsole("Unauthorized or empty response")
    return
end

-- Load the Lua HWID table
local fn, err = load(res_obj.content)
if not fn then
    OnTextOverlay("`4[ERROR] `0Failed to load HWID table")
    logToConsole("Failed to load Lua code: " .. tostring(err))
    return
end

-- Execute the loaded table
local hwid_table = fn()
if not hwid_table or type(hwid_table) ~= "table" then
    OnTextOverlay("`4[ERROR] `0Invalid HWID table")
    logToConsole("Invalid HWID table")
    return
end

-- Sanitize HWID helper
local function sanitizeHWID(input)
    if not input then return "" end
    return input:gsub("[%s%-%._]", ""):gsub("[^%w]", "")
end

local encodedHWID = sanitizeHWID(discord_id)

-- Check HWID entry
local entry = hwid_table[encodedHWID]
if not entry then
    OnTextOverlay("`4[ERROR] `0Discord ID not registered")
    logToConsole("HWID not found: " .. encodedHWID)
    return
end

-- Check expiration
local function isExpired(expires)
    if not expires then return false end
    local current = getCurrentTimeInternal()  -- Genta internal time in ms
    return current > expires
end

if isExpired(entry.expires) then
    OnTextOverlay("`4[ERROR] `0Proxy expired")
    logToConsole("HWID expired: " .. encodedHWID)
    return
end

-- Success: execute the actual proxy code
OnTextOverlay("`2[INFO] `0HWID valid, loading proxy...")
logToConsole("HWID valid: " .. encodedHWID)

-- Fetch actual proxy Lua code if needed
-- Example: same URL can be used for MP or Beta Proxy code
local proxy_code_obj = makeRequest(
    "https://erza.pythonanywhere.com/get_lua_file?version=" .. version,
    "GET",
    { {"User-Agent", "ErzaProxyOnTop"} },
    "",
    5000
)

if proxy_code_obj and proxy_code_obj.content and not proxy_code_obj.content:find("Unauthorized") then
    local proxy_fn, proxy_err = load(proxy_code_obj.content)
    if proxy_fn then
        proxy_fn()
        logToConsole("Proxy Lua executed successfully")
    else
        logToConsole("Failed to execute proxy Lua: " .. tostring(proxy_err))
    end
else
    logToConsole("Failed to fetch proxy Lua or unauthorized")
end
