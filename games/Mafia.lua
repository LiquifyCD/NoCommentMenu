--// Mafia Tools Plugin
--// No-Comment Framework Extension


local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")


local UI = shared.NoComment

while not UI or not UI.Ready do
	task.wait()
	UI = shared.NoComment
end



local LocalPlayer = Players.LocalPlayer



--==================================================
-- Lighting System
--==================================================


local LightingLock = false
local Shadows = true


local function RemoveEffects()

	for _,v in ipairs(Lighting:GetChildren()) do

		if v:IsA("ColorCorrectionEffect")
		or v:IsA("BloomEffect")
		or v:IsA("BlurEffect")
		or v:IsA("SunRaysEffect") then

			v:Destroy()

		end

	end

end



local function ApplyLighting()

	if not LightingLock then
		return
	end


	Lighting.Brightness = 5
	Lighting.ClockTime = 14
	Lighting.Ambient = Color3.fromRGB(255,255,255)
	Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
	Lighting.GlobalShadows = Shadows
	Lighting.FogEnd = 1000000
	Lighting.ExposureCompensation = 0.2


	RemoveEffects()


end



--==================================================
-- Freecam
--==================================================


local FreecamEnabled = false
local FreecamSpeed = 5


local camera = Workspace.CurrentCamera

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


	local character = LocalPlayer.Character
	local head = character and character:FindFirstChild("Head")

	if not head then
		return
	end


	FreecamEnabled = true


	cameraPart = Instance.new("Part")
	cameraPart.Name = "NoCommentFreecam"
	cameraPart.Size = Vector3.one
	cameraPart.Transparency = 1
	cameraPart.Anchored = true
	cameraPart.CanCollide = false
	cameraPart.Position = head.Position
	cameraPart.Parent = Workspace



	camera.CameraType = Enum.CameraType.Scriptable



	local _,y,_ = camera.CFrame:ToOrientation()

	yaw = y

	pitch = math.asin(
		math.clamp(
			camera.CFrame.LookVector.Y,
			-1,
			1
		)
	)



	freecamConnection = RunService.RenderStepped:Connect(function()


		if not FreecamEnabled then
			return
		end



		local rot = CFrame.fromOrientation(
			pitch,
			yaw,
			0
		)



		local dir =
			rot.LookVector * (movement.W - movement.S)
			+
			rot.RightVector * (movement.D - movement.A)
			+
			Vector3.yAxis * (movement.E - movement.Q)



		cameraPart.Position += dir * FreecamSpeed



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


	camera.CameraType = Enum.CameraType.Custom


end



UserInputService.InputBegan:Connect(function(input)


	if not FreecamEnabled then
		return
	end


	local k=input.KeyCode


	if k==Enum.KeyCode.W then movement.W=1 end
	if k==Enum.KeyCode.A then movement.A=1 end
	if k==Enum.KeyCode.S then movement.S=1 end
	if k==Enum.KeyCode.D then movement.D=1 end
	if k==Enum.KeyCode.E then movement.E=1 end
	if k==Enum.KeyCode.Q then movement.Q=1 end


end)



UserInputService.InputEnded:Connect(function(input)


	local k=input.KeyCode


	if k==Enum.KeyCode.W then movement.W=0 end
	if k==Enum.KeyCode.A then movement.A=0 end
	if k==Enum.KeyCode.S then movement.S=0 end
	if k==Enum.KeyCode.D then movement.D=0 end
	if k==Enum.KeyCode.E then movement.E=0 end
	if k==Enum.KeyCode.Q then movement.Q=0 end


end)



UserInputService.InputChanged:Connect(function(input)


	if FreecamEnabled
	and input.UserInputType == Enum.UserInputType.MouseMovement then


		yaw -= input.Delta.X * 0.0025
		pitch -= input.Delta.Y * 0.0025


	end


end)



--==================================================
-- Mafia Tracker
--==================================================


local trackerWindow
local trackerSection
local tracked = {}

local function TrackerIsAlive()
    return trackerWindow ~= nil
        and trackerWindow.Frame ~= nil
        and trackerWindow.Frame.Parent ~= nil
end

local function AddTracker(name, weapon)
    tracked[name] = weapon
    -- Only touch the live UI if the window/section actually still exists.
    -- If it's closed, the entry is still saved in `tracked` and will show
    -- up next time CreateTracker() rebuilds the list.
    if trackerSection and trackerSection.Frame and trackerSection.Frame.Parent then
        trackerSection:AddLabel(name.." - "..weapon)
    end
end

local function CreateTracker()
    if TrackerIsAlive() then
        return trackerWindow
    end

    trackerWindow = UI.CreateWindow({
        Id = "MafiaTracker",
        Title = "Mafia Tracker",
        Size = UDim2.fromOffset(400, 500),
    })

    local tab = trackerWindow:AddTab("Players")
    trackerSection = tab:AddSection("Detected Mafias")

    for name, weapon in pairs(tracked) do
        trackerSection:AddLabel(name.." - "..weapon)
    end

    return trackerWindow
end

local function OpenTracker()
    CreateTracker() -- creates if missing/closed, reuses if still alive
    trackerWindow.Frame.Visible = true
end

local function CloseTracker()
    if TrackerIsAlive() then
        trackerWindow:Close() -- destroys the Frame, clears Framework.Windows["MafiaTracker"]
    end
end



local weapons = {
	Gun=true,
	Knife=true
}



local function Watch(player,character)


	for _,obj in ipairs(character:GetChildren()) do

		if weapons[obj.Name] then

			AddTracker(
				player.Name,
				obj.Name
			)

		end

	end



	character.ChildAdded:Connect(function(obj)

		if weapons[obj.Name] then

			AddTracker(
				player.Name,
				obj.Name
			)

		end

	end)

end



local function Setup(player)

	if player.Character then
		Watch(player,player.Character)
	end


	player.CharacterAdded:Connect(function(char)

		Watch(player,char)

	end)

end



for _,p in ipairs(Players:GetPlayers()) do

	if p~=LocalPlayer then
		Setup(p)
	end

end



Players.PlayerAdded:Connect(function(p)

	if p~=LocalPlayer then
		Setup(p)
	end

end)




--==================================================
-- UI
--==================================================



local main = UI.Windows["MainMenu"]


if not main then

	main = UI.CreateWindow({

		Id="MainMenu",

		Title="No comment"

	})

end



local tab = main:AddTab("Mafia Tools")

local section = tab:AddSection("Mafia Tools")



section:AddToggle({

	Text="Lighting Lock",

	Default=false,


	Callback=function(v)

		LightingLock=v

		ApplyLighting()

	end

})



section:AddToggle({

	Text="Global Shadows",

	Default=true,


	Callback=function(v)

		Shadows=v

		ApplyLighting()

	end

})



section:AddToggle({

	Text="Freecam",

	Default=false,


	Callback=function(v)

		if v then

			EnableFreecam()

		else

			DisableFreecam()

		end

	end

})



section:AddSlider({

	Text="Freecam Speed",

	Min=1,

	Max=20,

	Default=1,


	Callback=function(v)

		FreecamSpeed=v

	end

})



section:AddButton({

	Text="Open Mafia Tracker",


	Callback=function()

		OpenTracker()

	end

})



UI.Notify({

	Title="Mafia Tools",

	Text="Loaded successfully."

})
