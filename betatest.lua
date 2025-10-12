-- Function to display overlay messages
function OnTextOverlay(text)
    sendVariant({
        [0] = "OnTextOverlay",
        [1] = text,
    }, -1, 0)
end

-- Example version you want to load ("mp" or "betatest")
local version = "mp"  -- change to "betatest" to test beta proxy

-- Debug
logToConsole("Fetching Lua code for version: " .. version)

-- Fetch Lua code using makeRequest
local response = makeRequest(
    "https://erza.pythonanywhere.com/get_lua_file?version=" .. version,
    "GET",
    { {"User-Agent", "ErzaProxyOnTop"} },
    "",
    5000
)

-- Debug response
if response then
    logToConsole("Response object received")
    logToConsole("Content length: " .. tostring(#response.content))
    logToConsole("Preview: " .. tostring(response.content):sub(1, 50))
else
    logToConsole("No response from server")
    OnTextOverlay("`4[ERROR] `0No response from server")
end

-- Handle the response
if response and response.content then
    local content = response.content

    if content:match("Unauthorized") then
        logToConsole("`4[ERROR] `0Unauthorized: your request was rejected by the server")
        OnTextOverlay("`4[ERROR] `0Unauthorized")
    else
        -- Try loading the Lua code
        local fn, err = load(content)
        if fn then
            logToConsole("Lua code loaded successfully")
            fn()
        else
            logToConsole("`4[ERROR] Failed to load Lua code: " .. tostring(err))
            OnTextOverlay("`4[ERROR] `0Failed to load Lua code")
        end
    end
end
