-- Version you want to test
local version = "mp"  -- or "betatest"

-- Debug: show what URL we're hitting
logToConsole("Testing makeRequest for version: " .. version)

-- Fetch Lua code from your Flask server using makeRequest
local response = makeRequest(
    "https://erza.pythonanywhere.com/get_lua_file?version=" .. version,
    "GET",
    { {"User-Agent", "ErzaProxyOnTop"} },
    "",
    5000
)

-- Debug: check if response is nil
if not response then
    logToConsole("[DEBUG] Response is nil")
else
    logToConsole("[DEBUG] Response object received")
end

-- Debug: print content length and first 200 characters
if response and response.content then
    logToConsole("[DEBUG] Response content length: " .. tostring(#response.content))
    logToConsole("[DEBUG] Response content preview: " .. response.content:sub(1, 200))
else
    logToConsole("[DEBUG] No content in response")
end
