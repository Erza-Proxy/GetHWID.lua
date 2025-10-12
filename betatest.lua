-- Simple Lua Debugger for Genta / Mobile Proxy

-- Print with type info
function debugPrint(label, value)
    if value == nil then
        logToConsole(label .. " = nil")
    else
        logToConsole(label .. " = " .. tostring(value) .. " (" .. type(value) .. ")")
    end
end

-- Debug HTTP responses from makeRequest
function debugRequest(url, method, headers, body, timeout)
    local res = makeRequest(url, method or "GET", headers or {}, body or "", timeout or 5000)

    if not res then
        logToConsole("[DEBUG] No response received from: " .. url)
        return nil
    end

    debugPrint("[DEBUG] Response object", res)
    if res.content then
        debugPrint("[DEBUG] Response content length", #res.content)
        -- Print first 300 chars only to avoid spam
        debugPrint("[DEBUG] Response preview", res.content:sub(1,300))
    else
        logToConsole("[DEBUG] No content in response")
    end

    return res
end

-- Example usage
local version = "mp"
local url = "https://erza.pythonanywhere.com/get_lua_file?version=" .. version
local res = debugRequest(url, "GET", {{"User-Agent", "ErzaProxyOnTop"}}, "", 5000)

if res and res.content then
    logToConsole("[DEBUG] Full response ready for loading")
    -- You can attempt to load it
    local fn, err = load(res.content)
    if fn then
        logToConsole("[DEBUG] Lua code loaded successfully")
        -- fn() -- uncomment to execute
    else
        debugPrint("[DEBUG] Failed to load Lua code", err)
    end
end
