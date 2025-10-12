-- Simple test fetch with debug
local version = "mp"  -- or "betatest"

-- Fetch Lua code from server
local res_obj = makeRequest(
    "https://erza.pythonanywhere.com/get_lua_file?version=" .. version,
    "GET",
    { {"User-Agent", "ErzaProxyOnTop"} },
    "",
    5000
)

-- Debug outputs
logToConsole("HTTP response object: " .. tostring(res_obj))
logToConsole("Response content length: " .. tostring(res_obj.content and #res_obj.content or 0))
logToConsole("Response preview (first 200 chars): " .. (res_obj.content and res_obj.content:sub(1,200) or "nil"))

-- Check if server returned Unauthorized
if res_obj.content and res_obj.content:find("Unauthorized") then
    logToConsole("Server response: Unauthorized")
else
    logToConsole("Server response looks okay")
end
