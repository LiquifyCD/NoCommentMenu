--// Mafia Tools Plugin
--// No-Comment Framework Extension

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("GameFlowLogRemote")


local UI = shared.NoComment

while not UI or not UI.Ready do
	task.wait()
	UI = shared.NoComment
end


local LocalPlayer = Players.LocalPlayer
local player = LocalPlayer
local camera = Workspace.CurrentCamera

--==================================================
-- PHASE SYSTEM
--==================================================

local validPhases = {
	Discussion = true,
	Voting = true,
	Night = true,
	Day = true,
}

local currentPhase

local function getCurrentPhase()
	return currentPhase
end

local function findPhase(value, visited)
	if typeof(value) == "string" then
		if validPhases[value] then
			return value
		end

		for phase in validPhases do
			if string.find(value, phase, 1, true) then
				return phase
			end
		end

		return nil
	end

	if typeof(value) ~= "table" then
		return nil
	end

	visited = visited or {}

	if visited[value] then
		return nil
	end

	visited[value] = true

	for key, nestedValue in value do
		local phase = findPhase(key, visited)
			or findPhase(nestedValue, visited)

		if phase then
			return phase
		end
	end

	return nil
end

remote.OnClientEvent:Connect(function(...)
	local arguments = table.pack(...)

	for index = 1, arguments.n do
		local phase = findPhase(arguments[index])

		if phase then
			currentPhase = phase
			return
		end
	end
end)

--==================================================
-- LIGHTING LOCK SYSTEM
--==================================================


local LightingLock = false
local GlobalShadows = true
local applyingLighting = false


local lightingConnections = {}
local atmosphereConnections = {}



local function RemoveEffects()

	for _,effect in ipairs(Lighting:GetChildren()) do

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

	if not LightingLock then
		return
	end


	if applyingLighting then
		return
	end


	applyingLighting = true


	Lighting.Brightness = 5
	Lighting.ClockTime = 14
	Lighting.Ambient = Color3.fromRGB(255,255,255)
	Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
	Lighting.GlobalShadows = GlobalShadows
	Lighting.FogEnd = 1000000
	Lighting.ExposureCompensation = 0.2


	FixAtmosphere()
	RemoveEffects()


	task.defer(function()

		applyingLighting = false

	end)

end



local function DisconnectLighting()

	for _,connection in ipairs(lightingConnections) do

		connection:Disconnect()

	end


	table.clear(lightingConnections)


	for _,connection in ipairs(atmosphereConnections) do

		connection:Disconnect()

	end


	table.clear(atmosphereConnections)

end



local function HookAtmosphere()

	local atmosphere =
		Lighting:FindFirstChildOfClass("Atmosphere")


	if not atmosphere then
		return
	end



	table.insert(

		atmosphereConnections,

		atmosphere:GetPropertyChangedSignal(
			"Density"
		):Connect(ApplyLighting)

	)


	table.insert(

		atmosphereConnections,

		atmosphere:GetPropertyChangedSignal(
			"Haze"
		):Connect(ApplyLighting)

	)


	table.insert(

		atmosphereConnections,

		atmosphere:GetPropertyChangedSignal(
			"Glare"
		):Connect(ApplyLighting)

	)


end



local function EnableLightingLock()


	if LightingLock then
		return
	end


	LightingLock = true



	for _,property in ipairs({

		"Brightness",
		"ClockTime",
		"Ambient",
		"OutdoorAmbient",
		"GlobalShadows",
		"FogEnd",
		"ExposureCompensation"

	}) do


		table.insert(

			lightingConnections,

			Lighting:GetPropertyChangedSignal(property)
			:Connect(ApplyLighting)

		)


	end



	HookAtmosphere()



	Lighting.ChildAdded:Connect(function(child)


		if not LightingLock then
			return
		end


		if child:IsA("Atmosphere") then

			HookAtmosphere()
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

		if LightingLock then

			task.defer(ApplyLighting)

		end

	end)



	ApplyLighting()

end




local function DisableLightingLock()


	LightingLock = false

	DisconnectLighting()

end




--==================================================
-- FREECAM
--==================================================


local FreecamEnabled = false
local FreecamSpeed = 5


local cameraPart
local freecamConnection


