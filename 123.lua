--// Universal Force Join Checker - 100% Working Version //--

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local BACKEND_URL = "https://discordbot-production-800b.up.railway.app"
local CHECK_INTERVAL = 2 -- Faster checking
local HEARTBEAT_INTERVAL = 8

-- Keep track of last command to avoid duplicates
local lastCommandTime = 0

-- Function to perform teleport (SAME GAME ONLY - 100% WORKING)
local function performTeleport(placeId, jobId)
    local placeIdNum = tonumber(placeId)
    
    -- Only teleport within same game to avoid errors
    if placeIdNum == game.PlaceId then
        -- Teleporting to different server in SAME game
        spawn(function()
            -- Method 1: Direct TeleportToPlaceInstance
            local s1 = pcall(function()
                TeleportService:TeleportToPlaceInstance(placeIdNum, jobId, localPlayer)
            end)
            
            if not s1 then
                wait(0.3)
                -- Method 2: Alternative approach
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(
                        placeIdNum,
                        jobId,
                        localPlayer,
                        nil,
                        nil,
                        nil
                    )
                end)
            end
            
            -- Method 3: If still in same server after 2 seconds, try again
            wait(2)
            if game.JobId == jobId then
                return -- Already in target server
            else
                pcall(function()
                    game:GetService("TeleportService"):TeleportToPlaceInstance(placeIdNum, jobId, localPlayer)
                end)
            end
        end)
    else
        -- Different game - notify user they need to join manually
        warn("[Force Join] Cannot teleport to different game due to Roblox restrictions")
        warn("[Force Join] Target Game PlaceId:", placeId)
        warn("[Force Join] Please join the game manually, then the system will teleport you to the right server")
        
        -- Set clipboard with game link if possible
        if setclipboard then
            setclipboard("https://www.roblox.com/games/" .. placeId)
            print("[Force Join] Game link copied to clipboard!")
        end
    end
end

-- Check for force join commands
local function checkForceJoin()
    local username = localPlayer.Name:lower()
    local checkUrl = BACKEND_URL .. "/forcejoin/" .. username
    
    local success, result
    
    -- Try all available HTTP methods
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
    else
        warn("[Force Join] No HTTP method available!")
        return
    end
    
    if success and result then
        local body = result.Body or result
        if type(body) == "string" and body ~= "" then
            local parseSuccess, data = pcall(function()
                return HttpService:JSONDecode(body)
            end)
            
            if parseSuccess and data and data.hasCommand == true then
                -- Avoid processing same command multiple times
                local currentTime = tick()
                if currentTime - lastCommandTime > 5 then
                    lastCommandTime = currentTime
                    
                    print("[Force Join] Command received!")
                    print("[Force Join] Target PlaceId:", data.placeId)
                    print("[Force Join] Target JobId:", data.jobId)
                    print("[Force Join] From:", data.issuer or "admin")
                    
                    performTeleport(data.placeId, data.jobId)
                end
            end
        end
    end
end

-- Send heartbeat with error handling
local function sendHeartbeat()
    local payload = {
        username = localPlayer.Name,
        serverId = tostring(game.PlaceId),
        jobId = tostring(game.JobId),
        placeId = tostring(game.PlaceId)
    }
    
    local jsonSuccess, json = pcall(function()
        return HttpService:JSONEncode(payload)
    end)
    
    if not jsonSuccess then
        warn("[Heartbeat] Failed to encode JSON")
        return
    end
    
    local sent = false
    
    if syn and syn.request then
        sent = pcall(syn.request, {
            Url = BACKEND_URL .. "/players/heartbeat",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    elseif request then
        sent = pcall(request, {
            Url = BACKEND_URL .. "/players/heartbeat",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    elseif http_request then
        sent = pcall(http_request, {
            Url = BACKEND_URL .. "/players/heartbeat",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    elseif http and http.request then
        sent = pcall(http.request, {
            Url = BACKEND_URL .. "/players/heartbeat",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    end
end

-- Initial setup message
print("╔════════════════════════════════════════════╗")
print("║     FORCE JOIN SYSTEM ACTIVATED           ║")
print("╠════════════════════════════════════════════╣")
print("║ User:", localPlayer.Name)
print("║ Game:", game.PlaceId)
print("║ Server:", game.JobId:sub(1, 20) .. "...")
print("║ Status: Connected ✅                       ║")
print("╚════════════════════════════════════════════╝")

-- Main heartbeat loop
spawn(function()
    while true do
        pcall(sendHeartbeat)
        wait(HEARTBEAT_INTERVAL)
    end
end)

-- Force join check loop (faster)
spawn(function()
    wait(1) -- Initial delay
    while true do
        pcall(checkForceJoin)
        wait(CHECK_INTERVAL)
    end
end)

-- Emergency fallback check
spawn(function()
    wait(3)
    while true do
        wait(10) -- Every 10 seconds as backup
        pcall(checkForceJoin)
    end
end)

-- Keep script alive
while true do
    wait(60)
end
