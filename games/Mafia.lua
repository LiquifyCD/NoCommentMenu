--// SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local player = LocalPlayer
local camera = Workspace.CurrentCamera

--// LIGHTING LOCK SYSTEM
local globalShadowsEnabled = true
local applyingLighting = false

local function RemoveEffects()
	for _, effect in ipairs(Lighting:GetChildren()) do
		if effect:IsA("ColorCorrectionEffect")
		or effect:IsA("BloomEffect")
		or effect:IsA("BlurEffect")
		or effect:IsA("SunRaysEffect") then
			effect:Destroy()
		end
	end
end

local function FixAtmosphere()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = 0
		atmosphere.Haze = 0
		atmosphere.Glare = 0
	end
end

local function ApplyLighting()
	if applyingLighting then return end
	applyingLighting = true
	Lighting.Brightness = 5
	Lighting.ClockTime = 14
	Lighting.Ambient = Color3.fromRGB(255,255,255)
	Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
	Lighting.GlobalShadows = globalShadowsEnabled
	Lighting.FogEnd = 1000000
	Lighting.ExposureCompensation = 0.2
	FixAtmosphere()
	RemoveEffects()
	task.defer(function() applyingLighting = false end)
end

ApplyLighting()

for _,property in ipairs({
	"Brightness","ClockTime","Ambient","OutdoorAmbient",
	"GlobalShadows","FogEnd","ExposureCompensation"
}) do
	Lighting:GetPropertyChangedSignal(property):Connect(ApplyLighting)
end

local function HookAtmosphere(atmosphere)
	local function changed() ApplyLighting() end
	atmosphere:GetPropertyChangedSignal("Density"):Connect(changed)
	atmosphere:GetPropertyChangedSignal("Haze"):Connect(changed)
	atmosphere:GetPropertyChangedSignal("Glare"):Connect(changed)
end

local atm=Lighting:FindFirstChildOfClass("Atmosphere")
if atm then HookAtmosphere(atm) end

Lighting.ChildAdded:Connect(function(child)
	if child:IsA("Atmosphere") then
		HookAtmosphere(child)
		task.defer(ApplyLighting)
	elseif child:IsA("ColorCorrectionEffect")
	or child:IsA("BloomEffect")
	or child:IsA("BlurEffect")
	or child:IsA("SunRaysEffect") then
		child:Destroy()
		task.defer(ApplyLighting)
	end
end)

Lighting.ChildRemoved:Connect(function()
	task.defer(ApplyLighting)
end)

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MafiaTracker"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 300)
frame.Position = UDim2.new(0, 20, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "Mafias"
title.TextColor3 = Color3.fromRGB(255,0,0)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

--// SHADOW TOGGLE BUTTON
local shadowButton = Instance.new("TextButton")
shadowButton.Size = UDim2.new(1, -10, 0, 30)
shadowButton.Position = UDim2.new(0, 5, 0, 45)
shadowButton.BackgroundColor3 = Color3.fromRGB(40,40,40)
shadowButton.BorderSizePixel = 0
shadowButton.TextColor3 = Color3.new(1,1,1)
shadowButton.TextScaled = true
shadowButton.Font = Enum.Font.Gotham
shadowButton.Parent = frame

local function UpdateShadowText()
	shadowButton.Text = "Global Shadows: " .. (globalShadowsEnabled and "ON" or "OFF")
end

UpdateShadowText()

shadowButton.MouseButton1Click:Connect(function()
	globalShadowsEnabled = not globalShadowsEnabled
	UpdateShadowText()
	ApplyLighting()
end)

--// LIST FRAME
local listFrame = Instance.new("Frame")
listFrame.Position = UDim2.new(0, 0, 0, 80)
listFrame.Size = UDim2.new(1, 0, 1, -80)
listFrame.BackgroundTransparency = 1
listFrame.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Parent = listFrame
layout.Padding = UDim.new(0, 5)

--// PLAYER TRACKING STORAGE
local addedPlayers = {}

local function isWeapon(name)
	return name == "Gun" or name == "Knife"
end

local function addToGUI(characterName)
	if addedPlayers[characterName] then return end
	addedPlayers[characterName] = true

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 0, 30)
	label.BackgroundColor3 = Color3.fromRGB(40,40,40)
	label.TextColor3 = Color3.new(1,1,1)
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.Text = characterName
	label.Parent = listFrame
end

local function watchCharacter(plr, character)
	for _, obj in ipairs(character:GetChildren()) do
		if isWeapon(obj.Name) then
			addToGUI(character.Name)
		end
	end

	character.ChildAdded:Connect(function(obj)
		if isWeapon(obj.Name) then
			addToGUI(character.Name)
		end
	end)
end

