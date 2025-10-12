-- ------------------------ Text Overlay Helper ------------------------
function OnTextOverlay(text)
    sendVariant({
        [0] = "OnTextOverlay",
        [1] = text,
    }, -1, 0)
end

-- ------------------------ Fetch Discord ID / HWID ------------------------
local discord_id = getDiscordID() or ""

-- ------------------------ Fetch HWID Table ------------------------
local hwid_table_url = "https://raw.githubusercontent.com/Erza-Proxy/GetHWID.lua/refs/heads/main/CPHWID.lua"
local res = makeRequest(hwid_table_url, "GET").content

if not res or res == "" then
    logToConsole("`4[ERROR] Could not fetch HWID table from GitHub")
    return
end

-- HWID table fix: do NOT prepend "return" because the file already starts with return { ... }
local fn, err = load(res)
if not fn then
    logToConsole("`4[ERROR] Failed to load HWID table: " .. tostring(err))
    return
end

local hwid_table = fn()
local entry = hwid_table[discord_id]

if not entry then
    OnTextOverlay("`4[ERROR] `0Discord ID not found")
    logToConsole("`4[ERROR] `0Discord ID not found")
    return
end

-- ------------------------ Check Expiration ------------------------
local current_ms = getCurrentTimeInternal()
if entry.expires and current_ms > entry.expires then
    local expire_date = os.date("%Y-%m-%d %H:%M:%S", math.floor(entry.expires/1000))
    OnTextOverlay("`4[ERROR] `0Proxy expired on " .. expire_date)
    logToConsole("`4[ERROR] `0Proxy expired on " .. expire_date)
    return
end

-- ------------------------ Proxy Valid ------------------------
local valid_date = os.date("%Y-%m-%d %H:%M:%S", math.floor(entry.expires/1000))
OnTextOverlay("`2[INFO] `0Proxy valid until " .. valid_date)
logToConsole("`2[INFO] `0Proxy valid until " .. valid_date)

-- ------------------------ Allowed Versions ------------------------
local version_map = {
    mp = "mp",
    betatest = "betatest"
}

local version = entry.version
if not version_map[version] then
    MessageBox("Erza Proxy", "Unsupported version: " .. tostring(version))
    logToConsole("`4[ERROR] Unsupported version: " .. tostring(version))
    return
end

-- ------------------------ Fetch Lua Proxy Script ------------------------
local code_url = "https://erza.pythonanywhere.com/get_lua_file?version=" .. version
local code_res_obj = makeRequest(code_url, "GET", {["User-Agent"] = "ErzaProxyOnTop"}, "", 5000)
local code_res = code_res_obj.content

logToConsole("[DEBUG] Lua script HTTP length: " .. tostring(#code_res))
logToConsole("[DEBUG] Lua script preview: " .. code_res:sub(1,50))

if not code_res or code_res == "" then
    logToConsole("`4[ERROR] Failed to fetch Lua script for version: " .. version)
    return
end

if code_res:find("Unauthorized") then
    MessageBox("Erza Proxy", "Unauthorized: Your HWID is not registered for version " .. version)
    logToConsole("[ERROR] Unauthorized")
    return
end

-- ------------------------ Load & Execute Proxy Script ------------------------
local fn_code, err_code = load(code_res)
if fn_code then
    fn_code()
    logToConsole("[INFO] Lua code loaded successfully for version: " .. version)
else
    logToConsole("`4[ERROR] Failed to load Lua script: " .. tostring(err_code))
end
