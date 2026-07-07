local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Configuration & State
local justiceName = "PortableJustice"
local f3xName = "Building Tools"
local targetPlayers = {}
local starterGiveRan = false
local antiPunishEnabled = false
local scriptRunning = true
local antiPunishConnection = nil
local lastUnpunishTime = 0

-- ==========================
-- 1. UTILITY FUNCTIONS
-- ==========================
local function sendCommand(msg)
	local channel = TextChatService:FindFirstChild("RBXGeneral", true)
	if channel then
		channel:SendAsync(msg)
	end
end

local function getTool(name)
	local backpack = localPlayer:FindFirstChild("Backpack")
	local character = localPlayer.Character
	return (character and character:FindFirstChild(name)) or (backpack and backpack:FindFirstChild(name))
end

local function runStartup()
	if not starterGiveRan and scriptRunning then
		starterGiveRan = true
		sendCommand("startergive me b")
		task.wait(0.5)
		sendCommand("logs")
	end
end

-- ==========================
-- 2. PROTECTION LOGIC (ANTI-PUNISH)
-- ==========================

local seenCommands = {}
local seenOrder = {}
local MAX_SEEN = 200

local function cleanText(text)
	if not text then
		return ""
	end

	return text
		:gsub("\160", " ")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
end

local function rememberCommand(text)
	if seenCommands[text] then
		return false
	end

	seenCommands[text] = true
	table.insert(seenOrder, text)

	if #seenOrder > MAX_SEEN then
		local oldest = table.remove(seenOrder, 1)
		seenCommands[oldest] = nil
	end

	return true
end

local function parseCommandText(text)
	if not text or text == "" then
		return nil
	end

	text = cleanText(text)

	-- Expected examples:
	-- 6:39 PM [Username]: punish Bob
	-- 12:01 AM [Some Name]: kill all

	local timePart, username, command = text:match("^(.-)%s*%[([^%]]+)%]:%s*(.+)$")

	if timePart and username and command then
		timePart = cleanText(timePart)
		username = cleanText(username)
		command = cleanText(command)

		return {
			raw = text,
			time = timePart,
			username = username,
			command = command
		}
	end

	return {
		raw = text,
		time = "Unknown",
		username = "Unknown",
		command = text
	}
end

