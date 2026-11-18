-- BrainrotData: the whole cast of Brainrot Breakout.
-- Every character here is original to this game: absurd meme-born
-- creatures with their own names, prices and money-per-second rates.
-- One table drives the spawner, the shop, the HUD and the economy,
-- so a new brainrot is one row added here and nothing else changes.

local BrainrotData = {}

-- Rarity ladder, cheapest first. Each rung names its colour (used by
-- labels, the shop and the HUD), its spawn weight and its sell value.
BrainrotData.Rarities = {
	{ name = "Common", color = Color3.fromRGB(190, 190, 190), weight = 40, sellBack = 0.5 },
	{ name = "Rare", color = Color3.fromRGB(80, 170, 255), weight = 26, sellBack = 0.55 },
	{ name = "Epic", color = Color3.fromRGB(170, 90, 255), weight = 16, sellBack = 0.6 },
	{ name = "Legendary", color = Color3.fromRGB(255, 190, 40), weight = 10, sellBack = 0.65 },
	{ name = "Mythic", color = Color3.fromRGB(255, 70, 120), weight = 5, sellBack = 0.7 },
	{ name = "Brainrot God", color = Color3.fromRGB(80, 255, 200), weight = 3, sellBack = 0.75 },
}

-- Mutations roll when a brainrot spawns. A mutated brainrot earns its
-- rate times the multiplier and sells for more; the roll is rare on
-- purpose so a Gold or Diamond find feels like a win.
BrainrotData.Mutations = {
	{ name = "Normal", multiplier = 1, chance = 0.82, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Gold", multiplier = 2, chance = 0.11, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", multiplier = 5, chance = 0.05, color = Color3.fromRGB(120, 220, 255) },
	{ name = "Rainbow", multiplier = 10, chance = 0.02, color = Color3.fromRGB(255, 110, 220) },
}

-- The roster. price is what the conveyor charges, rate is the cash
-- the brainrot earns every second once it sits on a base, bodyColor
-- is the colour of the little 3D creature the spawner builds.
BrainrotData.Roster = {
	-- Common
	{ id = "noodle_goblin", name = "Noodle Goblin", rarity = "Common", price = 10, rate = 1, bodyColor = Color3.fromRGB(255, 220, 120), size = 2.2 },
	{ id = "toilet_trumpet", name = "Toilet Trumpet", rarity = "Common", price = 25, rate = 3, bodyColor = Color3.fromRGB(200, 230, 255), size = 2.4 },
	{ id = "sock_shark", name = "Sock Puppet Shark", rarity = "Common", price = 50, rate = 5, bodyColor = Color3.fromRGB(120, 160, 255), size = 2.6 },
	-- Rare
	{ id = "banana_knight", name = "Banana Knight", rarity = "Rare", price = 150, rate = 12, bodyColor = Color3.fromRGB(255, 235, 60), size = 2.8 },
	{ id = "cereal_wizard", name = "Cereal Box Wizard", rarity = "Rare", price = 300, rate = 25, bodyColor = Color3.fromRGB(255, 150, 80), size = 3.0 },
	{ id = "fridge_frog", name = "Fridge Magnet Frog", rarity = "Rare", price = 500, rate = 40, bodyColor = Color3.fromRGB(90, 220, 130), size = 3.0 },
	-- Epic
	{ id = "disco_pickle", name = "Disco Pickle", rarity = "Epic", price = 1200, rate = 90, bodyColor = Color3.fromRGB(60, 255, 160), size = 3.2 },
	{ id = "lawnmower_llama", name = "Lawnmower Llama", rarity = "Epic", price = 2500, rate = 180, bodyColor = Color3.fromRGB(200, 140, 255), size = 3.4 },
	{ id = "spaghetti_tornado", name = "Spaghetti Tornado", rarity = "Epic", price = 5000, rate = 350, bodyColor = Color3.fromRGB(255, 200, 90), size = 3.6 },
	-- Legendary
	{ id = "wifi_router_grandma", name = "Grandma's WiFi Router", rarity = "Legendary", price = 12000, rate = 800, bodyColor = Color3.fromRGB(255, 120, 120), size = 3.8 },
	{ id = "quantum_burrito", name = "Quantum Burrito", rarity = "Legendary", price = 25000, rate = 1600, bodyColor = Color3.fromRGB(140, 255, 220), size = 4.0 },
	{ id = "invisible_chair_king", name = "Invisible Chair King", rarity = "Legendary", price = 50000, rate = 3200, bodyColor = Color3.fromRGB(220, 220, 255), size = 4.0 },
	-- Mythic
	{ id = "moon_cheese_dragon", name = "Moon Cheese Dragon", rarity = "Mythic", price = 120000, rate = 7500, bodyColor = Color3.fromRGB(255, 240, 150), size = 4.4 },
	{ id = "time_toaster", name = "Time-Traveling Toaster", rarity = "Mythic", price = 250000, rate = 15000, bodyColor = Color3.fromRGB(180, 180, 180), size = 4.4 },
	{ id = "sir_reginald_pigeon", name = "Sir Reginald III, a Pigeon", rarity = "Mythic", price = 500000, rate = 30000, bodyColor = Color3.fromRGB(150, 150, 200), size = 4.6 },
	-- Brainrot God
	{ id = "almighty_spud", name = "The Almighty Spud", rarity = "Brainrot God", price = 1500000, rate = 90000, bodyColor = Color3.fromRGB(200, 160, 90), size = 5.0 },
	{ id = "ceo_of_nonsense", name = "CEO of Nonsense", rarity = "Brainrot God", price = 3000000, rate = 180000, bodyColor = Color3.fromRGB(40, 40, 60), size = 5.2 },
	{ id = "galactic_grandpa", name = "Galactic Grandpa", rarity = "Brainrot God", price = 7500000, rate = 450000, bodyColor = Color3.fromRGB(255, 255, 255), size = 5.5 },
}

