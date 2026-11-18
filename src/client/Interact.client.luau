-- Interact.client: what the player does in the 3D world, beyond the
-- HUD buttons. Click a brainrot standing on another player's base
-- to try to steal it; press B to dash home to your base when the
-- tsunami warning goes up; press L to lock your base. Stealing
-- asks the server through the StealBrainrot RemoteEvent, and the
-- server decides: a locked base, a cooldown or an empty slot all
-- come back as feedback instead of a steal.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Dash home: teleport the character to its own base plot. The
-- server still decides whether the tsunami catches you, so the
-- dash is a real escape, not a cheat: it only moves you, it never
-- grants safety by itself.
local function dashHome()
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	-- The client remembers its plot from the last StateUpdate the
	-- HUD received; ask the HUD for it through the shared value.
	local plotValue = player:FindFirstChild("BrainrotPlot")
	local target = Config.SpawnPoint
	if plotValue and plotValue:IsA("Vector3Value") then
		target = plotValue.Value + Vector3.new(0, 3, 0)
	end
	root.CFrame = CFrame.new(target)
end

-- Clicking a brainrot on someone else's base tries to steal it.
-- The click finds the model, reads which slot it sits in from its
-- name tag, and asks the server; the server checks lock, cooldown
-- and ownership and answers through Feedback.
mouse.Button1Down:Connect(function()
	local target = mouse.Target
	if not target then
		return
	end
	local model = target:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end
	local slotTag = model:FindFirstChild("BaseSlot")
	local ownerTag = model:FindFirstChild("BaseOwner")
	if not slotTag or not ownerTag then
		return
	end
	local owner = Players:FindFirstChild(ownerTag.Value)
	if not owner or owner == player then
		return
	end
	remotes:WaitForChild("StealBrainrot"):FireServer(owner, slotTag.Value)
end)

-- Keys: B dashes home, L locks the base. ContextActionService is
-- not needed here because these keys are not camera keys; the
-- gameProcessedEvent guard keeps chat typing from triggering them.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.B then
		dashHome()
	elseif input.KeyCode == Enum.KeyCode.L then
		remotes:WaitForChild("LockBase"):FireServer()
	end
end)

-- Keep the client's plot value fresh so dashHome knows where home
-- is. The HUD owns the snapshot; this script only stores the plot.
remotes:WaitForChild("StateUpdate").OnClientEvent:Connect(function(snapshot)
	local plotValue = player:FindFirstChild("BrainrotPlot")
	if not plotValue then
		plotValue = Instance.new("Vector3Value")
		plotValue.Name = "BrainrotPlot"
		plotValue.Parent = player
	end
	local plots = Config.BasePlots
	local index = snapshot.basePlot or 1
	if plots[index] then
		plotValue.Value = plots[index].position
	end
end)
