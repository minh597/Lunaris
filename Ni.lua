local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local workspaceTowers = workspace:WaitForChild("Towers")

-- 💰 CASH LABEL
local cashLabel = playerGui
    :WaitForChild("ReactUniversalHotbar")
    :WaitForChild("Frame")
    :WaitForChild("values")
    :WaitForChild("cash")
    :WaitForChild("amount")

-- 🌊 WAVE DISPLAY
local waveContainer = playerGui
    :WaitForChild("ReactGameTopGameDisplay")
    :WaitForChild("Frame")
    :WaitForChild("wave")
    :WaitForChild("container")

-- ☠️ GAME OVER GUI
local gameOverGui = playerGui
    :WaitForChild("ReactGameNewRewards")
    :WaitForChild("Frame")
    :WaitForChild("gameOver")

-- 💵 LẤY TIỀN
local function getCash()
    local text = cashLabel.Text or ""
    local num = text:gsub("[^%d%-]", "")
    return tonumber(num) or 0
end

local function waitForCash(min)
    while getCash() < min do
        task.wait(1)
    end
end

-- 📡 GỬI LỆNH AN TOÀN
local function safeInvoke(args, cost)
    waitForCash(cost)
    pcall(function()
        remoteFunction:InvokeServer(unpack(args))
    end)
    task.wait(0.5)
end

-- 🏗️ ĐẶT & NÂNG & BÁN TOWER
function placeTower(position, name, cost)
    local args = {"Troops", "Place", {Rotation = CFrame.new(), Position = position}, name}
    safeInvoke(args, cost)
end

function upgradeTower(index, cost)
    local tower = workspaceTowers:GetChildren()[index]
    if tower then
        local args = {"Troops", "Upgrade", "Set", {Troop = tower}}
        safeInvoke(args, cost)
    end
end

function sellAllTowers()
    for _, tower in ipairs(workspaceTowers:GetChildren()) do
        local args = {"Troops", "Sell", {Troop = tower}}
        pcall(function()
            remoteFunction:InvokeServer(unpack(args))
        end)
        task.wait(0.2)
    end
end

-- 💥 BÁN TOWER KHI ĐẾN WAVE CẦN
if getgenv().LunarisX.SellAllTower == true then
    for _, label in ipairs(waveContainer:GetDescendants()) do
        if label:IsA("TextLabel") then
            label:GetPropertyChangedSignal("Text"):Connect(function()
                local wave = tonumber(label.Text:match("^(%d+)"))
                if wave and wave == getgenv().LunarisX.AtWave then
                    sellAllTowers()
                end
            end)
        end
    end
end

-- ⏩ AUTO SKIP
local autoskip = getgenv().LunarisX.autoskip == true

local function skipVote()
    while autoskip do
        pcall(function()
            remoteFunction:InvokeServer("Voting", "Skip")
        end)
        task.wait(1)
    end
end

-- 🕐 SKIP 5 GIÂY SAU KHI FARM
local function voteDelay()
    autoskip = true
    task.spawn(skipVote)
    task.wait(5)
    autoskip = false
end

-- ☠️ GAME OVER => RESET FARM
gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        task.wait(5)
        getgenv().LunarisX.setupfarm()
        voteDelay()
    end
end)

-- 🚀 BẮT ĐẦU FARM LẦN ĐẦU
getgenv().LunarisX.setupfarm()
voteDelay()
