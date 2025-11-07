--// Auto Teleport to TDX when GameOver appears

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local TDX_GAME_ID = 9503261072 -- ID game Tower Defense X Lobby

-- Hàm kiểm tra GUI
task.spawn(function()
	while true do
		task.wait(1) -- kiểm tra mỗi 1 giây
		local gameOverGui = StarterGui:FindFirstChild("Interface")
			and StarterGui.Interface:FindFirstChild("GameOverScreen")
			and StarterGui.Interface.GameOverScreen:FindFirstChild("Main")

		if gameOverGui and gameOverGui.Visible == true then
			print("[AutoTP] Game Over detected, teleporting to TDX lobby...")
			TeleportService:Teleport(TDX_GAME_ID, player)
			break
		end
	end
end)