local function isPrefixMatch(fullName, shortTarget)
	fullName = fullName:lower()
	shortTarget = shortTarget:lower()

	return fullName:sub(1, #shortTarget) == shortTarget
end

local function isPunishTargetingMe(target)
	if not target or target == "" then
		return false
	end

	target = target:lower()

	local myName = localPlayer.Name:lower()
	local myDisplayName = localPlayer.DisplayName:lower()

	if target == "all" or target == "others" then
		return true
	end

	if target == myName or target == myDisplayName then
		return true
	end

	if isPrefixMatch(myName, target) or isPrefixMatch(myDisplayName, target) then
		return true
	end

	return false
end

local function handleNewLabel(label)
	if not label:IsA("TextLabel") then
		return
	end

	task.wait(0.05)

	local text = cleanText(label.Text)
	if text == "" then
		return
	end

	-- Ignore duplicates caused by the UI rebuilding the same list
	if not rememberCommand(text) then
		return
	end

	local parsed = parseCommandText(text)
	if not parsed then
		return
	end

	print("New command detected")
	print("Time:", parsed.time)
	print("Username:", parsed.username)
	print("Command:", parsed.command)
	print("Full:", parsed.raw)

	local cmd = parsed.command:lower()

	-- Matches:
	-- punish name
	-- :punish name
	local target = cmd:match("^:?punish%s+(%S+)")

	if target then
		print("Punish command found")
		print("Punish target:", target)

		if isPunishTargetingMe(target) and (antiPunishEnabled == true) then
			print(">>> PUNISH TARGETS YOU <<<")

            sendCommand("reset me")
            
		end
	end
end

local function initCommandDetector()
	task.spawn(function()
		local scrollGui = playerGui:WaitForChild("ScrollGui", 10)
		if not scrollGui then
			warn("ScrollGui not found")
			return
		end

		local textButton = scrollGui:WaitForChild("TextButton", 10)
		if not textButton then
			warn("TextButton not found")
			return
		end

		local outerFrame = textButton:WaitForChild("Frame", 10)
		if not outerFrame then
			warn("Outer Frame not found")
			return
		end

		local targetFrame = outerFrame:WaitForChild("Frame", 10)
		if not targetFrame then
			warn("Target Frame not found")
			return
		end

		print("Tracking command log in:", targetFrame:GetFullName())

		-- Seed current labels so already-visible commands are not treated as new
		for _, child in ipairs(targetFrame:GetChildren()) do
			if child:IsA("TextLabel") then
				local text = cleanText(child.Text)
				if text ~= "" then
					rememberCommand(text)
				end
			end
		end

		targetFrame.ChildAdded:Connect(function(child)
			if child:IsA("TextLabel") then
				handleNewLabel(child)
			end
		end)
	end)
end

initCommandDetector()


-- ==========================
-- 3. CORE ATTACK LOGIC
-- ==========================
local function executeKill(singlePlayer)
	local tool = getTool(f3xName)
	local syncAPI = tool and tool:FindFirstChild("SyncAPI")
	if not syncAPI then return end

	local headsToRemove = {}

	if singlePlayer then
		local head = singlePlayer.Character and singlePlayer.Character:FindFirstChild("Head")
		if head then table.insert(headsToRemove, head) end
	else
		for _, p in pairs(Players:GetPlayers()) do
			if targetPlayers[p.UserId] == true and p.Character then
				local h = p.Character:FindFirstChild("Head")
				if h then table.insert(headsToRemove, h) end
			end
		end
	end

	if #headsToRemove > 0 then
		pcall(function() 
			syncAPI:Invoke("Remove", headsToRemove) 
		end)
	end
end

local function executeJail(p)
	if not p or not p.Character or p == localPlayer then return end

	local tool = getTool(justiceName)
	if not tool then
		sendCommand("gear me 82357101")
		local timeout = 0
		while not tool and timeout < 10 do 
			task.wait(0.1)
			tool = getTool(justiceName)
			timeout = timeout + 1
		end
	end

	local myHRP = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	local remote = tool and (tool:FindFirstChild("MouseClick") or tool:FindFirstChildOfClass("RemoteEvent"))

	if myHRP and remote then
		myHRP.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
		task.wait(0.15)
		remote:FireServer(p.Character)
	end
end

-- ==========================
-- 4. BACKGROUND THREADS
-- ==========================
task.spawn(function()
	while scriptRunning do
		executeKill() 
		task.wait(0.7)
	end
end)

-- ==========================
-- 5. GUI SYSTEM
-- ==========================
local function makeDraggable(handle, root)
	local dragging = false
	local dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = root.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

		local delta = input.Position - dragStart
		root.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end)
end

