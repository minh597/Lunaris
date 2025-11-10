local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")

local cashLabel = player
    :WaitForChild("PlayerGui")
    :WaitForChild("ReactUniversalHotbar")
    :WaitForChild("Frame")
    :WaitForChild("values")
    :WaitForChild("cash")
    :WaitForChild("amount")

local function getCash()
    local rawText = cashLabel.Text or ""
    local cleaned = rawText:gsub("[^%d%-]", "")
    return tonumber(cleaned) or 0
end

local actionLog = {}

-- GUI gọn chỉ chứa nút copy
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local CopyButton = Instance.new("TextButton")
CopyButton.Size = UDim2.new(0, 120, 0, 35)
CopyButton.Position = UDim2.new(1, -130, 1, -80)
CopyButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
CopyButton.TextColor3 = Color3.new(1, 1, 1)
CopyButton.Font = Enum.Font.SourceSans
CopyButton.TextSize = 16
CopyButton.Text = "Copy Lua"
CopyButton.Parent = ScreenGui

local function formatLuaLog()
    local lines = {}
    for _, v in ipairs(actionLog) do
        if v.type == "place" then
            table.insert(lines, string.format(
                'place(%.3f, %.3f, %.3f, "%s", %d)',
                v.pos[1], v.pos[2], v.pos[3], v.name, v.cash
            ))
        elseif v.type == "upgrade" then
            table.insert(lines, string.format(
                'upgrade(%.3f, %.3f, %.3f, %d)',
                v.pos[1], v.pos[2], v.pos[3], v.cash
            ))
        end
    end
    return table.concat(lines, "\n")
end

CopyButton.MouseButton1Click:Connect(function()
    local luaText = formatLuaLog()
    if setclipboard then
        setclipboard(luaText)
        CopyButton.Text = "Copied"
        task.wait(1)
        CopyButton.Text = "Copy Lua"
    end
end)

-- Hook
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if self == remoteFunction and (method == "FireServer" or method == "InvokeServer") then
        -- PLACE
        if type(args[3]) == "table" and args[3].Position and args[4] then
            local pos = args[3].Position
            table.insert(actionLog, {
                type = "place",
                pos = {pos.X, pos.Y, pos.Z},
                name = tostring(args[4]),
                cash = getCash()
            })
        end

        -- UPGRADE
        if args[1] == "Troops" and args[2] == "Upgrade" and typeof(args[4]) == "table" then
            local tower = args[4].Troop
            local result = old(self, ...)

            if tower and tower.Parent then
                local root = tower:FindFirstChild("HumanoidRootPart") or tower:FindFirstChildWhichIsA("BasePart")
                if root then
                    table.insert(actionLog, {
                        type = "upgrade",
                        pos = {root.Position.X, root.Position.Y, root.Position.Z},
                        cash = getCash()
                    })
                end
            end

            print(formatLuaLog()) -- in ra định dạng Lua
            return result
        end
    end

    return old(self, ...)
end)