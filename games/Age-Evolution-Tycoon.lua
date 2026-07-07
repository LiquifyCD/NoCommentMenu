loadstring(game:HttpGet("https://raw.githubusercontent.com/AsylumHUB/AsylumHUB-Anti-AFK/refs/heads/main/Main"))()

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local args = {
    vector.create(-685.1201171875, 1.9517230987548828, 300.91046142578125),
    2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 -- edit this value then collect the money in the pad
}
game:GetService("ReplicatedStorage"):WaitForChild("DropperEvents"):WaitForChild("CollectDrop"):FireServer(unpack(args))

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- // Settings
local _AB = false
local _UV = true
local AUTO_REBIRTH = false

local myPlot = nil
local SG = nil
local AutoBuyButton = nil
local AutoRebirthButton = nil
local rebirthCooldown = false

-- // Button touch cache
local touchedButtons = {}
local lastTouchedButton = nil

-- // Speed Settings
local MAIN_LOOP_DELAY = 0.06
local AFTER_TOUCH_DELAY = 0.2
local TOUCH_TIMEOUT = 0.35
local RELOCK_DELAY = 0.3
local NO_BUTTON_DELAY = 0.35

-- // Remove old copies before creating new GUI
for _, gui in ipairs(PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name == "LiquifyHub_Official" then
        gui:Destroy()
    end
end

-- // UI
SG = Instance.new("ScreenGui")
SG.Name = "LiquifyHub_Official"
SG.ResetOnSpawn = false
SG.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 250, 0, 390)
Main.Position = UDim2.new(0.5, -125, 0.5, -195)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = SG

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Glow = Instance.new("UIStroke")
Glow.Thickness = 2
Glow.Color = Color3.fromRGB(100, 0, 255)
Glow.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Liquid Mod Menu"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Main

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.9, 0, 0, 45)
Status.Position = UDim2.new(0.05, 0, 0, 40)
Status.BackgroundTransparency = 1
Status.Text = "Status: Idle"
Status.TextColor3 = Color3.fromRGB(180, 180, 180)
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.TextWrapped = true
Status.Parent = Main

local lastStatus = ""
local lastStatusTime = 0

local function SetStatus(text)
    if text == lastStatus and os.clock() - lastStatusTime < 1 then
        return
    end

    lastStatus = text
    lastStatusTime = os.clock()

    if Status and Status.Parent then
        Status.Text = "Status: " .. text
    end

    -- Uncomment for debugging only.
    -- print("[AutoBuy]", text)
end

-- // Side Toggle Button
local TBtn = Instance.new("TextButton")
TBtn.Size = UDim2.new(0, 45, 0, 45)
TBtn.Position = UDim2.new(1, -60, 0.5, -22)
TBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 255)
TBtn.Text = "V"
TBtn.TextColor3 = Color3.new(1, 1, 1)
TBtn.Font = Enum.Font.GothamBold
TBtn.TextSize = 18
TBtn.Parent = SG

local TBtnCorner = Instance.new("UICorner")
TBtnCorner.CornerRadius = UDim.new(1, 0)
TBtnCorner.Parent = TBtn

TBtn.MouseButton1Click:Connect(function()
    _UV = not _UV
    Main.Visible = _UV
end)

