local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local claimDaily = remotes:WaitForChild("ClaimDaily")
local redeemCode = remotes:WaitForChild("RedeemCode")
local dataUpdated = remotes:WaitForChild("DataUpdated")

local config = require(ReplicatedStorage:WaitForChild("Config"))

local OK_COLOR = Color3.fromRGB(120, 220, 130)
local ERR_COLOR = Color3.fromRGB(235, 110, 110)
local DIM_COLOR = Color3.fromRGB(175, 178, 190)

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local screenGui = create("ScreenGui", {
	Name = "RewardsUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local toggle = create("TextButton", {
	Name = "Toggle",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 12),
	Size = UDim2.fromOffset(124, 34),
	BackgroundColor3 = Color3.fromRGB(38, 40, 48),
	TextColor3 = Color3.fromRGB(240, 240, 245),
	Text = "Daily / Codes",
	TextSize = 14,
	Font = Enum.Font.GothamMedium,
	AutoButtonColor = true,
}, screenGui)

create("UICorner", { CornerRadius = UDim.new(0, 6) }, toggle)
create("UIStroke", { Color = Color3.fromRGB(72, 74, 88), Thickness = 1 }, toggle)

local panel = create("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 54),
	Size = UDim2.fromOffset(320, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = Color3.fromRGB(26, 27, 33),
	Visible = false,
}, screenGui)

create("UICorner", { CornerRadius = UDim.new(0, 8) }, panel)
create("UIStroke", { Color = Color3.fromRGB(72, 74, 88), Thickness = 1 }, panel)

create("UIPadding", {
	PaddingTop = UDim.new(0, 12),
	PaddingBottom = UDim.new(0, 12),
	PaddingLeft = UDim.new(0, 12),
	PaddingRight = UDim.new(0, 12),
}, panel)

create("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 8),
}, panel)

