-- GameState: the single place the server keeps player state.
-- Every other server module reads and writes through here, so there
-- is one source of truth for cash, owned brainrots, rebirths, locks
-- and base plots. Nothing else on the server keeps its own copy.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local GameState = {}

-- player -> { Cash, Rebirths, Owned = { [slot] = brainrot }, BasePlot, LockedUntil, LockReadyAt, LastStealAt }
GameState.Players = {}

-- Next free base plot index, handed out in join order.
local nextPlot = 1

-- A brainrot record: id, display name, rarity, mutation, rate per
-- second, price paid, and the slot it sits in on its owner's base.
function GameState.newBrainrotRecord(entry, mutationName: string, slot: number)
	return {
		id = entry.id,
		name = entry.name,
		rarity = entry.rarity,
		mutation = mutationName,
		rate = BrainrotData.rateOf(entry, mutationName),
		price = entry.price,
		slot = slot,
	}
end

-- Build a fresh state row for a joining player and give them a plot.
function GameState.createPlayer(player: Player)
	local plotIndex = nextPlot
	nextPlot = math.min(nextPlot + 1, #Config.BasePlots)
	local state = {
		Cash = Config.StartCash,
		Rebirths = 0,
		Owned = {},
		BasePlot = plotIndex,
		LockedUntil = 0,
		LockReadyAt = 0,
		LastStealAt = 0,
	}
	GameState.Players[player] = state
	return state
end

-- Forget a leaving player's state so their plot frees up.
function GameState.removePlayer(player: Player)
	GameState.Players[player] = nil
end

function GameState.get(player: Player)
	return GameState.Players[player]
end

-- Total money per second across everything the player owns,
-- rebirth bonus included. This is the number the HUD shows ticking.
function GameState.incomePerSecond(player: Player): number
	local state = GameState.Players[player]
	if not state then
		return 0
	end
	local total = 0
	for _, owned in pairs(state.Owned) do
		total += owned.rate
	end
	return math.floor(total * Config.rebirthMultiplier(state.Rebirths))
end

-- First empty slot on the player's base (slots fill 1, 2, 3...).
function GameState.nextFreeSlot(player: Player): number
	local state = GameState.Players[player]
	if not state then
		return 1
	end
	local slot = 1
	while state.Owned[slot] ~= nil do
		slot += 1
	end
	return slot
end

-- Add a brainrot to the player's base; returns its record and slot.
function GameState.addOwned(player: Player, entry, mutationName: string)
	local state = GameState.Players[player]
	if not state then
		return nil
	end
	local slot = GameState.nextFreeSlot(player)
	local record = GameState.newBrainrotRecord(entry, mutationName, slot)
	state.Owned[slot] = record
	return record
end

-- Take a brainrot off a base by slot; returns the record or nil.
function GameState.removeOwned(player: Player, slot: number)
	local state = GameState.Players[player]
	if not state then
		return nil
	end
	local record = state.Owned[slot]
	state.Owned[slot] = nil
	return record
end

-- Is this player's base locked right now?
function GameState.isLocked(player: Player): boolean
	local state = GameState.Players[player]
	if not state then
		return false
	end
	return os.time() < state.LockedUntil
end

-- Lock the base for Config.LockDuration; returns false while the
-- lock is still cooling down from its last use.
function GameState.lockBase(player: Player): boolean
	local state = GameState.Players[player]
	if not state then
		return false
	end
	local now = os.time()
	if now < state.LockReadyAt then
		return false
	end
	state.LockedUntil = now + Config.LockDuration
	state.LockReadyAt = now + Config.LockCooldown
	return true
end

-- Can this player attempt a steal right now (cooldown respected)?
function GameState.canSteal(player: Player): boolean
	local state = GameState.Players[player]
	if not state then
		return false
	end
	return os.time() - state.LastStealAt >= Config.StealCooldown
end

function GameState.markStealAttempt(player: Player)
	local state = GameState.Players[player]
	if state then
		state.LastStealAt = os.time()
	end
end

-- Rebirth: wipe cash and owned brainrots, keep the plot, grant one
-- more permanent income bonus. Returns false if the player cannot
-- afford this rebirth yet.
function GameState.rebirth(player: Player): boolean
	local state = GameState.Players[player]
	if not state then
		return false
	end
	local cost = Config.rebirthCost(state.Rebirths + 1)
	if state.Cash < cost then
		return false
	end
	state.Cash = 0
	state.Owned = {}
	state.Rebirths += 1
	return true
end

-- Push a fresh snapshot to one player's client: cash, income, owned
-- list, rebirth count, lock state. The HUD rebuilds from this alone.
function GameState.pushUpdate(player: Player)
	local state = GameState.Players[player]
	if not state then
		return
	end
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local event = remotes:WaitForChild("StateUpdate")
	local ownedList = {}
	for slot, record in pairs(state.Owned) do
		table.insert(ownedList, {
			slot = slot,
			id = record.id,
			name = record.name,
			rarity = record.rarity,
			mutation = record.mutation,
			rate = record.rate,
		})
	end
	table.sort(ownedList, function(a, b)
		return a.slot < b.slot
	end)
	event:FireClient(player, {
		cash = state.Cash,
		incomePerSecond = GameState.incomePerSecond(player),
		rebirths = state.Rebirths,
		basePlot = state.BasePlot,
		nextRebirthCost = Config.rebirthCost(state.Rebirths + 1),
		multiplier = Config.rebirthMultiplier(state.Rebirths),
		locked = GameState.isLocked(player),
		lockReadyIn = math.max(0, state.LockReadyAt - os.time()),
		owned = ownedList,
	})
end

-- Push a snapshot to every player in the server.
function GameState.pushAll()
	for player, _ in pairs(GameState.Players) do
		GameState.pushUpdate(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	GameState.createPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	GameState.removePlayer(player)
end)

return GameState