local function createMenu()
	local old = playerGui:FindFirstChild("Advanced_Admin_Menu")
	if old then old:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name = "Advanced_Admin_Menu"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 10
	sg.Parent = playerGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 220, 0, 360)
	mainFrame.Position = UDim2.new(1, -240, 0.5, -180)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = sg
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 34)
	header.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	header.Text = "TARGET MENU"
	header.TextColor3 = Color3.new(1, 1, 1)
	header.Font = Enum.Font.GothamBold
	header.TextSize = 14
	header.Parent = mainFrame
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)

	-- Exit Button (Red X)
	local exitBtn = Instance.new("TextButton")
	exitBtn.Size = UDim2.new(0, 28, 0, 24)
	exitBtn.Position = UDim2.new(1, -32, 0, 5)
	exitBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	exitBtn.Text = "X"
	exitBtn.TextColor3 = Color3.new(1, 1, 1)
	exitBtn.Font = Enum.Font.GothamBold
	exitBtn.TextSize = 12
	exitBtn.BorderSizePixel = 0
	exitBtn.Parent = header
	Instance.new("UICorner", exitBtn).CornerRadius = UDim.new(0, 6)

	-- Minimize Button (-) Shifted left to make room for exit
	local minimize = Instance.new("TextButton")
	minimize.Size = UDim2.new(0, 28, 0, 24)
	minimize.Position = UDim2.new(1, -64, 0, 5)
	minimize.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	minimize.Text = "—"
	minimize.TextColor3 = Color3.new(1, 1, 1)
	minimize.Font = Enum.Font.GothamBold
	minimize.TextSize = 14
	minimize.BorderSizePixel = 0
	minimize.Parent = header
	Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 6)
	
	local Nuke = Instance.new("TextButton")
	Nuke.Size = UDim2.new(0, 28, 0, 24)
	Nuke.Position = UDim2.new(1, -216, 0, 5)
	Nuke.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
	Nuke.Text = ""
	Nuke.TextColor3 = Color3.new(1, 1, 1)
	Nuke.Font = Enum.Font.GothamBold
	Nuke.TextSize = 14
	Nuke.BorderSizePixel = 0
	Nuke.Parent = header
	Instance.new("UICorner", Nuke).CornerRadius = UDim.new(0, 6)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "PlayerList"
	scroll.Size = UDim2.new(1, -12, 1, -76)
	scroll.Position = UDim2.new(0, 6, 0, 40)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 6
	scroll.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scroll
	
	local apButton = Instance.new("TextButton")
	apButton.Name = "AntiPunishToggle"
	apButton.Size = UDim2.new(1, -12, 0, 26)
	apButton.Position = UDim2.new(0, 6, 1, -32)
	apButton.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
	apButton.Text = "ANTI-PUNISH: OFF"
	apButton.TextColor3 = Color3.new(1, 1, 1)
	apButton.Font = Enum.Font.GothamBold
	apButton.TextSize = 12
	apButton.BorderSizePixel = 0
	apButton.Parent = mainFrame
	Instance.new("UICorner", apButton).CornerRadius = UDim.new(0, 6)
	
	apButton.MouseButton1Click:Connect(function()
		antiPunishEnabled = not antiPunishEnabled
		if antiPunishEnabled then
			apButton.Text = "ANTI-PUNISH: ON"
			apButton.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
		else
			apButton.Text = "ANTI-PUNISH: OFF"
			apButton.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
		end
	end)

	local optionsPanel = Instance.new("Frame")
	optionsPanel.Name = "OptionsPanel"
	optionsPanel.Size = UDim2.new(0, 140, 0, 140)
	optionsPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	optionsPanel.BorderSizePixel = 0
	optionsPanel.Visible = false
	optionsPanel.ZIndex = 100
	optionsPanel.Parent = sg
	Instance.new("UICorner", optionsPanel).CornerRadius = UDim.new(0, 8)

	local optionsStroke = Instance.new("UIStroke")
	optionsStroke.Color = Color3.fromRGB(85, 85, 95)
	optionsStroke.Parent = optionsPanel

	local optionsLayout = Instance.new("UIListLayout")
	optionsLayout.Padding = UDim.new(0, 4)
	optionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	optionsLayout.Parent = optionsPanel

	local topPad = Instance.new("UIPadding")
	topPad.PaddingTop = UDim.new(0, 6)
	topPad.PaddingLeft = UDim.new(0, 6)
	topPad.PaddingRight = UDim.new(0, 6)
	topPad.PaddingBottom = UDim.new(0, 6)
	topPad.Parent = optionsPanel

	local currentTarget = nil
	local minimized = false
	local rowByUserId = {}

	local function hideOptions()
		currentTarget = nil
		optionsPanel.Visible = false
	end

	local function clampPanelToScreen(x, y, width, height)
		local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
		x = math.clamp(x, 0, viewport.X - width)
		y = math.clamp(y, 0, viewport.Y - height)
		return x, y
	end

	local function showOptionsFor(button, player)
		currentTarget = player
		local absPos = button.AbsolutePosition
		local panelWidth = 140
		local x = absPos.X - panelWidth - 8
		local y = absPos.Y
		x, y = clampPanelToScreen(x, y, 140, 140)
		optionsPanel.Position = UDim2.fromOffset(x, y)
		optionsPanel.Visible = true

		local loopBtn = optionsPanel:FindFirstChild("LoopToggle")
		if loopBtn then
			local enabled = targetPlayers[player.UserId] == true
			loopBtn.Text = enabled and "LOOP: ON" or "LOOP: OFF"
			loopBtn.BackgroundColor3 = enabled and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(70, 70, 75)
		end
	end

	local function makeOptionButton(name, text, color, order, callback)
		local b = Instance.new("TextButton")
		b.Name = name
		b.Size = UDim2.new(1, 0, 0, 28)
		b.LayoutOrder = order
		b.BackgroundColor3 = color
		b.Text = text
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Font = Enum.Font.Gotham
		b.TextSize = 12
		b.BorderSizePixel = 0
		b.ZIndex = 101
		b.Parent = optionsPanel
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		b.MouseButton1Click:Connect(function()
			if currentTarget then callback(currentTarget) end
		end)
		return b
	end

	makeOptionButton("KillButton", "KILL", Color3.fromRGB(180, 60, 60), 1, function(p)
		executeKill(p)
		hideOptions()
	end)

	makeOptionButton("JailButton", "JAIL", Color3.fromRGB(60, 100, 180), 2, function(p)
		executeJail(p)
		hideOptions()
	end)

	makeOptionButton("LoopToggle", "LOOP: OFF", Color3.fromRGB(70, 70, 75), 3, function(p)
		targetPlayers[p.UserId] = not targetPlayers[p.UserId]
		showOptionsFor(rowByUserId[p.UserId], p)
	end)

	makeOptionButton("CancelButton", "CANCEL", Color3.fromRGB(55, 55, 60), 4, hideOptions)

	local function createPlayerEntry(p)
		if p == localPlayer or rowByUserId[p.UserId] then return end
		local btn = Instance.new("TextButton")
		btn.Name = tostring(p.UserId)
		btn.Size = UDim2.new(1, -4, 0, 30)
		btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		btn.Text = "  " .. p.DisplayName .. "  (@" .. p.Name .. ")"
		btn.TextColor3 = Color3.new(0.92, 0.92, 0.92)
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 13
		btn.Parent = scroll
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.MouseButton1Click:Connect(function() showOptionsFor(btn, p) end)
		rowByUserId[p.UserId] = btn
	end

	local function removePlayerEntry(userId)
		local row = rowByUserId[userId]
		if row then row:Destroy() rowByUserId[userId] = nil end
		if currentTarget and currentTarget.UserId == userId then hideOptions() end
		targetPlayers[userId] = nil
	end

	local function refreshPlayers()
		for _, p in ipairs(Players:GetPlayers()) do createPlayerEntry(p) end
		for userId, _ in pairs(rowByUserId) do
			if not Players:GetPlayerByUserId(userId) then removePlayerEntry(userId) end
		end
	end

	-- Exit button logic
	exitBtn.MouseButton1Click:Connect(function()
		scriptRunning = false -- Kills the background loop
		if antiPunishConnection then
			antiPunishConnection:Disconnect() -- Stops log listener
		end
		sg:Destroy() -- Destroys UI
	end)

	minimize.MouseButton1Click:Connect(function()
		minimized = not minimized
		scroll.Visible = not minimized
		apButton.Visible = not minimized
		mainFrame.Size = minimized and UDim2.new(0, 220, 0, 34) or UDim2.new(0, 220, 0, 360)
		minimize.Text = minimized and "+" or "—"
		if minimized then hideOptions() end
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.UserInputType == Enum.UserInputType.MouseButton1 and optionsPanel.Visible then
			hideOptions()
		end
	end)

	makeDraggable(header, mainFrame)
	Players.PlayerAdded:Connect(refreshPlayers)
	Players.PlayerRemoving:Connect(function(p) removePlayerEntry(p.UserId) end)
	refreshPlayers()
	
	return sg
end

createMenu()
localPlayer.CharacterAdded:Connect(runStartup)
runStartup()
