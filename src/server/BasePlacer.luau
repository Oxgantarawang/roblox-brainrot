-- BasePlacer: the 3D side of owning a brainrot. When Economy says
-- a player bought one, this module builds its little model (the
-- same builder the conveyor uses) and parks it on the player's base
-- plot, one slot per brainrot, in a neat row. When one is sold,
-- stolen or wiped by a rebirth, the model goes with it. The model
-- carries two tags the stealing click reads: BaseSlot (which slot
-- it sits in) and BaseOwner (whose base it is on).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Spawner = require(script.Parent:WaitForChild("Spawner"))

local BasePlacer = {}

-- player -> slot -> Model, so removal finds its model at once.
local placed = {}

-- Where slot n sits on a plot: two rows of four, facing the
-- conveyor, so a full base reads as a little collection shelf.
local function slotOffset(slot: number): Vector3
	local column = (slot - 1) % 4
	local row = math.floor((slot - 1) / 4)
	return Vector3.new(-6 + column * 4, 0, -6 + row * 4)
end

-- Park a bought brainrot's model on its owner's base.
function BasePlacer.place(player: Player, record)
	local entry = BrainrotData.findById(record.id)
	if not entry then
		return
	end
	local mutationColor = Color3.fromRGB(255, 255, 255)
	for _, mutation in ipairs(BrainrotData.Mutations) do
		if mutation.name == record.mutation then
			mutationColor = mutation.color
		end
	end
	local model = Spawner.buildBrainrotModel(entry, record.mutation, mutationColor)

	local state = require(script.Parent:WaitForChild("GameState")).get(player)
	local plotIndex = state and state.BasePlot or 1
	local plot = Config.BasePlots[plotIndex]
	local spot = plot.position + slotOffset(record.slot)
	model:PivotTo(CFrame.new(spot + Vector3.new(0, entry.size / 2 + 0.5, 0)))
	model.Parent = Workspace

	local slotTag = Instance.new("IntValue")
	slotTag.Name = "BaseSlot"
	slotTag.Value = record.slot
	slotTag.Parent = model

	local ownerTag = Instance.new("StringValue")
	ownerTag.Name = "BaseOwner"
	ownerTag.Value = player.Name
	ownerTag.Parent = model

	placed[player] = placed[player] or {}
	placed[player][record.slot] = model
end

-- Take the model for one slot off a base and destroy it.
function BasePlacer.remove(player: Player, slot: number)
	local byPlayer = placed[player]
	if not byPlayer then
		return
	end
	local model = byPlayer[slot]
	if model then
		model:Destroy()
	end
	byPlayer[slot] = nil
end

-- Clear every model on a player's base (rebirth, or leaving).
function BasePlacer.clear(player: Player)
	local byPlayer = placed[player]
	if not byPlayer then
		return
	end
	for _, model in pairs(byPlayer) do
		if model then
			model:Destroy()
		end
	end
	placed[player] = nil
end

return BasePlacer
