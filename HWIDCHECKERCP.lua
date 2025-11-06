function OnTextOverlay(text)
    sendVariant({ [0] = "OnTextOverlay", [1] = text }, -1, 0)
end

local function safeDate(ms)
    local t = math.floor(ms / 1000)
    local seconds_in_day = 86400
    local days = math.floor(t / seconds_in_day)
    local year = 1970 + math.floor(days / 365.25)
    local day_of_year = days - math.floor((year - 1970) * 365.25) + 1
    local month_lengths = {31,28,31,30,31,30,31,31,30,31,30,31}
    if year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0) then month_lengths[2] = 29 end
    local month, day = 1, day_of_year
    for i, ml in ipairs(month_lengths) do
        if day > ml then day = day - ml month = month + 1 else break end
    end
    local months = {"January","February","March","April","May","June","July","August","September","October","November","December"}
    return string.format("%s %d, %d", months[month], day, year)
end

local function readHWID()
    local hwidPaths = {
        "/storage/emulated/0/Android/media/.sysdata/HWID.txt",
        "/storage/emulated/0/.cache/system/.hwid"
    }
    for _, path in ipairs(hwidPaths) do
        local file = io.open(path, "r")
        if file then
            local hwid = file:read("*a"):gsub("%s+", "")
            file:close()
            return hwid
        end
    end
    return nil
end

local function readLocalList()
    local paths = {
        "/storage/emulated/0/Android/media/.sysdata/PROXYLIST.lua",
        "/storage/emulated/0/.cache/system/PROXYLIST.lua"
    }
    for _, path in ipairs(paths) do
        local f = io.open(path, "r")
        if f then
            local data = f:read("*a")
            f:close()
            if data and #data > 0 then
                local ok, fn = pcall(load, data)
                if ok and fn then
                    local tbl = fn()
                    if tbl then return tbl end
                end
            end
        end
    end
    return nil
end

local function fetchOnlineList()
    local url = "https://raw.githubusercontent.com/Erza-Proxy/GetHWID.lua/refs/heads/main/NEWCP.lua"
    local ok, res_obj = pcall(makeRequest, url, "GET")
    if ok and res_obj and res_obj.content then
        local fn = load(res_obj.content)
        if fn then
            local tbl = fn()
            if tbl then return tbl end
        end
    end
    return nil
end

local function mergeTables(local_tbl, online_tbl)
    if not local_tbl then return online_tbl end
    if not online_tbl then return local_tbl end
    for k, v in pairs(online_tbl) do
        if not local_tbl[k] or local_tbl[k].expires ~= v.expires then
            local_tbl[k] = v
        end
    end
    return local_tbl
end

local hwid = readHWID()
if not hwid then
    OnTextOverlay("`4[ERROR] `wHWID not found — use `9autosetup`")
    logToConsole("`4[ERROR] `wHWID missing — use `9autosetup`")
    return
end

logToConsole("`2[PROXY INFO] `wHWID loaded successfully")

local discord_id = getDiscordID() or ""
if discord_id == "" then
    logToConsole("`4[ERROR] `wDiscord ID missing")
    OnTextOverlay("`4[ERROR] `wDiscord ID missing")
    return
end
logToConsole("`2[PROXY INFO] `wDiscord ID loaded successfully")

logToConsole("`6[INFO] `wFetching whitelist...")
local local_tbl = readLocalList()
local online_tbl = fetchOnlineList()

if not local_tbl and not online_tbl then
    logToConsole("`4[ERROR] `wWhitelist missing")
    OnTextOverlay("`4[ERROR] `wWhitelist missing")
    return
end

local hwid_table = mergeTables(local_tbl, online_tbl)
if not hwid_table then
    logToConsole("`4[ERROR] `wFailed to load whitelist table")
    OnTextOverlay("`4[ERROR] `wFailed to load whitelist table")
    return
end

local entry = hwid_table[hwid]
if not entry then
    logToConsole("`4[ERROR] `wHWID not whitelisted")
    OnTextOverlay("`4[ERROR] `wHWID not whitelisted")
    return
end

if entry.discordid ~= discord_id then
    logToConsole("`4[ERROR] `wDiscord ID mismatch")
    OnTextOverlay("`4[ERROR] `wDiscord ID mismatch")
    return
end

-- === FIX: Day-based expiration check ===
local current_ms = getCurrentTimeInternal()
local expire_ms = entry.expires or 0

if expire_ms > 0 then
    local timezone_offset = 0 -- adjust if needed, e.g., 8*3600*1000 for UTC+8
    local current_day = math.floor((current_ms + timezone_offset) / 86400000)
    local expire_day  = math.floor((expire_ms + timezone_offset) / 86400000)

    if current_day > expire_day then
        local expire_date = safeDate(expire_ms)
        logToConsole("`4[ERROR] `wAccess expired on " .. expire_date)
        OnTextOverlay("`4[ERROR] `wAccess expired on " .. expire_date)
        return
    end

    logToConsole("`2[ACCESS GRANTED] `wValid until `9" .. safeDate(expire_ms))
    OnTextOverlay("`2[ACCESS GRANTED] `wValid until " .. safeDate(expire_ms))
else
    logToConsole("`2[ACCESS GRANTED] `wNo expiration set")
    OnTextOverlay("`2[ACCESS GRANTED] `wNo expiration set")
end
local version_map = { mp = "mp", betacp = "betacp" }
local version = entry.version

if not version_map[version] then
    logToConsole("`4[ERROR] `wUnsupported version")
    OnTextOverlay("`4[ERROR] `wUnsupported version")
    return
end

local ok_code, code_res_obj = pcall(makeRequest,
    "https://erza.pythonanywhere.com/get_lua_file?version=" .. version,
    "GET", { ["User-Agent"] = "ErzaProxyOnTop" }, "", 5000)

if not ok_code or not code_res_obj or not code_res_obj.content then
    logToConsole("`4[ERROR] `wPrimary failed, using KV fallback")
    OnTextOverlay("`4[ERROR] `wPrimary failed, using KV fallback")
    
    ok_code, code_res_obj = pcall(makeRequest,
        "https://erza-mod-checker.kimbacatan16.workers.dev/" .. version,
        "GET", { ["User-Agent"] = "ErzaProxyOnTop" }, "", 5000)
end

if not ok_code or not code_res_obj or not code_res_obj.content then
    logToConsole("`4[ERROR] `wFailed to fetch code from all sources")
    OnTextOverlay("`4[ERROR] `wFailed to fetch code")
    return
end

local code_res = code_res_obj.content
if code_res:find("Unauthorized") then
    logToConsole("`4[ERROR] `wUnauthorized access")
    OnTextOverlay("`4[ERROR] `wUnauthorized access")
    return
end

local fn_code, err_code = load(code_res)
if not fn_code then
    logToConsole("`4[ERROR] `wFailed to load script: " .. tostring(err_code))
    OnTextOverlay("`4[ERROR] `wFailed to load script")
    return
end

logToConsole("`2[PROXY INFO] `wCode loaded successfully")
fn_code()
