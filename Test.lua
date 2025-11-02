local LunarisX = getgenv().LunarisX or {}
local autoskip = LunarisX.autoskip
local SellAllTower = LunarisX.SellAllTower
local AtWave = LunarisX.AtWave
local autoCommander = LunarisX.autoCommander
local url = LunarisX.MarcoUrl

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local TeleportService = game:GetService("TeleportService")
local player = game.Players.LocalPlayer
local remoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local towerFolder = workspace:WaitForChild("Towers")

-- 🪙 Cash label
local cashLabel = player.PlayerGui:WaitForChild("ReactUniversalHotbar")
    :WaitForChild("Frame")
    :WaitForChild("values")
    :WaitForChild("cash")
    :WaitForChild("amount")

-- 🏹 Wave container
local waveContainer = player.PlayerGui:WaitForChild("ReactGameTopGameDisplay")
    :WaitForChild("Frame")
    :WaitForChild("wave")
    :WaitForChild("container")

-- 🎮 Game over GUI
local gameOverGui = player.PlayerGui:WaitForChild("ReactGameNewRewards")
    :WaitForChild("Frame")
    :WaitForChild("gameOver")

-- 💰 Cash functions
local function getCash()
    local rawText = cashLabel.Text or ""
    local cleaned = rawText:gsub("[^%d%-]", "")
    return tonumber(cleaned) or 0
end

local function waitForCash(minAmount)
    while getCash() < minAmount do
        task.wait(1)
    end
end

local function safeInvoke(args, cost)
    waitForCash(cost)
    pcall(function()
        remoteFunction:InvokeServer(unpack(args))
    end)
    task.wait(1)
end

-- 📍 Position check
local function isSamePos(a, b, eps)
    eps = eps or 0.05
    return math.abs(a.X - b.X) <= eps
       and math.abs(a.Y - b.Y) <= eps
       and math.abs(a.Z - b.Z) <= eps
end

-- 🏗 Place tower
function place(x, y, z, name, cost)
    local pos = Vector3.new(x, y, z)
    safeInvoke({
        "Troops",
        "Pl\208\176ce",
        {Rotation = CFrame.new(), Position = pos},
        name
    }, cost)
end

-- 🔼 Upgrade tower
function upgrade(x, y, z, cost)
    local pos = Vector3.new(x, y, z)
    local tower
    for _, t in ipairs(towerFolder:GetChildren()) do
        local tPos = (t.PrimaryPart and t.PrimaryPart.Position) or t.Position
        if isSamePos(tPos, pos, 0.05) then
            tower = t
            break
        end
    end
    if tower then
        safeInvoke({"Troops", "Upgrade", "Set", {Troop = tower}}, cost)
    end
end

-- 💸 Sell tower by position
function sell(x, y, z)
    local pos = Vector3.new(x, y, z)
    local tower
    for _, t in ipairs(towerFolder:GetChildren()) do
        local tPos = (t.PrimaryPart and t.PrimaryPart.Position) or t.Position
        if isSamePos(tPos, pos, 0.05) then
            tower = t
            break
        end
    end
    if tower then
        pcall(function()
            remoteFunction:InvokeServer("Troops", "Se\108\108", {Troop = tower})
        end)
    end
end

-- 🛠 Sell all towers
function sellAllTowers()
    for _, tower in ipairs(towerFolder:GetChildren()) do
        pcall(function()
            remoteFunction:InvokeServer("Troops", "Se\108\108", {Troop = tower})
        end)
        task.wait(0.1)
    end
end

-- ⏩ Skip voting
local skipVotingFlag = false
local function skipVoting()
    task.spawn(function()
        while skipVotingFlag do
            pcall(function()
                remoteFunction:InvokeServer("Voting", "Skip")
            end)
            task.wait(1)
        end
    end)
end

local function skipwave()
    task.spawn(function()
        while true do
            pcall(function()
                ReplicatedStorage:WaitForChild("RemoteFunction"):InvokeServer("Voting", "Skip")
            end)
            task.wait(1)
        end
    end)
end

if autoskip == true then
    skipwave()
end

if skip == true then
    skipVotingFlag = true
    skipVoting()
end

local function firstskip()
    skipVotingFlag = true
    skipVoting()
    task.spawn(function()
        task.wait(5)
        skipVotingFlag = false
    end)
end

-- 🌊 Get current wave
local function getWave()
    for _, label in ipairs(waveContainer:GetDescendants()) do
        if label:IsA("TextLabel") then
            local waveNum = tonumber(label.Text:match("^(%d+)"))
            if waveNum then
                return waveNum
            end
        end
    end
    return nil
end

-- ⚡ Setup farm
local function setupfarm()
    local rawUrl = url
    local content
    local success, err = pcall(function()
        content = game:HttpGet(rawUrl)
    end)
    if not success or not content then
        warn("Không thể load file raw:", err)
        return
    end

    pcall(function()
        local f = loadstring(content)
        if f then f() end
    end)
end

-- 👀 Listen wave changes
for _, label in ipairs(waveContainer:GetDescendants()) do
    if label:IsA("TextLabel") then
        label:GetPropertyChangedSignal("Text"):Connect(function()
            local wave = getWave()

            if wave == 1 then
                setupfarm()
            end

            if wave == AtWave and SellAllTower == true then
                sellAllTowers()
            end
        end)
    end
end

-- ⌨ Auto CTA
local interval = 10
local vim_ok, vim = pcall(function()
    return game:GetService("VirtualInputManager")
end)

local function autoCTA()
    if vim_ok and vim and vim.SendKeyEvent then
        pcall(function()
            vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            task.wait(0.00001)
            vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
    end
end

if autoCommander == true then
    task.spawn(function()
        while task.wait(interval) do
            autoCTA()
        end
    end)
end

-- 🎮 Game over
gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        task.wait(2)
        firstskip()
    end
end)
