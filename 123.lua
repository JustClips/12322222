--// Universal Force Join Checker - Executor Version //--

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local BACKEND_URL = "https://discordbot-production-800b.up.railway.app"
local CHECK_INTERVAL = 2
local HEARTBEAT_INTERVAL = 8

-- Keep track of last command
local lastCommandTime = 0

-- Direct teleport using executor (bypasses Roblox restrictions)
local function performTeleport(placeId, jobId)
    -- Convert to number if string
    local placeIdNum = tonumber(placeId) or placeId
    
    -- Use the EXACT method you provided
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeIdNum, jobId, localPlayer)
    end)
    
    if not success then
        warn("Teleport failed: " .. tostring(err))
        
        -- Retry once after a short delay
        wait(1)
        local retry, retryErr = pcall(function()
            TeleportService:TeleportToPlaceInstance(placeIdNum, jobId, localPlayer)
        end)
        
        if not retry then
            warn("Retry failed: " .. tostring(retryErr))
        end
    else
        print("Teleporting to PlaceId: " .. tostring(placeIdNum))
        print("Teleporting to JobId: " .. jobId)
    end
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
    end
    
    if success and result then
        local body = result.Body or result
        if type(body) == "string" and body ~= "" then
            local parseSuccess, data = pcall(function()
                return HttpService:JSONDecode(body)
            end)
            
            if parseSuccess and data and data.hasCommand == true then
                -- Avoid duplicate commands
                local currentTime = tick()
                if currentTime - lastCommandTime > 5 then
                    lastCommandTime = currentTime
                    
                    -- Execute the teleport immediately
                    performTeleport(data.placeId, data.jobId)
                end
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

-- Main heartbeat loop
spawn(function()
    while true do
        pcall(sendHeartbeat)
        wait(HEARTBEAT_INTERVAL)
    end
end)

-- Force join check loop
spawn(function()
    wait(1)
    while true do
        pcall(checkForceJoin)
        wait(CHECK_INTERVAL)
    end
end)

-- Keep alive
while true do
    wait(60)
end
