-- Spawner: the conveyor. Every few seconds a new brainrot rolls
-- in at the north end, walks south past the players, and despawns
-- at the far end if nobody buys it. The walker is a small 3D model
-- the spawner builds from parts, with a floating label showing its
-- name, rarity, money per second and price, and a ProximityPrompt
-- the buyer uses. Buying goes through Economy, never through the
-- prompt alone.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local Spawner = {}

-- walkerId -> { entryId, mutation, model, prompt, connection }
Spawner.Walkers = {}
local walkerCount = 0

-- Build the little 3D creature: a coloured body, a head, two eyes,
-- and a label floating above it with everything a buyer must read.
function Spawner.buildBrainrotModel(entry, mutation, mutationColor: Color3)
	local model = Instance.new("Model")
	model.Name = entry.name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(entry.size, entry.size, entry.size)
	body.Color = entry.bodyColor
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(entry.size * 0.7, entry.size * 0.7, entry.size * 0.7)
	head.Color = mutationColor
	head.Material = Enum.Material.Neon
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model
	model.PrimaryPart = body

	-- The floating label: name, rarity, rate and price, big enough
	-- to read from across the conveyor.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BrainrotLabel"
	billboard.Size = UDim2.new(0, 220, 0, 90)
	billboard.StudsOffset = Vector3.new(0, entry.size + 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.35, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Position = UDim2.new(0, 0, 0.35, 0)
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = BrainrotData.findRarity(entry.rarity).name .. "  |  " .. mutation .. "  |  $" .. tostring(BrainrotData.rateOf(entry, mutation)) .. "/s"
	rarityLabel.TextColor3 = BrainrotData.findRarity(entry.rarity).color
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = billboard

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLabel"
	priceLabel.Position = UDim2.new(0, 0, 0.65, 0)
	priceLabel.Size = UDim2.new(1, 0, 0.35, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "BUY: $" .. tostring(entry.price)
	priceLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBlack
	priceLabel.Parent = billboard

	return model
end

-- Set by init.server: the function that runs when a player uses a
-- walker's buy prompt (player, walkerId). Kept as a callback so the
-- spawner never decides a purchase itself; Economy does that.
Spawner.OnBuyPrompt = nil

-- Spawn one brainrot and start it walking. Returns its walker id.
function Spawner.spawnOne(): string
	local rarity = BrainrotData.rollRarity()
	local entry = BrainrotData.pickOfRarity(rarity)
	local mutation = BrainrotData.rollMutation()
	walkerCount += 1
	local walkerId = "walker_" .. tostring(walkerCount)

	local model = Spawner.buildBrainrotModel(entry, mutation.name, mutation.color)
	model:PivotTo(CFrame.new(Config.ConveyorStart))
	model.Parent = Workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy " .. entry.name .. " ($" .. tostring(entry.price) .. ")"
	prompt.ObjectText = entry.rarity .. " | $" .. tostring(BrainrotData.rateOf(entry, mutation.name)) .. "/s"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	local walker = {
		entryId = entry.id,
		mutation = mutation.name,
		model = model,
		prompt = prompt,
	}
	Spawner.Walkers[walkerId] = walker

	-- The prompt only asks; Economy decides whether the buy goes
	-- through (cash, still on the conveyor) and answers the player.
	prompt.Triggered:Connect(function(player)
		if Spawner.OnBuyPrompt then
			Spawner.OnBuyPrompt(player, walkerId)
		end
	end)

	-- Walk south along the conveyor, bobbing as it goes, until the
	-- end of the line. The task dies with the walker when it is
	-- bought or despawns.
	task.spawn(function()
		local position = Config.ConveyorStart
		local elapsed = 0
		while Spawner.Walkers[walkerId] ~= nil do
			task.wait(0.1)
			elapsed += 0.1
			position += Vector3.new(0, 0, Config.WalkSpeed * 0.1)
			local bob = math.sin(elapsed * 4) * 0.35
			local spin = CFrame.Angles(0, elapsed * 1.5, 0)
			model:PivotTo(CFrame.new(position + Vector3.new(0, entry.size / 2 + bob, 0)) * spin)
			if position.Z >= Config.ConveyorEnd.Z then
				Spawner.removeWalker(walkerId)
			end
		end
	end)

	return walkerId
end

function Spawner.getWalker(walkerId: string)
	return Spawner.Walkers[walkerId]
end

-- Remove a walker from the conveyor and destroy its model. Called
-- when it is bought and when it walks off the end unbought.
function Spawner.removeWalker(walkerId: string)
	local walker = Spawner.Walkers[walkerId]
	if not walker then
		return
	end
	Spawner.Walkers[walkerId] = nil
	if walker.model then
		walker.model:Destroy()
	end
end

-- How many brainrots are walking right now.
function Spawner.walkingCount(): number
	local count = 0
	for _, _ in pairs(Spawner.Walkers) do
		count += 1
	end
	return count
end

-- Start the spawn loop: a new brainrot every few seconds, as long
-- as the conveyor is not already full. Call once, from init.
function Spawner.startSpawnLoop()
	task.spawn(function()
		while true do
			task.wait(Config.SpawnInterval)
			if Spawner.walkingCount() < Config.MaxWalking then
				Spawner.spawnOne()
			end
		end
	end)
end

return Spawner
