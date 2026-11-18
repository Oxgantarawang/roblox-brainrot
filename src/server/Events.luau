-- Events: the tsunami. Every few minutes a warning banner goes up,
-- then a giant wave sweeps the map from north to south. Any player
-- caught out in the open is flung back to spawn and loses a slice
-- of their cash; a player standing safe on their own base plot is
-- untouched. The dash home is the point: the wave is the hazard
-- that makes a full pocket worth protecting.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))

local Events = {}

local wavePart: BasePart? = nil

-- Find the wave wall the place file builds (named TsunamiWave in
-- Workspace), or build a fallback one if the place has none.
function Events.getWavePart(): BasePart
	if wavePart then
		return wavePart
	end
	local found = Workspace:FindFirstChild("TsunamiWave")
	if found and found:IsA("BasePart") then
		wavePart = found
		return found
	end
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWave"
	wall.Size = Vector3.new(220, 30, 4)
	wall.Color = Color3.fromRGB(40, 140, 255)
	wall.Material = Enum.Material.Neon
	wall.Transparency = 0.3
	wall.Anchored = true
	wall.CanCollide = false
	wall.Parent = Workspace
	wavePart = wall
	return wall
end

-- Is this player standing on their own base plot right now?
-- Bases are the safe ground; the open conveyor is not.
function Events.isPlayerOnOwnBase(player: Player): boolean
	local state = GameState.get(player)
	if not state then
		return false
	end
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local plot = Config.BasePlots[state.BasePlot]
	if not plot then
		return false
	end
	local offset = root.Position - plot.position
	return math.abs(offset.X) < 11 and math.abs(offset.Z) < 11
end

-- The wave catches a player: fling them to spawn and take a cut
-- of their cash. Their brainrots stay safe on their base.
function Events.catchPlayer(player: Player)
	local state = GameState.get(player)
	if not state then
		return
	end
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(Config.SpawnPoint)
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:TakeDamage(0)
		end
	end
	local loss = math.floor(state.Cash * Config.TsunamiCashLoss)
	state.Cash -= loss
	GameState.pushUpdate(player)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("Feedback"):FireClient(player, "The TSUNAMI caught you out in the open! -$" .. tostring(loss) .. ". Get home before the next wave!")
end

-- Run one tsunami: warn, wait, sweep the wave south, catch anyone
-- still out in the open, then park the wave out of sight.
function Events.runTsunami()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local warning = remotes:WaitForChild("TsunamiWarning")

	warning:FireAllClients("TSUNAMI INCOMING! Run to your base!")
	task.wait(Config.TsunamiWarningSeconds)

	local wave = Events.getWavePart()
	wave.CFrame = CFrame.new(0, 15, -120)
	wave.Transparency = 0.15

	local caught = {}
	local position = -120
	while position < 140 do
		task.wait(0.1)
		position += Config.TsunamiWaveSpeed * 0.1
		wave.CFrame = CFrame.new(0, 15, position)
		for player, _ in pairs(GameState.Players) do
			if not caught[player] and not Events.isPlayerOnOwnBase(player) then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.Z - position) < 8 then
					caught[player] = true
					Events.catchPlayer(player)
				end
			end
		end
	end

	warning:FireAllClients("")
	wave.Transparency = 1
	wave.CFrame = CFrame.new(0, -50, 0)
end

-- Start the tsunami loop: a wave every Config.TsunamiEverySeconds.
-- Call once, from init.
function Events.startTsunamiLoop()
	task.spawn(function()
		while true do
			task.wait(Config.TsunamiEverySeconds)
			Events.runTsunami()
		end
	end)
end

return Events
