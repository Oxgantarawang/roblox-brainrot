-- Stealing: take a brainrot off another player's base. The genre's
-- tension lives here: bases can be locked, and a steal is a real
-- transfer, not a copy. The victim keeps a consolation cut of the
-- price so a steal stings instead of ruining a new player, and the
-- thief waits out a cooldown before trying again.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local BasePlacer = require(script.Parent:WaitForChild("BasePlacer"))

local Stealing = {}

-- Try to steal the brainrot in slot `slot` on victim's base.
-- Returns true and the record on success, false and a reason if not.
function Stealing.attemptSteal(thief: Player, victim: Player, slot: number)
	local thiefState = GameState.get(thief)
	local victimState = GameState.get(victim)
	if not thiefState or not victimState then
		return false, "player not found"
	end
	if thief == victim then
		return false, "that is your own base"
	end
	if not GameState.canSteal(thief) then
		return false, "steal is cooling down, wait a moment"
	end
	if GameState.isLocked(victim) then
		return false, victim.Name .. "'s base is LOCKED"
	end
	local record = victimState.Owned[slot]
	if not record then
		return false, "nothing in that slot"
	end
	GameState.markStealAttempt(thief)

	-- Move the brainrot: off the victim's base, onto the thief's,
	-- keeping its mutation and rate, model included.
	GameState.removeOwned(victim, slot)
	BasePlacer.remove(victim, slot)
	local entry = BrainrotData.findById(record.id)
	local moved = GameState.addOwned(thief, entry, record.mutation)
	BasePlacer.place(thief, moved)
	if not moved then
		-- Should not happen; give it back rather than lose it.
		victimState.Owned[slot] = record
		return false, "your base is full"
	end

	-- Consolation for the victim: a quarter of the price back.
	local entryPrice = entry and entry.price or 0
	victimState.Cash += math.floor(entryPrice * Config.StealConsolation)

	GameState.pushUpdate(thief)
	GameState.pushUpdate(victim)
	return true, moved
end

-- Lock the caller's own base. Returns false while the lock is on
-- cooldown; the HUD shows the remaining cooldown.
function Stealing.lockOwnBase(player: Player): boolean
	return GameState.lockBase(player)
end

-- Wire the RemoteEvents: StealBrainrot (thief asks, server checks)
-- and LockBase (owner asks for a lock). Feedback goes back through
-- the shared Feedback event so the HUD can show it.
function Stealing.bindRemotes()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local feedback = remotes:WaitForChild("Feedback")

	remotes:WaitForChild("StealBrainrot").OnServerEvent:Connect(function(thief, victim, slot)
		if typeof(victim) ~= "Instance" or not victim:IsA("Player") then
			feedback:FireClient(thief, "Pick a player to steal from first.")
			return
		end
		local ok, result = Stealing.attemptSteal(thief, victim, slot)
		if ok then
			feedback:FireClient(thief, "STOLE " .. result.name .. " from " .. victim.Name .. "! It now earns for you.")
			feedback:FireClient(victim, thief.Name .. " stole your " .. result.name .. "! Lock your base next time.")
		else
			feedback:FireClient(thief, "Steal failed: " .. tostring(result))
		end
	end)

	remotes:WaitForChild("LockBase").OnServerEvent:Connect(function(player)
		if Stealing.lockOwnBase(player) then
			feedback:FireClient(player, "Base LOCKED for " .. tostring(Config.LockDuration) .. " seconds. Nobody can steal from you now.")
			GameState.pushUpdate(player)
		else
			feedback:FireClient(player, "Lock is still cooling down. Watch the timer on your HUD.")
		end
	end)
end

return Stealing
