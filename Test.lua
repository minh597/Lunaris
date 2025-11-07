local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- === CONFIGURATION ===
local TARGET_TEXT = "CHALET"           -- Text to find in map name
local SOLO_ONLY = true                 -- Only enter if empty
local CHECK_INTERVAL = 2               -- Scan every 2 seconds
local MAX_PLAYERS = 1                  -- Return to lobby if players >= this
local LOBBY_PLACE_ID = game.PlaceId    -- Place ID to return to (change if needed)
-- =====================

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChaletFinder"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 360, 0, 500)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(255, 100, 100)
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "Finding APC with 'CHALET'"
title.TextColor3 = Color3.fromRGB(255, 100, 100)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -50)
scroll.Position = UDim2.new(0, 5, 0, 45)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 6
scroll.BackgroundTransparency = 1
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

-- Store labels by APC ID
local labels = {}

-- State variables
local hasEntered = false
local currentTargetMap = nil
local isMonitoring = false

-- Function to return to lobby
local function returnToLobby()
    title.Text = "Returning to lobby..."
    title.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    -- Teleport to lobby
    local success, err = pcall(function()
        TeleportService:Teleport(LOBBY_PLACE_ID, player)
    end)
    
    if not success then
        warn("Failed to teleport to lobby:", err)
        title.Text = "Teleport failed - Retrying..."
        task.wait(2)
        returnToLobby() -- Retry
    end
end

-- Function to update GUI and find CHALET
local function scanAndEnter()
    local apcList = {}
    local apcs = Workspace:FindFirstChild("APCs")
    local apcs2 = Workspace:FindFirstChild("APCs2")

    -- Collect APCs 1-10
    if apcs then
        for i = 1, 10 do
            local f = apcs:FindFirstChild(tostring(i))
            if f then table.insert(apcList, {id = i, folder = f}) end
        end
    end
    -- Collect APCs 11-16
    if apcs2 then
        for i = 11, 16 do
            local f = apcs2:FindFirstChild(tostring(i))
            if f then table.insert(apcList, {id = i, folder = f}) end
        end
    end

    local foundChalet = false
    local targetRamp = nil
    local chaletPlayerCount = 0

    for _, data in ipairs(apcList) do
        local id = data.id
        local folder = data.folder
        local label = labels[id]

        -- Create label if not exists
        if not label then
            label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -10, 0, 32)
            label.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.Parent = scroll
            labels[id] = label
        end

        -- Get map TextLabel safely
        local mapTextBox
        local mapDisplay = folder:FindFirstChild("mapdisplay", true)
        if mapDisplay then
            local screen = mapDisplay:FindFirstChild("screen")
            if screen then
                local display = screen:FindFirstChild("displayscreen")
                if display then
                    mapTextBox = display:FindFirstChild("map")
                end
            end
        end

        local mapName = "Unknown"
        if mapTextBox and (mapTextBox:IsA("TextBox") or mapTextBox:IsA("TextLabel")) then
            mapName = mapTextBox.Text or mapTextBox.ContentText or "Unknown"
        end

        -- Count seated players
        local seatFolder = folder:FindFirstChild("APC")
        local playerCount = 0
        if seatFolder and seatFolder:FindFirstChild("Seats") then
            for _, seat in ipairs(seatFolder.Seats:GetChildren()) do
                if seat:IsA("Seat") and seat.Occupant then
                    playerCount += 1
                end
            end
        end

        -- Check if has CHALET
        local hasTarget = mapName:lower():find(TARGET_TEXT:lower()) ~= nil
        local isEmpty = playerCount == 0

        -- Update color + text
        if hasTarget then
            foundChalet = true
            chaletPlayerCount = playerCount
            currentTargetMap = mapName
            
            if isEmpty then
                label.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                label.Text = string.format("APC[%02d]: %s [CHALET] (Empty)", id, mapName)
                targetRamp = seatFolder and seatFolder:FindFirstChild("Ramp")
            else
                label.BackgroundColor3 = Color3.fromRGB(120, 60, 0)
                label.TextColor3 = Color3.fromRGB(255, 200, 100)
                label.Text = string.format("APC[%02d]: %s [CHALET] (%d players)", id, mapName, playerCount)
            end
            
            -- Check if player count > MAX_PLAYERS and we're monitoring
            if isMonitoring and playerCount > MAX_PLAYERS then
                print("Target map has "..playerCount.." players (max: "..MAX_PLAYERS..") - Returning to lobby")
                returnToLobby()
                return
            end
        elseif playerCount > 0 then
            label.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
            label.TextColor3 = Color3.fromRGB(255, 150, 150)
            label.Text = string.format("APC[%02d]: %s (%d players)", id, mapName, playerCount)
        else
            label.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            label.TextColor3 = Color3.fromRGB(180, 180, 180)
            label.Text = string.format("APC[%02d]: %s", id, mapName)
        end

        -- If found empty CHALET and haven't entered yet → teleport to Ramp
        if hasTarget and isEmpty and targetRamp and not hasEntered then
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Teleport to Ramp
                hrp.CFrame = targetRamp.CFrame + Vector3.new(0, 5, 0)
                task.wait(1)

                -- Check if seated
                local seats = seatFolder and seatFolder:FindFirstChild("Seats")
                if seats then
                    for _, seat in ipairs(seats:GetChildren()) do
                        if seat:IsA("Seat") and seat.Occupant == character:FindFirstChild("Humanoid") then
                            print("ENTERED CHALET APC: APC["..id.."]")
                            hasEntered = true
                            isMonitoring = true -- Start monitoring player count
                            title.Text = "MONITORING CHALET (Players: "..chaletPlayerCount..")"
                            title.TextColor3 = Color3.fromRGB(0, 255, 0)
                            return
                        end
                    end
                end

                -- If not seated → try again
                hrp.CFrame = targetRamp.CFrame + Vector3.new(0, 5, 0)
            end
        end
    end

    -- Update Canvas
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)

    -- Update title based on state
    if isMonitoring then
        title.Text = "MONITORING CHALET (Players: "..chaletPlayerCount.."/"..MAX_PLAYERS..")"
        title.TextColor3 = Color3.fromRGB(0, 255, 0)
    elseif not foundChalet then
        title.Text = "Searching for 'CHALET'... (0/16)"
        currentTargetMap = nil
    else
        if chaletPlayerCount == 0 then
            title.Text = "Found CHALET! Waiting for empty..."
        else
            title.Text = "Found CHALET! ("..chaletPlayerCount.." players)"
        end
    end
end

-- Scan loop (continues even after entering)
spawn(function()
    while true do
        if Workspace:FindFirstChild("APCs") or Workspace:FindFirstChild("APCs2") then
            pcall(scanAndEnter)
        else
            title.Text = "No APCs found → In match or lobby"
        end
        task.wait(CHECK_INTERVAL)
    end
end)
