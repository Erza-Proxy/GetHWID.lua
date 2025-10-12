local version = "mp"  -- or "betatest"
local res_obj = makeRequest(
    "https://yourserver.com/get_lua_file?version=" .. version,
    "GET",
    { {"User-Agent", "ErzaProxyOnTop"} },
    "",
    5000
)

logToConsole("Response content: " .. tostring(res_obj.content))
logToConsole("Response length: " .. tostring(#res_obj.content))
