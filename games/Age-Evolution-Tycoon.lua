local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- // Initial Drop Exploit Call
local args = {
    vector.create(-685.1201171875, 1.9517230987548828, 300.91046142578125),
    2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
}
task.spawn(function()
    local dropperEvents = ReplicatedStorage:WaitForChild("DropperEvents", 5)
    local collectDrop = dropperEvents and dropperEvents:WaitForChild("CollectDrop", 5)
    if collectDrop then
        collectDrop:FireServer(unpack(args))
    end
end)

-- // UI Framework Integration Wait-loop
local UI = shared.NoComment
while not UI or not UI.Ready do
    task.wait()
    UI = shared.NoComment
end

-- // Setup Window & Components
local main = UI.Windows["MainMenu"]
if not main then
    main = UI.CreateWindow({
        Id = "MainMenu",
        Title = "No comment",
    })
end

local tab = main:AddTab("Evolution Tycoon")
local automationSection = tab:AddSection("Automation")

-- // Script Settings / States
local _AB = false
local AUTO_REBIRTH = false
local myPlot = nil
local rebirthCooldown = false

local touchedButtons = {}
local lastTouchedButton = nil

-- // Timing Configurations
local MAIN_LOOP_DELAY = 0.06
local AFTER_TOUCH_DELAY = 0.2
local TOUCH_TIMEOUT = 0.35
local RELOCK_DELAY = 0.3
local NO_BUTTON_DELAY = 0.35

-- // Intercepted Status Logger (Bridged to UI Notifications)
local lastStatus = ""
local function SetStatus(text)
    if text == lastStatus then return end
    lastStatus = text
    
    -- Send notifications for critical milestones instead of spamming trivial movements
    if string.find(text, "Locked") or string.find(text, "requested") or string.find(text, "No buttons") then
        UI.Notify({
            Title = "Tycoon Status",
            Text = text,
        })
    end
    print("[Liquid Hub]: " .. text)
end

-- // Helper Functions Core
local function FindPlot()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then
        SetStatus("workspace.Plots missing")
        return nil
    end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { char }
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(hrp.Position, Vector3.new(0, -80, 0), params)
    if result and result.Instance then
        for _, plot in ipairs(plotsFolder:GetChildren()) do
            if result.Instance:IsDescendantOf(plot) then
                return plot
            end
        end
    end
    return nil
end

local function IsActuallyInWorkspace(inst)
    return inst and inst:IsDescendantOf(workspace)
end

local function HasBoughtMarker(button)
    if button:GetAttribute("Bought") == true or button:GetAttribute("Purchased") == true or button:GetAttribute("IsBought") == true then
        return true
    end
    local boughtValue = button:FindFirstChild("Bought", true) or button:FindFirstChild("Purchased", true) or button:FindFirstChild("IsBought", true)
    if boughtValue and boughtValue:IsA("BoolValue") and boughtValue.Value == true then
        return true
    end
    return false
end

local function GetBase(button)
    local base = button:FindFirstChild("Base", true)
    if base and base:IsA("BasePart") then return base end
    for _, obj in ipairs(button:GetDescendants()) do
        if obj:IsA("BasePart") and obj.CanTouch then return obj end
    end
    return nil
end

local function IsButtonBuyable(button, plot)
    if not button or not plot then return false end
    local buttonsFolder = plot:FindFirstChild("Buttons")
    if not buttonsFolder or not button:IsDescendantOf(buttonsFolder) then return false end
    if not IsActuallyInWorkspace(button) or touchedButtons[button] then return false end
    if HasBoughtMarker(button) then
        touchedButtons[button] = nil
        return false
    end
    if button:GetAttribute("Unlocked") == false then return false end

    local base = GetBase(button)
    if not base or not IsActuallyInWorkspace(base) or base.CanTouch == false then
        touchedButtons[button] = nil
        return false
    end

    local gui = button:FindFirstChild("BillboardGui", true)
    if base.Transparency >= 1 and (not gui or gui.Enabled == false) then
        touchedButtons[button] = nil
        return false
    end
    return true
