-- 🌙 LunarisX Core Script

local LunarisX = getgenv().LunarisX or {}
local autoskip = LunarisX.autoskip
local SellAllTower = LunarisX.SellAllTower
local AtWave = LunarisX.AtWave
local setupfarm = LunarisX.setupfarm

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")

local player = game.Players.LocalPlayer
local towerFolder = workspace:WaitForChild("Towers")

local cashLabel = player
    :WaitForChild("PlayerGui")
    :WaitForChild("ReactUniversalHotbar")
    :WaitForChild("Frame")
    :WaitForChild("values")
    :WaitForChild("cash")
    :WaitForChild("amount")

local waveContainer = player
    :WaitForChild("PlayerGui")
    :WaitForChild("ReactGameTopGameDisplay")
    :WaitForChild("Frame")
    :WaitForChild("wave")
    :WaitForChild("container")

local gameOverGui = player
    :WaitForChild("PlayerGui")
    :WaitForChild("ReactGameNewRewards")
    :WaitForChild("Frame")
    :WaitForChild("gameOver")

-- 💰 Lấy tiền hiện tại
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

-- 🏗️ Đặt tower
function placeTower(position, name, cost)
    local args = { "Troops", "Place", { Rotation = CFrame.new(), Position = position }, name }
    waitForCash(cost)
    pcall(function()
        remoteFunction:InvokeServer(unpack(args))
    end)
    task.wait(1)
end

-- ⬆️ Nâng cấp tower
function upgradeTower(num, cost)
    local tower = towerFolder:GetChildren()[num]
    if tower then
        local args = { "Troops", "Upgrade", "Set", { Troop = tower } }
        waitForCash(cost)
        pcall(function()
            remoteFunction:InvokeServer(unpack(args))
        end)
        task.wait(1)
    end
end

-- 💸 Bán toàn bộ tower
function sellAllTowers()
    for _, tower in ipairs(towerFolder:GetChildren()) do
        local args = { "Troops", "Sell", { Troop = tower } }
        pcall(function()
            remoteFunction:InvokeServer(unpack(args))
        end)
        task.wait(0.2)
    end
end

-- 🌊 Tự bán tower khi đến wave chỉ định
if SellAllTower == true then
    for _, label in ipairs(waveContainer:GetDescendants()) do
        if label:IsA("TextLabel") then
            label:GetPropertyChangedSignal("Text"):Connect(function()
                local waveNum = tonumber(label.Text:match("^(%d+)"))
                if waveNum and waveNum == AtWave then
                    sellAllTowers()
                end
            end)
        end
    end
end

-- ⏩ Tự động skip wave
local function skipwave()
    task.spawn(function()
        while true do
            pcall(function()
                remoteFunction:InvokeServer("Voting", "Skip")
            end)
            task.wait(1)
        end
    end)
end

if autoskip == true then
    skipwave()
end

-- 🔁 Reset khi game over
gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        task.wait(5)
        if typeof(setupfarm) == "function" then
            setupfarm()
        end
    end
end)