local yaw = 0
local pitch = 0



local movement = {

	W = 0,
	A = 0,
	S = 0,
	D = 0,
	E = 0,
	Q = 0

}



local function EnableFreecam()


	if FreecamEnabled then
		return
	end



	local character =
		player.Character or player.CharacterAdded:Wait()


	local head =
		character:FindFirstChild("Head")


	if not head then
		return
	end



	FreecamEnabled = true



	cameraPart = Instance.new("Part")

	cameraPart.Name = "NoCommentFreecam"

	cameraPart.Size = Vector3.one

	cameraPart.Anchored = true

	cameraPart.CanCollide = false

	cameraPart.Transparency = 1

	cameraPart.Position = head.Position

	cameraPart.Parent = Workspace



	camera.CameraType =
		Enum.CameraType.Scriptable



	local _,y,_ =
		camera.CFrame:ToOrientation()


	yaw = y


	pitch =
		math.asin(
			math.clamp(
				camera.CFrame.LookVector.Y,
				-1,
				1
			)
		)



	freecamConnection =
		RunService.RenderStepped:Connect(function()


			if not FreecamEnabled then
				return
			end



			local rot =
				CFrame.fromOrientation(
					pitch,
					yaw,
					0
				)



			local direction =
				rot.LookVector *
				(movement.W - movement.S)
				+
				rot.RightVector *
				(movement.D - movement.A)
				+
				Vector3.yAxis *
				(movement.E - movement.Q)



			cameraPart.Position +=
				direction * FreecamSpeed



			camera.CFrame =
				CFrame.new(cameraPart.Position)
				*
				rot


		end)

end



local function DisableFreecam()


	FreecamEnabled = false


	if freecamConnection then

		freecamConnection:Disconnect()

		freecamConnection=nil

	end



	if cameraPart then

		cameraPart:Destroy()

		cameraPart=nil

	end



	camera.CameraType =
		Enum.CameraType.Custom


end

--==================================================
-- FREECAM INPUT
--==================================================


UserInputService.InputBegan:Connect(function(input)

	if not FreecamEnabled then
		return
	end


	local key = input.KeyCode


	if key == Enum.KeyCode.W then movement.W = 1 end
	if key == Enum.KeyCode.A then movement.A = 1 end
	if key == Enum.KeyCode.S then movement.S = 1 end
	if key == Enum.KeyCode.D then movement.D = 1 end
	if key == Enum.KeyCode.E then movement.E = 1 end
	if key == Enum.KeyCode.Q then movement.Q = 1 end

end)



UserInputService.InputEnded:Connect(function(input)


	local key = input.KeyCode


	if key == Enum.KeyCode.W then movement.W = 0 end
	if key == Enum.KeyCode.A then movement.A = 0 end
	if key == Enum.KeyCode.S then movement.S = 0 end
	if key == Enum.KeyCode.D then movement.D = 0 end
	if key == Enum.KeyCode.E then movement.E = 0 end
	if key == Enum.KeyCode.Q then movement.Q = 0 end

end)



UserInputService.InputChanged:Connect(function(input)

	if not FreecamEnabled then
		return
	end


	if input.UserInputType ==
		Enum.UserInputType.MouseMovement then


		yaw -= input.Delta.X * 0.0025

		pitch -= input.Delta.Y * 0.0025


		pitch = math.clamp(
			pitch,
			math.rad(-89),
			math.rad(89)
		)

	end

end)



player.CharacterAdded:Connect(function()

	if FreecamEnabled then

		task.wait(0.2)

		DisableFreecam()

	end

end)



--==================================================
-- Green Eyes Fake Out
--==================================================

local VirtualInputManager = game:GetService("VirtualInputManager")

local GreenEyesFakeOut = false

local function TriggerGreenEyesFakeOut()
	if not GreenEyesFakeOut then
		return
	end

	-- Simulate pressing Q
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
	task.wait(0.05)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
end


--==================================================
-- MAFIA TRACKER
--==================================================


local trackerWindow
local trackerSection


local detectedCharacters = {}



local weapons = {

	Gun = true,

	Knife = true

}