local function NewButton(text, y, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.85, 0, 0, 40)
    b.Position = UDim2.new(0.075, 0, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(220, 220, 220)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 14
    b.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = b

    b.MouseButton1Click:Connect(function()
        callback(b)
    end)

    return b
end

-- // Strict Plot Scanner
local function FindPlot()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        return nil
    end

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
    if button:GetAttribute("Bought") == true then
        return true
    end

    if button:GetAttribute("Purchased") == true then
        return true
    end

    if button:GetAttribute("IsBought") == true then
        return true
    end

    local boughtValue =
        button:FindFirstChild("Bought", true)
        or button:FindFirstChild("Purchased", true)
        or button:FindFirstChild("IsBought", true)

    if boughtValue and boughtValue:IsA("BoolValue") and boughtValue.Value == true then
        return true
    end

    return false
end

local function GetBase(button)
    local base = button:FindFirstChild("Base", true)

    if base and base:IsA("BasePart") then
        return base
    end

    for _, obj in ipairs(button:GetDescendants()) do
        if obj:IsA("BasePart") and obj.CanTouch then
            return obj
        end
    end

    return nil
end

local function IsButtonBuyable(button, plot)
    if not button or not plot then
        return false
    end

    local buttonsFolder = plot:FindFirstChild("Buttons")
    if not buttonsFolder then
        return false
    end

    -- Locks Auto Buy to your selected plot only
    if not button:IsDescendantOf(buttonsFolder) then
        return false
    end

    if not IsActuallyInWorkspace(button) then
        return false
    end

    -- Important:
    -- Once this button has been touched, ignore it until it is removed/invalidated.
    if touchedButtons[button] then
        return false
    end

    if HasBoughtMarker(button) then
        touchedButtons[button] = nil
        return false
    end

    if button:GetAttribute("Unlocked") == false then
        return false
    end

    local base = GetBase(button)
    if not base then
        return false
    end

    if not IsActuallyInWorkspace(base) then
        touchedButtons[button] = nil
        return false
    end

    if base.CanTouch == false then
        touchedButtons[button] = nil
        return false
    end

    local gui = button:FindFirstChild("BillboardGui", true)

    -- Some valid tycoon buttons are transparent.
    -- Only reject fully invisible ones if the GUI is disabled or missing.
    if base.Transparency >= 1 then
        if not gui or gui.Enabled == false then
            touchedButtons[button] = nil
            return false
        end
    end

    return true
end

-- // Faster Beam Finder
-- Searches character, PlayerGui, and locked plot only.
local function GetButtonFromGuideEffect(plot)
    if not plot then
        return nil
    end

    local buttonsFolder = plot:FindFirstChild("Buttons")
    if not buttonsFolder then
        return nil
    end

    local char = LP.Character
    if not char then
        return nil
    end

    local searchPlaces = {
        char,
        PlayerGui,
        plot
    }

    for _, place in ipairs(searchPlaces) do
        if place then
            for _, obj in ipairs(place:GetDescendants()) do
                if obj:IsA("Beam") and obj.Enabled ~= false then
                    local attachment1 = obj.Attachment1
                    local attachment0 = obj.Attachment0

                    if attachment1 and attachment1.Parent then
                        local targetPart = attachment1.Parent

                        for _, button in ipairs(buttonsFolder:GetChildren()) do
                            if targetPart:IsDescendantOf(button) and IsButtonBuyable(button, plot) then
                                return button
                            end
                        end
                    end

                    if attachment0 and attachment0.Parent then
                        local targetPart = attachment0.Parent

                        for _, button in ipairs(buttonsFolder:GetChildren()) do
                            if targetPart:IsDescendantOf(button) and IsButtonBuyable(button, plot) then
                                return button
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

-- // Fallback scanner, only inside locked plot
local function GetNextBuyableButton(plot)
    local buttonsFolder = plot and plot:FindFirstChild("Buttons")
    if not buttonsFolder then
        return nil
    end

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    local closestButton = nil
    local closestDistance = math.huge
    local checked = 0
    local valid = 0

    for _, button in ipairs(buttonsFolder:GetChildren()) do
        checked += 1

        if IsButtonBuyable(button, plot) then
            valid += 1

            local base = GetBase(button)

            if base and hrp then
                local distance = (hrp.Position - base.Position).Magnitude

                if distance < closestDistance then
                    closestDistance = distance
                    closestButton = button
                end
            elseif base then
                closestButton = button
            end
        end
    end

    if not closestButton then
        SetStatus("No valid buttons. Checked " .. checked .. ", valid " .. valid)
    end

    return closestButton
end

local function CharacterIsTouchingPart(char, part)
    if not char or not part then
        return false
    end

    for _, touchingPart in ipairs(part:GetTouchingParts()) do
        if touchingPart:IsDescendantOf(char) then
            return true
        end
    end

    return false
end

-- // Teleport and wait until character touches button
local function TeleportToButton(button, plot)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not char or not hrp then
        SetStatus("Character not ready")
        return false
    end

    local base = GetBase(button)
    if not base then
        SetStatus("Target has no BasePart")
        return false
    end

    if not IsButtonBuyable(button, plot) then
        SetStatus("Target invalid")
        return false
    end

    local touched = false
    local connection

    connection = base.Touched:Connect(function(hit)
        if hit and hit:IsDescendantOf(char) then
            touched = true
        end
    end)

    local oldCFrame = hrp.CFrame

    -- Lower offset so character actually touches the pad.
    local targetCFrame = base.CFrame + Vector3.new(0, 1.25, 0)

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    char:PivotTo(targetCFrame)

    -- Portal effect hook for later:
    -- CreatePortalEffect(oldCFrame)
    -- CreatePortalEffect(targetCFrame)

    local startTime = os.clock()

    repeat
        task.wait(0.03)

        if not _AB then
            break
        end

        if not hrp.Parent then
            break
        end

        -- Touched event can miss teleports, so also check actual overlap.
        if CharacterIsTouchingPart(char, base) then
            touched = true
            break
        end

        -- If server already bought/removed/disabled it, count as done.
        if HasBoughtMarker(button) or not IsActuallyInWorkspace(base) or base.CanTouch == false then
            touched = true
            break
        end

    until touched or os.clock() - startTime > TOUCH_TIMEOUT

    if connection then
        connection:Disconnect()
    end

    if touched then
        touchedButtons[button] = true
        lastTouchedButton = button
        SetStatus("Touched " .. button.Name .. " - waiting for next")
        return true
    end

    SetStatus("Touch timeout: " .. button.Name)
    return false
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
    if not AUTO_REBIRTH then
        return
    end

    if rebirthCooldown then
        return
    end

    rebirthCooldown = true

    SetStatus("No buttons left - trying rebirth")

    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        SetStatus("RemoteEvents folder missing")
        rebirthCooldown = false
        return
    end

    local buyRebirthEvent = remoteEvents:FindFirstChild("BuyRebirth")
    if not buyRebirthEvent then
        SetStatus("BuyRebirth remote missing")
        rebirthCooldown = false
        return
    end

    buyRebirthEvent:FireServer()
    SetStatus("Rebirth requested")

    -- Let rebirth/reset finish. Auto Buy stays ON.
    task.wait(10)

    myPlot = nil
    touchedButtons = {}
    lastTouchedButton = nil
    rebirthCooldown = false

    local args = {
        vector.create(-685.1201171875, 1.9517230987548828, 300.91046142578125),
        2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 -- edit this value then collect the money in the pad
    }
    game:GetService("ReplicatedStorage"):WaitForChild("DropperEvents"):WaitForChild("CollectDrop"):FireServer(unpack(args))
end

local function ClearOldGUIs()
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name == "LiquifyHub_Official" and gui ~= SG then
            gui:Destroy()
        end
    end
end

-- // Buttons
AutoBuyButton = NewButton("Auto Buy: OFF", 95, function(btn)
    _AB = not _AB

    if _AB then
        touchedButtons = {}
        lastTouchedButton = nil
        myPlot = FindPlot()

        if myPlot then
            btn.Text = "Auto Buy: ON"
            btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
            SetStatus("Locked plot: " .. myPlot.Name)
        else
            btn.Text = "Auto Buy: ON"
            btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
            SetStatus("Auto Buy ON - waiting for plot")
        end
    else
        myPlot = nil
        touchedButtons = {}
        lastTouchedButton = nil

        btn.Text = "Auto Buy: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        SetStatus("Idle")
    end
end)

NewButton("WalkSpeed: OFF", 145, function(btn)
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if hum then
        if hum.WalkSpeed == 16 then
            hum.WalkSpeed = 100
            btn.Text = "WalkSpeed: ON"
            btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        else
            hum.WalkSpeed = 16
            btn.Text = "WalkSpeed: OFF"
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        end
    end
end)

AutoRebirthButton = NewButton("Auto Rebirth: OFF", 195, function(btn)
    AUTO_REBIRTH = not AUTO_REBIRTH

    if AUTO_REBIRTH then
        btn.Text = "Auto Rebirth: ON"
        btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        SetStatus("Auto Rebirth enabled")
    else
        btn.Text = "Auto Rebirth: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        SetStatus("Auto Rebirth disabled")
    end
end)

NewButton("Clear Old GUIs", 245, function(btn)
    ClearOldGUIs()

    btn.Text = "Old GUIs Cleared!"
    btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)

    task.wait(1)

    btn.Text = "Clear Old GUIs"
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
end)

