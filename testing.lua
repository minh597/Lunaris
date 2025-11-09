local LunarisX = getgenv().LunarisX or {}  
local rawFileURL = LunarisX.MacroUrl  
local map = LunarisX.Map  
local difficulty = LunarisX.Difficulty  

local Players = game:GetService("Players")  
local Workspace = game:GetService("Workspace")  
local ReplicatedStorage = game:GetService("ReplicatedStorage")  
local TeleportService = game:GetService("TeleportService")  
local player = Players.LocalPlayer  

-- Hàm an toàn load Tele.lua
local function loadTele()
    local url = "https://raw.githubusercontent.com/minh597/Lunaris/refs/heads/main/Tele.lua"
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and result and result ~= "" then
        local func, err = loadstring(result)
        if func then
            pcall(func)
        else
            warn("Failed to load Tele.lua:", err)
        end
    else
        warn("Failed to HttpGet Tele.lua")
    end
end

-- Hàm vote difficulty và setup lobby
local function setupLobby()
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    
    Remotes.DifficultyVoteCast:FireServer(difficulty)
    task.wait(0.5)
    Remotes.DifficultyVoteReady:FireServer()
    task.wait(0.5)
    Remotes.SoloToggleSpeedControl:FireServer(true, true)
end

-- Hàm check APC và load Tele.lua
local function checkAndJoin()
    if Workspace:FindFirstChild("APCs") then
        loadTele()
    else
        setupLobby()

        -- Load raw file nếu có
        if rawFileURL then
            local success, result = pcall(function()
                return game:HttpGet(rawFileURL)
            end)
            
            if success and result and result ~= "" then
                for line in result:gmatch("[^\r\n]+") do
                    line = line:match("^%s*(.-)%s*$")
                    if line ~= "" and not line:match("^%-%-") then
                        pcall(function()
                            local func = loadstring(line)
                            if func then func() end
                        end)
                    end
                end
            else
                warn("Failed to load raw macro file")
            end
        end

        -- Game over teleport back to lobby
        task.spawn(function()
            local gui = player:WaitForChild("PlayerGui"):WaitForChild("Interface"):WaitForChild("GameOverScreen")
            gui:GetPropertyChangedSignal("Visible"):Connect(function()
                if gui.Visible then
                    TeleportService:Teleport(9503261072, player)
                end
            end)
        end)
    end
end

-- Bắt đầu
checkAndJoin()
