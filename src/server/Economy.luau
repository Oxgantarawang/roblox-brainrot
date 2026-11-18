-- Economy: cash in, cash out. The income ticker pays every owned
-- brainrot once a second, and the buy/sell/rebirth handlers are the
-- only ways cash leaves a player. All of it runs on the server; the
-- client only asks, and the server checks the price every time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local BasePlacer = require(script.Parent:WaitForChild("BasePlacer"))

local Economy = {}

-- Pay every player their income once. The ticker below calls this
-- every Config.IncomeTickSeconds seconds.
function Economy.payIncomeTick()
	for player, _ in pairs(GameState.Players) do
		local state = GameState.get(player)
		if state then
			state.Cash += GameState.incomePerSecond(player)
			GameState.pushUpdate(player)
		end
	end
end

-- Start the income ticker. Call once, from init.
function Economy.startIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(Config.IncomeTickSeconds)
			Economy.payIncomeTick()
		end
	end)
end

-- Buy the brainrot walking the conveyor whose model the player
-- prompted. Checks cash, charges the price, puts the brainrot on
-- the player's base, and tells the spawner to take the walker away.
-- Returns true and the record on success, false and a reason if not.
function Economy.buyWalkingBrainrot(player: Player, walkerId: string, spawner)
	local state = GameState.get(player)
	if not state then
		return false, "no state"
	end
	local walker = spawner.getWalker(walkerId)
	if not walker then
		return false, "that brainrot already left the conveyor"
	end
	local entry = BrainrotData.findById(walker.entryId)
	if not entry then
		return false, "unknown brainrot"
	end
	if state.Cash < entry.price then
		return false, "not enough cash"
	end
	state.Cash -= entry.price
	local record = GameState.addOwned(player, entry, walker.mutation)
	BasePlacer.place(player, record)
	spawner.removeWalker(walkerId)
	GameState.pushUpdate(player)
	return true, record
end

-- Sell a brainrot off the player's base for its sell-back price.
function Economy.sellOwnedBrainrot(player: Player, slot: number)
	local state = GameState.get(player)
	if not state then
		return false, "no state"
	end
	local record = state.Owned[slot]
	if not record then
		return false, "nothing in that slot"
	end
	local entry = BrainrotData.findById(record.id)
	if not entry then
		return false, "unknown brainrot"
	end
	local refund = BrainrotData.sellPriceOf(entry, record.mutation)
	GameState.removeOwned(player, slot)
	BasePlacer.remove(player, slot)
	state.Cash += refund
	GameState.pushUpdate(player)
	return true, refund
end

-- Rebirth through GameState, then push the fresh (empty, richer)
-- snapshot to the client.
function Economy.rebirth(player: Player)
	local ok = GameState.rebirth(player)
	if ok then
		BasePlacer.clear(player)
		GameState.pushUpdate(player)
	end
	return ok
end

-- Wire the RemoteEvents the client fires for buying, selling and
-- rebirthing. Every handler re-checks on the server; the client
-- never moves cash itself.
function Economy.bindRemotes(spawner)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")

	remotes:WaitForChild("BuyBrainrot").OnServerEvent:Connect(function(player, walkerId)
		local ok, result = Economy.buyWalkingBrainrot(player, walkerId, spawner)
		local feedback = remotes:WaitForChild("Feedback")
		if ok then
			feedback:FireClient(player, "Bought " .. result.name .. " for $" .. tostring(result.price) .. "! It now earns $" .. tostring(result.rate) .. "/s on your base.")
		else
			feedback:FireClient(player, "Could not buy: " .. tostring(result))
		end
	end)

	remotes:WaitForChild("SellBrainrot").OnServerEvent:Connect(function(player, slot)
		local ok, result = Economy.sellOwnedBrainrot(player, slot)
		local feedback = remotes:WaitForChild("Feedback")
		if ok then
			feedback:FireClient(player, "Sold for $" .. tostring(result) .. ".")
		else
			feedback:FireClient(player, "Could not sell: " .. tostring(result))
		end
	end)

	remotes:WaitForChild("Rebirth").OnServerEvent:Connect(function(player)
		local state = GameState.get(player)
		local cost = Config.rebirthCost((state and state.Rebirths or 0) + 1)
		local feedback = remotes:WaitForChild("Feedback")
		if Economy.rebirth(player) then
			feedback:FireClient(player, "REBIRTH! Your income is now permanently x" .. string.format("%.2f", Config.rebirthMultiplier(state.Rebirths)) .. ". Climb again!")
		else
			feedback:FireClient(player, "Rebirth costs $" .. tostring(cost) .. ". Keep earning!")
		end
	end)
end

return Economy
