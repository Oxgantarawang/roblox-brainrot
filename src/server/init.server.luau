-- init.server: Brainrot Breakout boots here. It wires the modules
-- together in one place: state first, then the economy, the
-- conveyor, stealing and the tsunami, each started once. Nothing
-- else in ServerScriptService runs game logic; every module above
-- this file has exactly one job.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = require(script:WaitForChild("GameState"))
local Economy = require(script:WaitForChild("Economy"))
local Spawner = require(script:WaitForChild("Spawner"))
local Stealing = require(script:WaitForChild("Stealing"))
local Events = require(script:WaitForChild("Events"))
local BasePlacer = require(script:WaitForChild("BasePlacer"))

-- A buy prompt on a walking brainrot asks Economy to run the
-- server-checked purchase, then tells the buyer what happened.
Spawner.OnBuyPrompt = function(player: Player, walkerId: string)
	local ok, result = Economy.buyWalkingBrainrot(player, walkerId, Spawner)
	local feedback = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Feedback")
	if ok then
		feedback:FireClient(player, "Bought " .. result.name .. " for $" .. tostring(result.price) .. "! It now earns $" .. tostring(result.rate) .. "/s on your base.")
	else
		feedback:FireClient(player, "Could not buy: " .. tostring(result))
	end
end

-- A joining player gets state, a base plot, a spawn point and a
-- first snapshot for their HUD. Players who joined before this
-- script ran (Studio play-solo) get the same treatment.
local function setupPlayer(player: Player)
	if not GameState.get(player) then
		GameState.createPlayer(player)
	end
	local state = GameState.get(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart")
	local plot = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")).BasePlots[state.BasePlot]
	root.CFrame = CFrame.new(plot.position + Vector3.new(0, 3, 0))
	GameState.pushUpdate(player)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

-- A leaving player's state is forgotten and their base models are
-- cleared, so a rejoin starts fresh on the next free plot.
Players.PlayerRemoving:Connect(function(player)
	BasePlacer.clear(player)
	GameState.removePlayer(player)
end)

-- Start the loops and bind the remotes. The economy's handlers
-- need the spawner, which init passes in.
Economy.startIncomeLoop()
Economy.bindRemotes(Spawner)
Stealing.bindRemotes()
Spawner.startSpawnLoop()
Events.startTsunamiLoop()

-- Seed the conveyor so the first players see brainrots at once
-- instead of waiting out the first spawn interval.
Spawner.spawnOne()
Spawner.spawnOne()

print("[Brainrot Breakout] server up: conveyor, economy, stealing and tsunami running.")