end

local function GetButtonFromGuideEffect(plot)
    if not plot then return nil end
    local buttonsFolder = plot:FindFirstChild("Buttons")
    if not buttonsFolder then return nil end

    local char = LP.Character
    if not char then return nil end

    local searchPlaces = { char, PlayerGui, plot }
    for _, place in ipairs(searchPlaces) do
        if place then
            for _, obj in ipairs(place:GetDescendants()) do
                if obj:IsA("Beam") and obj.Enabled ~= false then
                    local a0, a1 = obj.Attachment0, obj.Attachment1
                    if a1 and a1.Parent then
                        local targetPart = a1.Parent
                        for _, button in ipairs(buttonsFolder:GetChildren()) do
                            if targetPart:IsDescendantOf(button) and IsButtonBuyable(button, plot) then return button end
                        end
                    end
                    if a0 and a0.Parent then
                        local targetPart = a0.Parent
                        for _, button in ipairs(buttonsFolder:GetChildren()) do
                            if targetPart:IsDescendantOf(button) and IsButtonBuyable(button, plot) then return button end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local ZERO_VECTOR = Vector3.zero
local TELEPORT_OFFSET = CFrame.new(0, 1.25, 0)

local function GetCharacterRoot()
	local char = LP.Character
	if not char then
		return nil, nil
	end

	return char, char:FindFirstChild("HumanoidRootPart")
end

local function GetNextBuyableButton(plot)
	local buttonsFolder = plot and plot:FindFirstChild("Buttons")
	if not buttonsFolder then
		return nil
	end

	local _, hrp = GetCharacterRoot()
	local rootPosition = hrp and hrp.Position

	local closestButton
	local closestDistanceSquared = math.huge
	local firstBuyableButton

	for _, button in ipairs(buttonsFolder:GetChildren()) do
		if IsButtonBuyable(button, plot) then
			local base = GetBase(button)

			if base then
				-- Keep a fallback for when the character is unavailable.
				firstBuyableButton = firstBuyableButton or button

				if rootPosition then
					local offset = rootPosition - base.Position
					local distanceSquared = offset:Dot(offset)

					if distanceSquared < closestDistanceSquared then
						closestDistanceSquared = distanceSquared
						closestButton = button
					end
				end
			end
		end
	end

	return closestButton or firstBuyableButton
end

local function CharacterIsTouchingPart(char, part)
	if not char or not part or not part:IsDescendantOf(workspace) then
		return false
	end

	local touchingParts = part:GetTouchingParts()

	for i = 1, #touchingParts do
		if touchingParts[i]:IsDescendantOf(char) then
			return true
		end
	end

	return false
end

local function TeleportToButton(button, plot)
	local char, hrp = GetCharacterRoot()

	if not hrp then
		SetStatus("Character not ready")
		return false
	end

	local base = GetBase(button)

	if not base
		or not base:IsDescendantOf(workspace)
		or not IsButtonBuyable(button, plot)
	then
		return false
	end

	local touched = false

	local connection = base.Touched:Connect(function(hit)
		if hit and hit:IsDescendantOf(char) then
			touched = true
		end
	end)

	hrp.AssemblyLinearVelocity = ZERO_VECTOR
	hrp.AssemblyAngularVelocity = ZERO_VECTOR
	char:PivotTo(base.CFrame * TELEPORT_OFFSET)

	local deadline = os.clock() + TOUCH_TIMEOUT

	while not touched and _AB and hrp.Parent and os.clock() < deadline do
		-- These checks are cheaper than GetTouchingParts().
		if HasBoughtMarker(button)
			or not base:IsDescendantOf(workspace)
			or not base.CanTouch
		then
			touched = true
			break
		end

		task.wait(0.03)
	end

	-- Only perform the more expensive physics query once.
	if not touched
		and base.Parent
		and base.CanTouch
		and CharacterIsTouchingPart(char, base)
	then
		touched = true
	end

	connection:Disconnect()

	if not touched then
		return false
	end

	touchedButtons[button] = true
	lastTouchedButton = button

	SetStatus("Touched " .. button.Name)
	return true