local function setupPlayer(plr)
	if plr.Character then
		watchCharacter(plr, plr.Character)
	end

	plr.CharacterAdded:Connect(function(char)
		watchCharacter(plr, char)
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer then
		setupPlayer(plr)
	end
end

Players.PlayerAdded:Connect(function(plr)
	if plr ~= LocalPlayer then
		setupPlayer(plr)
	end
end)

local TOGGLE_KEY = Enum.KeyCode.H
local ROTATE_MOUSE_BUTTON = Enum.UserInputType.MouseButton2

local NORMAL_SPEED = 2
local FAST_SPEED = 5
local SMOOTHNESS = 0.18
local MOUSE_SENSITIVITY = 0.0025

local enabled = false
local cameraPart = nil
local renderConnection = nil

local moveState = {
	forward = 0,
	back = 0,
	left = 0,
	right = 0,
	up = 0,
	down = 0,
	fast = false,
}

local yaw = 0
local pitch = 0
local rotating = false
local currentVelocity = Vector3.zero

local savedCameraType
local savedCameraSubject

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getHeadAndHumanoid()
	local character = getCharacter()
	return character:FindFirstChild("Head"),
		   character:FindFirstChildWhichIsA("Humanoid")
end

local function createCameraPart(pos)
	local part = Instance.new("Part")
	part.Name = "LocalFreecamPart"
	part.Size = Vector3.new(1,1,1)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.CFrame = CFrame.new(pos)
	part.Parent = Workspace
	return part
end

local function resetMovement()
	for k in pairs(moveState) do
		moveState[k] = (typeof(moveState[k]) == "boolean") and false or 0
	end
	currentVelocity = Vector3.zero
end

local function enableFreecam()
	if enabled then return end

	local head, humanoid = getHeadAndHumanoid()
	if not head then return end

	enabled = true
	resetMovement()

	savedCameraType = camera.CameraType
	savedCameraSubject = camera.CameraSubject

	cameraPart = createCameraPart(head.Position)

	local cf = camera.CFrame
	local _, y, _ = cf:ToOrientation()
	yaw = y
	pitch = math.asin(math.clamp(cf.LookVector.Y, -1, 1))

	camera.CameraType = Enum.CameraType.Scriptable

	renderConnection = RunService.RenderStepped:Connect(function()
		if not enabled then return end

		local rot = CFrame.fromOrientation(pitch, yaw, 0)
		local dir = rot.LookVector * (moveState.forward - moveState.back)
			+ rot.RightVector * (moveState.right - moveState.left)
			+ Vector3.yAxis * (moveState.up - moveState.down)

		if dir.Magnitude > 1 then dir = dir.Unit end

		local speed = moveState.fast and FAST_SPEED or NORMAL_SPEED
		currentVelocity = currentVelocity:Lerp(dir * speed, SMOOTHNESS)

		cameraPart.Position += currentVelocity
		camera.CFrame = CFrame.new(cameraPart.Position) * rot
	end)
end

local function disableFreecam()
	if not enabled then return end

	enabled = false
	if renderConnection then renderConnection:Disconnect() end
	if cameraPart then cameraPart:Destroy() end

	camera.CameraType = savedCameraType or Enum.CameraType.Custom
	camera.CameraSubject = savedCameraSubject
end

local function toggleFreecam()
	if enabled then disableFreecam() else enableFreecam() end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == TOGGLE_KEY then
		toggleFreecam()
		return
	end

	if not enabled then return end

	if input.UserInputType == ROTATE_MOUSE_BUTTON then
		rotating = true
	end

	if input.KeyCode == Enum.KeyCode.W then moveState.forward = 1 end
	if input.KeyCode == Enum.KeyCode.S then moveState.back = 1 end
	if input.KeyCode == Enum.KeyCode.A then moveState.left = 1 end
	if input.KeyCode == Enum.KeyCode.D then moveState.right = 1 end
	if input.KeyCode == Enum.KeyCode.E then moveState.up = 1 end
	if input.KeyCode == Enum.KeyCode.Q then moveState.down = 1 end
	if input.KeyCode == Enum.KeyCode.LeftShift then moveState.fast = true end
end)

UserInputService.InputEnded:Connect(function(input)
	if not enabled then return end

	if input.UserInputType == ROTATE_MOUSE_BUTTON then
		rotating = false
	end

	if input.KeyCode == Enum.KeyCode.W then moveState.forward = 0 end
	if input.KeyCode == Enum.KeyCode.S then moveState.back = 0 end
	if input.KeyCode == Enum.KeyCode.A then moveState.left = 0 end
	if input.KeyCode == Enum.KeyCode.D then moveState.right = 0 end
	if input.KeyCode == Enum.KeyCode.E then moveState.up = 0 end
	if input.KeyCode == Enum.KeyCode.Q then moveState.down = 0 end
	if input.KeyCode == Enum.KeyCode.LeftShift then moveState.fast = false end
end)

UserInputService.InputChanged:Connect(function(input)
	if not enabled or not rotating then return end

	if input.UserInputType == Enum.UserInputType.MouseMovement then
		yaw -= input.Delta.X * MOUSE_SENSITIVITY
		pitch -= input.Delta.Y * MOUSE_SENSITIVITY
		pitch = math.clamp(pitch, math.rad(-89), math.rad(89))
	end
end)

player.CharacterAdded:Connect(function()
	if enabled then
		task.wait(0.2)
		disableFreecam()
	end
end)