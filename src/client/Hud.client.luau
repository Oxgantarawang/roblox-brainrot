-- Hud.client: the whole interface of Brainrot Breakout, built in
-- code on the client. Top bar: cash, income per second, rebirths.
-- Below it: the owned-brainrots list (name, rarity, $/s, sell
-- button), the shop (next tiers to chase), the base-lock button and
-- the rebirth button, plus a feedback line and the tsunami banner.
-- The HUD never moves money itself; it shows what StateUpdate says
-- and asks the server through RemoteEvents. Text stays clear of the
-- top-left corner, where Roblox draws its own menu buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- Small helper: a label with the game's chunky look.
local function makeLabel(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	label.BackgroundTransparency = 0.25
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBlack
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, size, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Font = Enum.Font.GothamBlack
	button.Parent = parent
	return button
end

-- Top bar, centred so the top-left stays clear for Roblox's menu.
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 12)
topBar.Size = UDim2.new(0, 640, 0, 64)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
topBar.BackgroundTransparency = 0.15
topBar.Parent = gui

local cashLabel = makeLabel(topBar, "CashLabel", "Cash: $100", UDim2.new(0, 200, 0, 28), UDim2.new(0, 16, 0, 6), 24, Color3.fromRGB(120, 255, 140))
local incomeLabel = makeLabel(topBar, "IncomeLabel", "+$0/s", UDim2.new(0, 200, 0, 28), UDim2.new(0, 16, 0, 34), 20, Color3.fromRGB(255, 220, 90))
local rebirthLabel = makeLabel(topBar, "RebirthLabel", "Rebirths: 0  (x1.00)", UDim2.new(0, 220, 0, 28), UDim2.new(0, 240, 0, 6), 20)
local nextLabel = makeLabel(topBar, "NextLabel", "Next rebirth: $100,000", UDim2.new(0, 220, 0, 28), UDim2.new(0, 240, 0, 34), 16, Color3.fromRGB(180, 180, 255))

-- Feedback line under the top bar: buys, steals, warnings.
local feedbackLabel = makeLabel(gui, "FeedbackLabel", "Welcome to Brainrot Breakout! Buy brainrots off the conveyor, park them on your base, and watch the cash roll in.", UDim2.new(0, 640, 0, 30), UDim2.new(0.5, -320, 0, 84), 16, Color3.fromRGB(255, 255, 255))
feedbackLabel.AnchorPoint = Vector2.new(0, 0)
feedbackLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Tsunami banner: hidden until the server warns of a wave.
local tsunamiBanner = Instance.new("TextLabel")
tsunamiBanner.Name = "TsunamiBanner"
tsunamiBanner.AnchorPoint = Vector2.new(0.5, 0)
tsunamiBanner.Position = UDim2.new(0.5, 0, 0, 122)
tsunamiBanner.Size = UDim2.new(0, 640, 0, 44)
tsunamiBanner.BackgroundColor3 = Color3.fromRGB(30, 90, 200)
tsunamiBanner.Text = ""
tsunamiBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
tsunamiBanner.TextSize = 26
tsunamiBanner.Font = Enum.Font.GothamBlack
tsunamiBanner.Visible = false
tsunamiBanner.Parent = gui

-- Left panel: my base, the brainrots I own, each with a sell button.
local basePanel = Instance.new("Frame")
basePanel.Name = "BasePanel"
basePanel.Position = UDim2.new(0, 12, 0, 180)
basePanel.Size = UDim2.new(0, 300, 0, 320)
basePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
basePanel.BackgroundTransparency = 0.15
basePanel.Parent = gui

local baseTitle = makeLabel(basePanel, "BaseTitle", "MY BASE", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 20, Color3.fromRGB(255, 220, 90))
baseTitle.TextXAlignment = Enum.TextXAlignment.Center

local ownedList = Instance.new("ScrollingFrame")
ownedList.Name = "OwnedList"
ownedList.Position = UDim2.new(0, 6, 0, 36)
ownedList.Size = UDim2.new(1, -12, 1, -42)
ownedList.BackgroundTransparency = 1
ownedList.ScrollBarThickness = 6
ownedList.Parent = basePanel

-- Right panel: the shop, the next tiers to chase, with prices.
local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.AnchorPoint = Vector2.new(1, 0)
shopPanel.Position = UDim2.new(1, -12, 0, 180)
shopPanel.Size = UDim2.new(0, 300, 0, 320)
shopPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
shopPanel.BackgroundTransparency = 0.15
shopPanel.Parent = gui

local shopTitle = makeLabel(shopPanel, "ShopTitle", "SHOP: NEXT TIERS", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 20, Color3.fromRGB(120, 220, 255))
shopTitle.TextXAlignment = Enum.TextXAlignment.Center

