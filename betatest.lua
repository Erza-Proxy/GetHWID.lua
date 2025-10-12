-- Minimal Lua fetcher for mobile proxy

local version = "mp"  -- or "betacp"
local url = "https://erza.pythonanywhere.com/get_lua_file?version=" .. version

-- Make the HTTP request
local res_obj = makeRequest(
    url,
    "GET",
    { {"User-Agent", "ErzaProxyOnTop"} },
    "",
    5000
)

-- Debug: log HTTP response length and content (short preview)
logToConsole("HTTP response length: " .. tostring(#res_obj.content))
logToConsole("HTTP response preview: " .. tostring(res_obj.content:sub(1, 50)))

-- Check response
if res_obj.content and #res_obj.content > 0 then
    if res_obj.content:find("Unauthorized") then
        logToConsole("[ERROR] Unauthorized: check User-Agent or version")
    elseif res_obj.content:find("File not found") then
        logToConsole("[ERROR] File not found on server")
    else
        -- Attempt to load Lua code
        local fn, err = load(res_obj.content)
        if fn then
            fn()  -- run the Lua code
            logToConsole("[INFO] Lua code loaded successfully")
        else
            logToConsole("[ERROR] Failed to load Lua code: " .. tostring(err))
        end
    end
else
    logToConsole("[ERROR] Empty response from server")
end