NewButton("Destroy GUI", 295, function()
    _AB = false
    myPlot = nil
    touchedButtons = {}
    lastTouchedButton = nil

    if SG and SG.Parent then
        SG:Destroy()
    end
end)

NewButton("Debug Scan", 345, function()
    local plot = myPlot or FindPlot()

    if not plot then
        SetStatus("Debug: no plot found")
        return
    end

    local buttonsFolder = plot:FindFirstChild("Buttons")
    if not buttonsFolder then
        SetStatus("Debug: plot has no Buttons folder")
        return
    end

    local total = 0
    local valid = 0
    local touchedCached = 0

    for _, button in ipairs(buttonsFolder:GetChildren()) do
        total += 1

        if touchedButtons[button] then
            touchedCached += 1
        end

        if IsButtonBuyable(button, plot) then
            valid += 1
            print("[Debug Valid Button]", button:GetFullName())
        end
    end

    SetStatus(
        "Debug on "
            .. plot.Name
            .. ": "
            .. valid
            .. " valid / "
            .. total
            .. " total / "
            .. touchedCached
            .. " touched"
    )
end)

-- // Optimized Auto Buy Loop
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
                SetStatus("Locked plot has no Buttons folder")
                task.wait(RELOCK_DELAY)
                continue
            end

            CleanTouchedCache()

            local button = GetButtonFromGuideEffect(myPlot) or GetNextBuyableButton(myPlot)

            if button then
                local touched = TeleportToButton(button, myPlot)

                if touched then
                    -- Button touched, so wait for tycoon/building to update
                    -- and do not spam the same touched button.
                    task.wait(AFTER_TOUCH_DELAY)
                else
                    task.wait(0.12)
                end
            else
                SetStatus("Waiting for next button")

                -- Wait for next button/building update.
                task.wait(NO_BUTTON_DELAY)

                CleanTouchedCache()

                -- Only rebirth if there are truly no button objects left.
                -- If touched buttons still exist, this waits instead of rebirthing too early.
                local count = 0
                for _, child in ipairs(buttonsFolder:GetChildren()) do
                    count += 1
                end

                if count == 0 then
                    SetStatus("No buttons left")
                    TryAutoRebirth()
                end
            end
        end
    end
end)

-- // Death Handling
local function SetupDeathHandling(character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end

    hum.Died:Connect(function()
        -- Auto Buy stays ON until clicked OFF.
        myPlot = nil
        touchedButtons = {}
        lastTouchedButton = nil
        SetStatus("Died/reset - Auto Buy still ON")
    end)
end

if LP.Character then
    SetupDeathHandling(LP.Character)
end

LP.CharacterAdded:Connect(function(character)
    task.wait(0.75)
    SetupDeathHandling(character)

    if _AB then
        local newPlot = FindPlot()

        if newPlot then
            myPlot = newPlot
            touchedButtons = {}
            lastTouchedButton = nil
            SetStatus("Respawned - re-locked plot: " .. myPlot.Name)
        else
            SetStatus("Respawned - Auto Buy ON, waiting for plot")
        end

        if AutoBuyButton then
            AutoBuyButton.Text = "Auto Buy: ON"
            AutoBuyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        end
    else
        SetStatus("Respawned - GUI kept")
    end
end)

-- // Keyboard Toggle
UIS.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.RightShift then
        _UV = not _UV

        if Main and Main.Parent then
            Main.Visible = _UV
        end
    end
end)
