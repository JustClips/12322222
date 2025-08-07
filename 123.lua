--// Force Join Receiver - Executor Direct Method //--

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local BACKEND_URL = "https://discordbot-production-800b.up.railway.app"
local CHECK_INTERVAL = 2

-- Check and execute force join
local function checkForceJoin()
    local username = localPlayer.Name:lower()
    local checkUrl = BACKEND_URL .. "/forcejoin/" .. username
    
    local success, result
    if syn and syn.request then
        success, result = pcall(syn.request, {
            Url = checkUrl,
            Method = "GET"
        })
    elseif request then
        success, result = pcall(request, {
            Url = checkUrl,
            Method = "GET"
        })
    elseif http_request then
        success, result = pcall(http_request, {
            Url = checkUrl,
            Method = "GET"
        })
    end
    
    if success and result and result.Body then
        local data = HttpService:JSONDecode(result.Body)
        
        if data.hasCommand then
            -- YOUR EXACT TELEPORT METHOD
            local placeId = tonumber(data.placeId)
            local jobId = data.jobId
            
            local success, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, jobId, localPlayer)
            end)
            
            if not success then
                warn("Teleport failed: " .. tostring(err))
            else
                print("Teleporting to job ID: " .. jobId)
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
    end
end

-- Main loops
spawn(function()
    while true do
        pcall(sendHeartbeat)
        wait(10)
    end
end)

spawn(function()
    while true do
        pcall(checkForceJoin)
        wait(CHECK_INTERVAL)
    end
end)

print("Force Join Receiver Active for:", localPlayer.Name)
