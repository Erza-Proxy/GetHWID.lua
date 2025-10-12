-- Helper function to display overlay messages
function OnTextOverlay(text)
    sendVariant({
        [0] = "OnTextOverlay",
        [1] = text,
    }, -1, 0)
end

-- Fetch HWID (discord ID or device ID)
local discord_id = getDiscordID()

-- Fetch HWID table from your server
local hwid_url = "https://erza.pythonanywhere.com/get_lua_file?version=mp" -- or betatest
local headers = { {"User-Agent", "ErzaProxyOnTop"} }
local response = makeRequest(hwid_url, "GET", headers, "", 5000)

if not response or not response.content then
    logToConsole("`4[ERROR] No response from server")
    OnTextOverlay("`4[ERROR] Failed to fetch HWID table")
    return
end

local hwid_table_code = response.content

-- Attempt to load HWID table
local hwid_table_fn, err = load(hwid_table_code)
if not hwid_table_fn then
    logToConsole("`4[ERROR] Failed to load HWID table: " .. tostring(err))
    OnTextOverlay("`4[ERROR] Invalid HWID table")
    return
end

local hwid_table = hwid_table_fn()
if not hwid_table or type(hwid_table) ~= "table" then
    logToConsole("`4[ERROR] HWID table is not a table")
    OnTextOverlay("`4[ERROR] HWID table invalid")
    return
end

-- Helper: sanitize HWID
local function sanitizeHWID(input)
    if not input then return "" end
    return input:gsub("[%s%-%._]", ""):gsub("[^%w]", "")
end

local encodedHWID = sanitizeHWID(discord_id)
local hwid_entry = hwid_table[encodedHWID]

-- Check expiration
local function isExpired(entry)
    if not entry or not entry.expires then return false end
    local current = getCurrentTimeInternal() -- returns ms
    return current > tonumber(entry.expires)
end

if not hwid_entry then
    logToConsole("`4[ERROR] HWID not found: " .. encodedHWID)
    OnTextOverlay("`4[ERROR] Discord ID not found")
    return
end

if isExpired(hwid_entry) then
    logToConsole("`4[ERROR] HWID expired: " .. encodedHWID)
    OnTextOverlay("`4[ERROR] Proxy expired")
    return
end

-- Determine proxy version
local version_map = {
    mp = "mp",
    betatest = "betatest"
}

local proxy_version = hwid_entry.version
if not version_map[proxy_version] then
    logToConsole("`4[ERROR] Unsupported proxy version: " .. tostring(proxy_version))
    OnTextOverlay("`4[ERROR] Unsupported proxy version")
    return
end

-- Fetch and execute the Lua proxy code
local proxy_url = "https://erza.pythonanywhere.com/get_lua_file?version=" .. proxy_version
local proxy_response = makeRequest(proxy_url, "GET", headers, "", 5000)

if not proxy_response or not proxy_response.content then
    logToConsole("`4[ERROR] Failed to fetch proxy Lua code")
    OnTextOverlay("`4[ERROR] Failed to load proxy")
    return
end

local proxy_code = proxy_response.content

-- Check for unauthorized
if proxy_code:match("Unauthorized") then
    logToConsole("`4[ERROR] Unauthorized: Your HWID is not allowed")
    OnTextOverlay("`4[ERROR] Unauthorized HWID")
    return
end

-- Load and execute proxy
local fn, err = load(proxy_code)
if not fn then
    logToConsole("`4[ERROR] Failed to load proxy: " .. tostring(err))
    OnTextOverlay("`4[ERROR] Failed to load proxy")
    return
end

fn() -- Run the proxy
logToConsole("`2[INFO] Proxy loaded successfully for version: " .. proxy_version)
OnTextOverlay("`2[INFO] Proxy loaded successfully")