local function AddTracker(characterName, weapon)


	-- Prevent duplicates
	if detectedCharacters[characterName] then

		return

	end



	detectedCharacters[characterName] = weapon



	if trackerSection then

		if getCurrentPhase() == "Discussion" then
			trackerSection:AddLabel(
				"(Vigilante) " .. characterName
			)

		else

			trackerSection:AddLabel(
				"(Mafia) " .. characterName .. " - " .. weapon
			)
			
		end

	end



	UI.Notify({

		Title = "Weapon Detected",

		Text = characterName ..
			" has a " ..
			weapon,

		Duration = 4

	})


end



local function CreateTrackerWindow()


	if trackerWindow then

		return

	end



	trackerWindow = UI.CreateWindow({

		Id = "RolesTracker",

		Title = "Roles Tracker",

		Size = UDim2.fromOffset(
			400,
			500
		)

	})



	local tab =
		trackerWindow:AddTab(
			"Players"
		)



	trackerSection =
		tab:AddSection(
			"Detected Roles"
		)



	for name,weapon in pairs(detectedCharacters) do

		if getCurrentPhase() == "Discussion" then
			trackerSection:AddLabel(
				"(Vigilante) " .. name
			)

		else

			trackerSection:AddLabel(
				"(Mafia) " .. name .. " - " .. weapon
			)
			
		end

	end

end



local function OpenTracker()


	-- Recreate if closed/destroyed
	if not trackerWindow
	or not trackerWindow.Frame
	or not trackerWindow.Frame.Parent then


		trackerWindow = nil

		trackerSection = nil


		CreateTrackerWindow()


	end



	if trackerWindow.Frame then

		trackerWindow.Frame.Visible = true

	end

end




local function WatchCharacter(player, character)


	local function CheckObject(obj)


		if weapons[obj.Name] then


			AddTracker(

				character.Name,

				obj.Name

			)

			TriggerGreenEyesFakeOut()


		end

	end



	for _,obj in ipairs(character:GetChildren()) do

		CheckObject(obj)

	end



	character.ChildAdded:Connect(function(obj)

		CheckObject(obj)

	end)

end



local function SetupPlayer(player)


	if player.Character then

		WatchCharacter(
			player,
			player.Character
		)

	end



	player.CharacterAdded:Connect(function(character)

		WatchCharacter(
			player,
			character
		)

	end)

end



for _,plr in ipairs(Players:GetPlayers()) do

	if plr ~= LocalPlayer then

		SetupPlayer(plr)

	end

end



Players.PlayerAdded:Connect(function(plr)


	if plr ~= LocalPlayer then

		SetupPlayer(plr)

	end

end)

--==================================================
-- NO COMMENT UI
--==================================================


local main =
	UI.Windows["MainMenu"]



if not main then


	main =
		UI.CreateWindow({

			Id = "MainMenu",

			Title = "No comment"

		})


end



local tab =
	main:AddTab(
		"Mafia Tools"
	)



local section =
	tab:AddSection(
		"Mafia Tools"
	)



section:AddToggle({

	Text = "Lighting Lock",

	Default = false,


	Callback = function(value)


		if value then

			EnableLightingLock()

		else

			DisableLightingLock()

		end


	end

})



section:AddToggle({

	Text = "Global Shadows",

	Default = true,


	Callback = function(value)


		GlobalShadows = value


		if LightingLock then

			ApplyLighting()

		end


	end

})



section:AddToggle({

	Text = "Freecam",

	Default = false,


	Callback = function(value)


		if value then

			EnableFreecam()

		else

			DisableFreecam()

		end


	end

})



section:AddSlider({

	Text = "Freecam Speed",

	Min = 1,

	Max = 20,

	Default = 5,


	Callback = function(value)

		FreecamSpeed = value

	end

})



section:AddToggle({
	Text = "Green Eyes Fake-Out",
	Default = false,

	Callback = function(value)
		GreenEyesFakeOut = value
	end
})



section:AddButton({

	Text = "Open Roles Tracker",


	Callback = function()

		OpenTracker()

	end

})



UI.Notify({

	Title = "Mafia Tools",

	Text = "Loaded successfully.",

	Duration = 3

})

loadstring(game:HttpGet("https://raw.githubusercontent.com/LiquifyCD/No-Comment-Menu/main/scripts/plugins/CursorDot.lua"))()