end

local function CleanTouchedCache()
    for oldButton in pairs(touchedButtons) do
        if not oldButton or not oldButton:IsDescendantOf(workspace) then
            touchedButtons[oldButton] = nil
        else
            local base = GetBase(oldButton)
            if not base or not base:IsDescendantOf(workspace) or base.CanTouch == false or HasBoughtMarker(oldButton) then
                touchedButtons[oldButton] = nil
            end
        end
    end
end

local function TryAutoRebirth()
    if not AUTO_REBIRTH or rebirthCooldown then return end
    rebirthCooldown = true
    SetStatus("No buttons left - trying rebirth")

    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    local buyRebirthEvent = remoteEvents and remoteEvents:FindFirstChild("BuyRebirth")

    if not buyRebirthEvent then
        SetStatus("BuyRebirth remote missing")
        rebirthCooldown = false
        return
    end

    buyRebirthEvent:FireServer()
    SetStatus("Rebirth requested")
    task.wait(10)

    myPlot = nil
    touchedButtons = {}
    lastTouchedButton = nil
    rebirthCooldown = false

    local collectDrop = ReplicatedStorage:WaitForChild("DropperEvents"):WaitForChild("CollectDrop")
    collectDrop:FireServer(unpack(args))
end

-- // Inject Layout Elements into structural UI sections
automationSection:AddToggle({
    Text = "Auto Buy Tycoon",
    Default = false,
    Callback = function(value)
        _AB = value
        if _AB then
            touchedButtons = {}
            lastTouchedButton = nil
            myPlot = FindPlot()
            if myPlot then
                SetStatus("Locked plot: " .. myPlot.Name)
            else
                SetStatus("Auto Buy ON - scanning for plot")
            end
        else
            myPlot = nil
            touchedButtons = {}
            lastTouchedButton = nil
            SetStatus("Idle")
        end
    end,
})

automationSection:AddToggle({
    Text = "Auto Rebirth",
    Default = false,
    Callback = function(value)
        AUTO_REBIRTH = value
        SetStatus("Auto Rebirth: " .. (AUTO_REBIRTH and "Enabled" or "Disabled"))
    end,
})

-- // Main Processing Loop
task.spawn(function()
    while task.wait(MAIN_LOOP_DELAY) do
        if _AB then
            if not myPlot or not myPlot:IsDescendantOf(workspace) then
                local newPlot = FindPlot()
                if newPlot then
                    myPlot = newPlot
                    touchedButtons = {}
                    lastTouchedButton = nil
                    SetStatus("Re-locked plot: " .. myPlot.Name)
                else
                    SetStatus("Auto Buy ON - waiting for plot")
                    task.wait(RELOCK_DELAY)
                    continue
                end
            end

            local buttonsFolder = myPlot:FindFirstChild("Buttons")
            if not buttonsFolder then
                task.wait(RELOCK_DELAY)
                continue
            end

            CleanTouchedCache()
            local button = GetButtonFromGuideEffect(myPlot) or GetNextBuyableButton(myPlot)

            if button then
                local touched = TeleportToButton(button, myPlot)
                task.wait(touched and AFTER_TOUCH_DELAY or 0.12)
            else
                task.wait(NO_BUTTON_DELAY)
                CleanTouchedCache()

                local count = #buttonsFolder:GetChildren()
                if count == 0 then
                    TryAutoRebirth()
                end
            end
        end
    end
end)

-- // Character Setup & Rig Updates
local function SetupDeathHandling(character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.Died:Connect(function()
        myPlot = nil
        touchedButtons = {}
        lastTouchedButton = nil
        SetStatus("Character Reset - Maintaining Engine Engine Run")
    end)
end

if LP.Character then SetupDeathHandling(LP.Character) end
LP.CharacterAdded:Connect(function(character)
    task.wait(0.75)
    SetupDeathHandling(character)
    if _AB then
        myPlot = FindPlot()
        touchedButtons = {}
        lastTouchedButton = nil
    end
end)
