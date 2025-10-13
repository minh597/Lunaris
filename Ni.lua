local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")

local player = game.Players.LocalPlayer
local towerFolder = workspace:WaitForChild("Towers")

-- 🪙 CASH LABEL
local cashLabel = player
    :WaitForChild("PlayerGui")
    :WaitForChild("ReactUniversalHotbar")
    :WaitForChild("Frame")
    :WaitForChild("values")
    :WaitForChild("cash")
    :WaitForChild("amount")

-- 🌊 WAVE CONTAINER
local waveContainer = player
    :WaitForChild("PlayerGui")
    :WaitForChild("ReactGameTopGameDisplay")
    :WaitForChild("Frame")
    :WaitForChild("wave")
    :WaitForChild("container")

-- 💀 GAME OVER GUI
local gameOverGui = player
    :WaitForChild("PlayerGui")
    :WaitForChild("ReactGameNewRewards")
    :WaitForChild("Frame")
    :WaitForChild("gameOver")

-- 💵 LẤY SỐ TIỀN
local function getCash()
    local rawText = cashLabel.Text or ""
    local cleaned = rawText:gsub("[^%d%-]", "")
    return tonumber(cleaned) or 0
end

-- ⏳ CHỜ ĐỦ TIỀN
local function waitForCash(minAmount)
    while getCash() < minAmount do
        task.wait(1)
    end
end

-- 🛠️ GỌI HÀM SERVER AN TOÀN
local function safeInvoke(args, cost)
    waitForCash(cost)
    pcall(function()
        remoteFunction:InvokeServer(unpack(args))
    end)
    task.wait(1)
end

-- 🏗️ ĐẶT TOWER
function placeTower(position, name, cost)
    local args = {
        "Troops",
        "Pl\208\176ce",
        { Rotation = CFrame.new(), Position = position },
        name
    }
    safeInvoke(args, cost)
end

-- ⚙️ NÂNG CẤP TOWER
function upgradeTower(num, cost)
    local tower = towerFolder:GetChildren()[num]
    if tower then
        local args = { "Troops", "Upgrade", "Set", { Troop = tower } }
        safeInvoke(args, cost)
    end
end

-- 💸 BÁN TẤT CẢ TOWER
local function sellAllTowers()
    for _, tower in ipairs(towerFolder:GetChildren()) do
        local args = { "Troops", "Se\108\108", { Troop = tower } }
        pcall(function()
            remoteFunction:InvokeServer(unpack(args))
        end)
        task.wait(0.2)
    end
end

-- 🌊 THEO DÕI WAVE
for _, label in ipairs(waveContainer:GetDescendants()) do
    if label:IsA("TextLabel") then
        label:GetPropertyChangedSignal("Text"):Connect(function()
            local waveNum = tonumber(label.Text:match("^(%d+)"))
            if waveNum and waveNum == 24 then
                sellAllTowers()
            end
        end)
    end
end

-- Biến toàn cục cho autoskip
local autoskip = false

-- Hàm skip voting
local function skipVoting()
    task.spawn(function()
        while autoskip do
            pcall(function()
                ReplicatedStorage:WaitForChild("RemoteFunction"):InvokeServer("Voting", "Skip")
            end)
            task.wait(1)
        end
    end)
end
gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        task.wait(3)
        -- chờ 5 giây trước khi restart
        setupfarm()  -- gọi lại farm
    end
end)
function voteskip()
 autoskip = true
 skipVoting()
 task.spawn(function()
    task.wait(5)
    autoskip = false
 end)
end
