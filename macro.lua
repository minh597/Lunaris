local LunarisX = getgenv().LunarisX or {}
local rawFileURL = LunarisX.MacroUrl
local map = LunarisX.Map
local difficulty = LunarisX.Difficulty

local function joingame()
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local TeleportService = game:GetService("TeleportService")
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local SOLO_ONLY = true
    local CHECK_INTERVAL = 1
    local MAX_PLAYERS = 1
    local LOBBY_PLACE_ID = game.PlaceId

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MapFinder"
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
    title.Text = "Finding APC with '" .. map:upper() .. "'"
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

    local labels = {}
    local hasEntered = false
    local currentTargetMap = nil
    local isMonitoring = false

    local function returnToLobby()
        title.Text = "Returning to lobby..."
        title.TextColor3 = Color3.fromRGB(255, 200, 0)
        
        local success, err = pcall(function()
            TeleportService:Teleport(LOBBY_PLACE_ID, player)
        end)
        
        if not success then
            task.wait(2)
            returnToLobby()
        end
    end

    local function scanAndEnter()
        local apcList = {}
        local apcs = Workspace:FindFirstChild("APCs")
        local apcs2 = Workspace:FindFirstChild("APCs2")

        if apcs then
            for i = 1, 10 do
                local f = apcs:FindFirstChild(tostring(i))
                if f then table.insert(apcList, {id = i, folder = f}) end
            end
        end
        if apcs2 then
            for i = 11, 16 do
                local f = apcs2:FindFirstChild(tostring(i))
                if f then table.insert(apcList, {id = i, folder = f}) end
            end
        end

        local foundTarget = false
        local targetRamp = nil
        local targetPlayerCount = 0

        for _, data in ipairs(apcList) do
            local id = data.id
            local folder = data.folder
            local label = labels[id]

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

            local seatFolder = folder:FindFirstChild("APC")
            local playerCount = 0
            if seatFolder and seatFolder:FindFirstChild("Seats") then
                for _, seat in ipairs(seatFolder.Seats:GetChildren()) do
                    if seat:IsA("Seat") and seat.Occupant then
                        playerCount += 1
                    end
                end
            end

            local hasTarget = mapName:lower():find(map:lower()) ~= nil
            local isEmpty = playerCount == 0

            if hasTarget then
                foundTarget = true
                targetPlayerCount = playerCount
                currentTargetMap = mapName
                
                if isEmpty then
                    label.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
                    label.TextColor3 = Color3.fromRGB(255, 255, 255)
                    label.Text = string.format("APC[%02d]: %s [%s] (Empty)", id, mapName, map:upper())
                    targetRamp = seatFolder and seatFolder:FindFirstChild("Ramp")
                else
                    label.BackgroundColor3 = Color3.fromRGB(120, 60, 0)
                    label.TextColor3 = Color3.fromRGB(255, 200, 100)
                    label.Text = string.format("APC[%02d]: %s [%s] (%d players)", id, mapName, map:upper(), playerCount)
                end
                
                if isMonitoring and playerCount > MAX_PLAYERS then
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

            if hasTarget and isEmpty and targetRamp and not hasEntered then
                local character = player.Character or player.CharacterAdded:Wait()
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = targetRamp.CFrame + Vector3.new(0, 5, 0)
                    task.wait(1)

                    local seats = seatFolder and seatFolder:FindFirstChild("Seats")
                    if seats then
                        for _, seat in ipairs(seats:GetChildren()) do
                            if seat:IsA("Seat") and seat.Occupant == character:FindFirstChild("Humanoid") then
                                hasEntered = true
                                isMonitoring = true
                                title.Text = "MONITORING " .. map:upper() .. " (Players: " .. targetPlayerCount .. ")"
                                title.TextColor3 = Color3.fromRGB(0, 255, 0)
                                return
                            end
                        end
                    end

                    hrp.CFrame = targetRamp.CFrame + Vector3.new(0, 5, 0)
                end
            end
        end

        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)

        if isMonitoring then
            title.Text = "MONITORING " .. map:upper() .. " (Players: " .. targetPlayerCount .. "/" .. MAX_PLAYERS .. ")"
            title.TextColor3 = Color3.fromRGB(0, 255, 0)
        elseif not foundTarget then
            title.Text = "Searching for '" .. map:upper() .. "'... (0/16)"
            currentTargetMap = nil
        else
            if targetPlayerCount == 0 then
                title.Text = "Found " .. map:upper() .. "! Waiting for empty..."
            else
                title.Text = "Found " .. map:upper() .. "! (" .. targetPlayerCount .. " players)"
            end
        end
    end

    spawn(function()
        while true do
            if Workspace:FindFirstChild("APCs") or Workspace:FindFirstChild("APCs2") then
                pcall(scanAndEnter)
            else
                title.Text = "No APCs found"
            end
            task.wait(CHECK_INTERVAL)
        end
    end)
end

if workspace:FindFirstChild("APCs") then
    joingame()
else
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")

    Remotes.DifficultyVoteCast:FireServer(difficulty)
    task.wait(0.5)
    Remotes.DifficultyVoteReady:FireServer()
    task.wait(0.5)
    Remotes.SoloToggleSpeedControl:FireServer(true, true)

    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local leaderstats = player:WaitForChild("leaderstats")
    local cashValue = leaderstats:WaitForChild("Cash")

    local PlaceTower = Remotes:WaitForChild("PlaceTower")
    local TowerUpgradeRequest = Remotes:WaitForChild("TowerUpgradeRequest")
    local SellTower = Remotes:WaitForChild("SellTower")

    local function getCash()
        return tonumber(cashValue.Value) or 0
    end

    local function waitForCash(amount)
        while getCash() < amount do
            task.wait(0.2)
        end
    end

    function place(slot, towerName, position, rotation, cost)
        cost = cost or 0
        waitForCash(cost)
        PlaceTower:InvokeServer(slot, towerName, position, rotation)
        task.wait(0.1)
    end

    function upgrade(index, path, tier, cost)
        cost = cost or 0
        waitForCash(cost)
        TowerUpgradeRequest:FireServer(index, path, tier)
        task.wait(0.1)
    end

    function sell(index)
        SellTower:FireServer(index)
    end

    local function executeRawFile(url)
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        
        if not success then
            return
        end
        
        for line in result:gmatch("[^\r\n]+") do
            line = line:match("^%s*(.-)%s*$")
            
            if line ~= "" and not line:match("^%-%-") then
                pcall(function()
                    local func = loadstring(line)
                    if func then
                        func()
                    end
                end)
            end
        end
    end

    executeRawFile(rawFileURL)

    task.spawn(function()
        local p = game.Players.LocalPlayer
        local gui = p:WaitForChild("PlayerGui"):WaitForChild("Interface"):WaitForChild("GameOverScreen")
        gui:GetPropertyChangedSignal("Visible"):Connect(function()
            if gui.Visible then
                game:GetService("TeleportService"):Teleport(9503261072, p)
            end
        end)
    end)
end