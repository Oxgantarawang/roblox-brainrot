-- Config: every tunable number of Brainrot Breakout in one place.
-- Gameplay tuning lives here, not scattered through the scripts,
-- so balancing the game means editing this file only.

local Config = {}

-- Starting cash for a player who joins fresh.
Config.StartCash = 100

-- How often the conveyor drops a new brainrot (seconds).
Config.SpawnInterval = 6

-- How fast a brainrot walks the conveyor (studs per second).
Config.WalkSpeed = 7

-- How many brainrots may walk the conveyor at once.
Config.MaxWalking = 10

-- Income tick: the server pays every owned brainrot's rate this often.
Config.IncomeTickSeconds = 1

-- Rebirth: cost in cash for rebirth number n (1-based), and the
-- permanent income bonus each rebirth adds.
Config.RebirthBaseCost = 100000
Config.RebirthCostGrowth = 6
Config.RebirthIncomeBonus = 0.25

-- Stealing: how long a base lock lasts once the owner locks it, how
-- long before the same lock can be used again, and how long a thief
-- must wait between steal attempts.
Config.LockDuration = 60
Config.LockCooldown = 120
Config.StealCooldown = 15

-- Stealing a brainrot costs the thief nothing but time; the victim
-- keeps a consolation cut of the brainrot's price so a steal stings
-- instead of ruining a new player.
Config.StealConsolation = 0.25

-- Tsunami: the wave rolls in this often, warns first, then sweeps.
Config.TsunamiEverySeconds = 180
Config.TsunamiWarningSeconds = 10
Config.TsunamiWaveSpeed = 30
Config.TsunamiCashLoss = 0.10

-- Base plots: eight plots, four down each side of the conveyor.
-- The server hands them out in join order.
Config.BasePlots = {
	{ position = Vector3.new(-32, 0, -60), rotation = 0 },
	{ position = Vector3.new(32, 0, -60), rotation = 0 },
	{ position = Vector3.new(-32, 0, -20), rotation = 0 },
	{ position = Vector3.new(32, 0, -20), rotation = 0 },
	{ position = Vector3.new(-32, 0, 20), rotation = 0 },
	{ position = Vector3.new(32, 0, 20), rotation = 0 },
	{ position = Vector3.new(-32, 0, 60), rotation = 0 },
	{ position = Vector3.new(32, 0, 60), rotation = 0 },
}

-- Conveyor endpoints: brainrots enter at the north end and walk
-- south until they reach the despawn line.
Config.ConveyorStart = Vector3.new(0, 0, -95)
Config.ConveyorEnd = Vector3.new(0, 0, 95)

-- Where a fresh player spawns, and where the tsunami flings a
-- player it catches out in the open.
Config.SpawnPoint = Vector3.new(0, 3, 112)

-- Rebirth cost for rebirth number n: base * growth ^ (n - 1).
function Config.rebirthCost(rebirthNumber: number): number
	return math.floor(Config.RebirthBaseCost * (Config.RebirthCostGrowth ^ (rebirthNumber - 1)))
end

-- Income multiplier from rebirths: +25% per rebirth, compounding.
function Config.rebirthMultiplier(rebirths: number): number
	return (1 + Config.RebirthIncomeBonus) ^ rebirths
end

return Config