create("TextLabel", {
	Name = "Title",
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, 22),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(240, 240, 245),
	Text = "Daily rewards",
	TextSize = 17,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local coinsLabel = create("TextLabel", {
	Name = "Coins",
	LayoutOrder = 2,
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(240, 240, 245),
	Text = "Coins: 0",
	TextSize = 14,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local streakLabel = create("TextLabel", {
	Name = "Streak",
	LayoutOrder = 3,
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundTransparency = 1,
	TextColor3 = DIM_COLOR,
	Text = ("Streak: not started, %d days total"):format(#config.DailyRewards),
	TextSize = 14,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local timerLabel = create("TextLabel", {
	Name = "Timer",
	LayoutOrder = 4,
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundTransparency = 1,
	TextColor3 = DIM_COLOR,
	Text = "Checking...",
	TextSize = 14,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local grid = create("Frame", {
	Name = "Days",
	LayoutOrder = 5,
	Size = UDim2.new(1, 0, 0, 116),
	BackgroundTransparency = 1,
}, panel)

create("UIGridLayout", {
	CellSize = UDim2.fromOffset(68, 52),
	CellPadding = UDim2.fromOffset(6, 6),
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, grid)

local statusLabel = create("TextLabel", {
	Name = "Status",
	LayoutOrder = 6,
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundTransparency = 1,
	TextColor3 = DIM_COLOR,
	Text = "Pick a day or enter a code.",
	TextSize = 13,
	Font = Enum.Font.Gotham,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
}, panel)

local codeFrame = create("Frame", {
	Name = "CodeRow",
	LayoutOrder = 7,
	Size = UDim2.new(1, 0, 0, 32),
	BackgroundTransparency = 1,
}, panel)

local codeBox = create("TextBox", {
	Name = "CodeInput",
	Size = UDim2.new(1, -96, 1, 0),
	BackgroundColor3 = Color3.fromRGB(38, 40, 48),
	TextColor3 = Color3.fromRGB(240, 240, 245),
	PlaceholderText = "PROMO CODE",
	PlaceholderColor3 = Color3.fromRGB(120, 124, 138),
	Text = "",
	ClearTextOnFocus = false,
	TextSize = 14,
	Font = Enum.Font.Gotham,
}, codeFrame)

create("UICorner", { CornerRadius = UDim.new(0, 6) }, codeBox)
create("UIStroke", { Color = Color3.fromRGB(72, 74, 88), Thickness = 1 }, codeBox)

local redeemButton = create("TextButton", {
	Name = "Redeem",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.fromOffset(88, 32),
	BackgroundColor3 = Color3.fromRGB(56, 120, 220),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Text = "Redeem",
	TextSize = 14,
	Font = Enum.Font.GothamMedium,
	AutoButtonColor = true,
}, codeFrame)

create("UICorner", { CornerRadius = UDim.new(0, 6) }, redeemButton)

local nextClaimAt = 0
local claimInFlight = false
local redeemInFlight = false

local function setStatus(text, color)
	statusLabel.Text = text
	statusLabel.TextColor3 = color or DIM_COLOR
end

local function refreshTimer()
	local remaining = nextClaimAt - os.time()
	if nextClaimAt == 0 or remaining <= 0 then
		timerLabel.Text = "Reward ready"
		timerLabel.TextColor3 = OK_COLOR
		return
	end

	timerLabel.Text = ("Next in %02d:%02d:%02d"):format(remaining // 3600, (remaining % 3600) // 60, remaining % 60)
	timerLabel.TextColor3 = DIM_COLOR
end

local function requestClaim()
	if claimInFlight then
		return
	end
	claimInFlight = true

	local ok, result = pcall(function()
		return claimDaily:InvokeServer()
	end)

	claimInFlight = false

	if not ok or typeof(result) ~= "table" then
		setStatus("Server did not respond.", ERR_COLOR)
		return
	end

	setStatus(tostring(result.message), result.ok and OK_COLOR or ERR_COLOR)
	if result.nextClaimAt then
		nextClaimAt = result.nextClaimAt
		refreshTimer()
	end
end

local function requestRedeem()
	if redeemInFlight then
		return
	end

	local code = string.upper((string.gsub(codeBox.Text, "%s+", "")))
	if #code == 0 then
		setStatus("Enter a code first.", ERR_COLOR)
		return
	end

	redeemInFlight = true

	local ok, result = pcall(function()
		return redeemCode:InvokeServer(code)
	end)

	redeemInFlight = false

	if not ok or typeof(result) ~= "table" then
		setStatus("Server did not respond.", ERR_COLOR)
		return
	end

	setStatus(tostring(result.message), result.ok and OK_COLOR or ERR_COLOR)
	if result.ok then
		codeBox.Text = ""
	end
end

-- Every button asks the server the same question. The server decides which day is actually claimable.
for day, reward in config.DailyRewards do
	local button = create("TextButton", {
		Name = "Day" .. day,
		LayoutOrder = day,
		BackgroundColor3 = Color3.fromRGB(38, 40, 48),
		TextColor3 = Color3.fromRGB(240, 240, 245),
		Text = ("Day %d\n+%d"):format(day, reward.Coins),
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		AutoButtonColor = true,
	}, grid)

	create("UICorner", { CornerRadius = UDim.new(0, 6) }, button)
	create("UIStroke", { Color = Color3.fromRGB(72, 74, 88), Thickness = 1 }, button)

	button.Activated:Connect(requestClaim)
end

redeemButton.Activated:Connect(requestRedeem)
codeBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		requestRedeem()
	end
end)

toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

dataUpdated.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then
		return
	end

	coinsLabel.Text = ("Coins: %d"):format(data.Coins or 0)

	if data.Streak and data.Streak > 0 then
		streakLabel.Text = ("Streak: day %d / %d"):format(data.Streak, #config.DailyRewards)
	else
		streakLabel.Text = ("Streak: not started, %d days total"):format(#config.DailyRewards)
	end

	nextClaimAt = data.NextClaimAt or 0
	refreshTimer()
end)

task.spawn(function()
	while true do
		refreshTimer()
		task.wait(1)
	end
end)