-- Look a brainrot up by its id; the spawner and the shop both use this.
function BrainrotData.findById(id: string)
	for _, entry in ipairs(BrainrotData.Roster) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

-- Look a rarity rung up by name, for colours and sell-back rates.
function BrainrotData.findRarity(name: string)
	for _, rung in ipairs(BrainrotData.Rarities) do
		if rung.name == name then
			return rung
		end
	end
	return BrainrotData.Rarities[1]
end

-- Pick a rarity by weight, so Commons flood the conveyor and Gods
-- stay a rare sighting worth sprinting for.
function BrainrotData.rollRarity(): string
	local total = 0
	for _, rung in ipairs(BrainrotData.Rarities) do
		total += rung.weight
	end
	local roll = math.random(1, total)
	local running = 0
	for _, rung in ipairs(BrainrotData.Rarities) do
		running += rung.weight
		if roll <= running then
			return rung.name
		end
	end
	return "Common"
end

-- Pick a mutation by chance; most spawns stay Normal.
function BrainrotData.rollMutation()
	local roll = math.random()
	local running = 0
	for _, mutation in ipairs(BrainrotData.Mutations) do
		running += mutation.chance
		if roll <= running then
			return mutation
		end
	end
	return BrainrotData.Mutations[1]
end

-- Pick a random roster entry of the given rarity.
function BrainrotData.pickOfRarity(rarity: string)
	local pool = {}
	for _, entry in ipairs(BrainrotData.Roster) do
		if entry.rarity == rarity then
			table.insert(pool, entry)
		end
	end
	if #pool == 0 then
		return BrainrotData.Roster[1]
	end
	return pool[math.random(1, #pool)]
end

-- How much cash a brainrot earns per second with its mutation applied.
function BrainrotData.rateOf(entry, mutationName: string): number
	for _, mutation in ipairs(BrainrotData.Mutations) do
		if mutation.name == mutationName then
			return entry.rate * mutation.multiplier
		end
	end
	return entry.rate
end

-- How much cash selling a brainrot returns (rarity sell-back rate,
-- mutation multiplier included, rounded down).
function BrainrotData.sellPriceOf(entry, mutationName: string): number
	local rung = BrainrotData.findRarity(entry.rarity)
	local multiplier = 1
	for _, mutation in ipairs(BrainrotData.Mutations) do
		if mutation.name == mutationName then
			multiplier = mutation.multiplier
		end
	end
	return math.floor(entry.price * rung.sellBack * multiplier)
end

return BrainrotData
