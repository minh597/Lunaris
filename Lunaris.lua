local LunarisX = getgenv().LunarisX or {}
local farm = LunarisX.farm
local strategy = LunarisX.strategy

if farm == "gems" and strategy == "040811crossroads" then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/minh597/TDS-strategy/refs/heads/main/040811.lua"))()
end

if farm == "gum" and strategy == "batmangumfarm" then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/minh597/TDS-strategy/refs/heads/main/batmanpizza.lua"))()
end
