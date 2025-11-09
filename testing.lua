local LunarisX = getgenv().LunarisX or {}
local rawFileURL = LunarisX.MacroUrl
local map = LunarisX.Map
local difficulty = LunarisX.Difficulty

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

if Workspace:FindFirstChild("APCs") then
    -- Nếu thấy APCs thì chạy Tele.lua trực tiếp
    loadstring(game:HttpGet("https://raw.githubusercontent.com/minh597/Lunaris/refs/heads/main/Tele.lua"))()
else
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")

    -- Vote difficulty
    Remotes.DifficultyVoteCast:FireServer(difficulty)
    task.wait(0.5)
    Remotes.DifficultyVoteReady:FireServer()
    task.wait(0.5)
    Remotes.SoloToggleSpeedControl:FireServer(true, true)

    -- Leaderstats & cash
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

    -- Execute raw macro file
    local function executeRawFile(url)
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        if not success then return end

        for line in result:gmatch("[^\r\n]+") do
            line = line:match("^%s*(.-)%s*$")
            if line ~= "" and not line:match("^%-%-") then
                pcall(function()
                    local func = loadstring(line)
                    if func then func() end
                end)
            end
        end
    end

    executeRawFile(rawFileURL)

    -- Game over teleport back to lobby
    task.spawn(function()
        local gui = player:WaitForChild("PlayerGui"):WaitForChild("Interface"):WaitForChild("GameOverScreen")
        gui:GetPropertyChangedSignal("Visible"):Connect(function()
            if gui.Visible then
                game:GetService("TeleportService"):Teleport(9503261072, player)
            end
        end)
    end)
end