local shopList = Instance.new("ScrollingFrame")
shopList.Name = "ShopList"
shopList.Position = UDim2.new(0, 6, 0, 36)
shopList.Size = UDim2.new(1, -12, 1, -42)
shopList.BackgroundTransparency = 1
shopList.ScrollBarThickness = 6
shopList.Parent = shopPanel

-- Bottom buttons: lock the base, rebirth.
local lockButton = makeButton(gui, "LockButton", "LOCK BASE (60s)", UDim2.new(0, 200, 0, 44), UDim2.new(0.5, -210, 1, -60), Color3.fromRGB(60, 120, 255))
local rebirthButton = makeButton(gui, "RebirthButton", "REBIRTH", UDim2.new(0, 200, 0, 44), UDim2.new(0.5, 10, 1, -60), Color3.fromRGB(170, 60, 220))

lockButton.MouseButton1Click:Connect(function()
	remotes:WaitForChild("LockBase"):FireServer()
end)

rebirthButton.MouseButton1Click:Connect(function()
	remotes:WaitForChild("Rebirth"):FireServer()
end)

-- Rebuild the owned list from a StateUpdate snapshot.
local function rebuildOwnedList(owned)
	for _, child in ipairs(ownedList:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local y = 0
	for _, record in ipairs(owned) do
		local row = makeLabel(ownedList, "Owned_" .. tostring(record.slot),
			record.name .. "  [" .. record.rarity .. " " .. record.mutation .. "]  $" .. tostring(record.rate) .. "/s",
			UDim2.new(1, -60, 0, 26), UDim2.new(0, 0, 0, y), 14,
			BrainrotData.findRarity(record.rarity).color)
		y += 30
		local sell = makeButton(ownedList, "Sell_" .. tostring(record.slot), "SELL",
			UDim2.new(0, 52, 0, 26), UDim2.new(1, -56, 0, y - 30), Color3.fromRGB(200, 60, 60))
		sell.TextSize = 14
		local slot = record.slot
		sell.MouseButton1Click:Connect(function()
			remotes:WaitForChild("SellBrainrot"):FireServer(slot)
		end)
	end
	ownedList.CanvasSize = UDim2.new(0, 0, 0, y)
	if #owned == 0 then
		makeLabel(ownedList, "EmptyLabel", "No brainrots yet. Buy one off the conveyor!", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), 14)
	end
end

-- Rebuild the shop: every roster entry, cheapest first, with its
-- rarity colour, rate and price, so the next tier is always visible.
local function rebuildShop(cash)
	for _, child in ipairs(shopList:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local sorted = {}
	for _, entry in ipairs(BrainrotData.Roster) do
		table.insert(sorted, entry)
	end
	table.sort(sorted, function(a, b)
		return a.price < b.price
	end)
	local y = 0
	for _, entry in ipairs(sorted) do
		local affordable = cash >= entry.price
		local row = makeLabel(shopList, "Shop_" .. entry.id,
			entry.name .. "  $" .. tostring(entry.rate) .. "/s  -  $" .. tostring(entry.price),
			UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, y), 14,
			affordable and BrainrotData.findRarity(entry.rarity).color or Color3.fromRGB(140, 140, 140))
		y += 26
	end
	shopList.CanvasSize = UDim2.new(0, 0, 0, y)
end

-- The server's snapshot drives every number on screen.
remotes:WaitForChild("StateUpdate").OnClientEvent:Connect(function(snapshot)
	cashLabel.Text = "Cash: $" .. tostring(snapshot.cash)
	incomeLabel.Text = "+$" .. tostring(snapshot.incomePerSecond) .. "/s"
	rebirthLabel.Text = "Rebirths: " .. tostring(snapshot.rebirths) .. "  (x" .. string.format("%.2f", snapshot.multiplier) .. ")"
	nextLabel.Text = "Next rebirth: $" .. tostring(snapshot.nextRebirthCost)
	if snapshot.locked then
		lockButton.Text = "BASE LOCKED"
		lockButton.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
	elseif snapshot.lockReadyIn > 0 then
		lockButton.Text = "LOCK READY IN " .. tostring(snapshot.lockReadyIn) .. "s"
		lockButton.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
	else
		lockButton.Text = "LOCK BASE (60s)"
		lockButton.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
	end
	rebuildOwnedList(snapshot.owned)
	rebuildShop(snapshot.cash)
end)

remotes:WaitForChild("Feedback").OnClientEvent:Connect(function(message)
	feedbackLabel.Text = message
end)

remotes:WaitForChild("TsunamiWarning").OnClientEvent:Connect(function(message)
	if message == "" then
		tsunamiBanner.Visible = false
	else
		tsunamiBanner.Text = message
		tsunamiBanner.Visible = true
	end
end)
