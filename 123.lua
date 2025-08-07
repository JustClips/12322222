--// Player Heartbeat - Registers player presence to backend //--

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Backend URL
local BACKEND_URL = "https://discordbot-production-800b.up.railway.app"
local HEARTBEAT_INTERVAL = 5 -- Send heartbeat every 5 seconds

-- Check for force-join commands
local function checkForceJoin()
    local username = Players.LocalPlayer.Name:lower()
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
    end
    
    if success and result and result.Body then
        local data = HttpService:JSONDecode(result.Body)
        
        if data.hasCommand then
            -- Execute the force-join
            local placeId = tonumber(data.placeId)
            local jobId = data.jobId
            
            -- Attempt to teleport
            local TeleportService = game:GetService("TeleportService")
            pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, jobId, Players.LocalPlayer)
            end)
        end
    end
end

-- Send heartbeat to backend
local function sendHeartbeat()
    local payload = {
        username = Players.LocalPlayer.Name,
        serverId = tostring(game.PlaceId),
        jobId = tostring(game.JobId),
        placeId = tostring(game.PlaceId)
    }
    
    local json = HttpService:JSONEncode(payload)
    local success, result
    
    if syn and syn.request then
        success, result = pcall(syn.request, {
            Url = BACKEND_URL .. "/players/heartbeat",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    elseif request then
        success, result = pcall(request, {
            Url = BACKEND_URL .. "/players/heartbeat",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    elseif http_request then
        success, result = pcall(http_request, {
            Url = BACKEND_URL .. "/players/heartbeat",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    end
end

-- Start heartbeat loop
spawn(function()
    while true do
        sendHeartbeat()
        checkForceJoin()
        wait(HEARTBEAT_INTERVAL)
    end
end)

-- Silent operation - no console output
