local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer
local Framework = shared.Framework

local MainMenu = Framework.CreateWindow({
	Id = "MainMenu",
	Title = "No comment",
	Size = UDim2.fromOffset(720, 480),
})

if #MainMenu.Tabs == 0 then

	local tab = win:AddTab("Home")
local section = tab:AddSection("Main Section")
	
  local General = win:AddTab("General")
    local Visual = win:AddTab("Visual")
    local PlayerTab = win:AddTab("Player")   -- was shadowing Visual
    local External = win:AddTab("External")

    local externalSection = External:AddSection("Scripts")
	local generalSection = External:AddSection("Functions")
	local playerSection = External:AddSection("Movement")

	externalSection:AddButton({
		Text = "Dark Dex V4",
		Callback = function()
        
			Framework.Notify({
				Title = "Dark Dex V4",
				Text = "Initializing Explorer",
			})

      local func, err = loadstring(game:HttpGet("https://raw.githubusercontent.com/LiquifyCD/No-Comment-Menu/main/scripts/DarkDexV4.lua"))()

      if not func then
            Framework.Notify({
              Title = "Error",
              Text = "Failed initializing Explorer",
            })
          return
      end
        
		end,
	})

  externalSection:AddButton({
		Text = "Remote Spy",
		Callback = function()
        
			Framework.Notify({
				Title = "Remote Spy",
				Text = "Initializing Remote Spy",
			})

      local func, err = loadstring(game:HttpGet("https://raw.githubusercontent.com/LiquifyCD/No-Comment-Menu/main/scripts/RemoteSpy.lua"))()

      if not func then
            Framework.Notify({
              Title = "Error",
              Text = "Failed initializing Remote Spy",
            })
          return
      end
        
		end,
	})

	--Anti AFK
	local antiAfkConnection = nil
	
	local function enableAntiAFK()
	    if antiAfkConnection then return end
	
	    local ok, err = pcall(function()
	        antiAfkConnection = player.Idled:Connect(function()
	            VirtualUser:CaptureController()
	            VirtualUser:ClickButton2(Vector2.new(0, 0))
	        end)
	    end)
	
	    if not ok then
	        Framework.Notify({
	            Title = "Error",
	            Text = "Failed initializing Anti-AFK: " .. tostring(err),
	        })
	        return
	    end
	
	    Framework.Notify({
	        Title = "Anti-AFK",
	        Text = "Anti-AFK enabled",
	    })
	end
	
	local function disableAntiAFK()
	    if antiAfkConnection then
	        antiAfkConnection:Disconnect()
	        antiAfkConnection = nil
	    end
	
	    Framework.Notify({
	        Title = "Anti-AFK",
	        Text = "Anti-AFK disabled",
	    })
	end
	
	generalSection:AddToggle({
	    Text = "Anti-AFK",
	    Default = true,
	    Callback = function(value)
	        if value then
	            enableAntiAFK()
	        else
	            disableAntiAFK()
	        end
	    end,
	})


	playerSection:AddSlider({
		Text = "Walkspeed",
		Min = 0,
		Max = 100,
		Default = 16,
		Step = 1,
		Callback = function(value)
			local player = game:GetService("Players").LocalPlayer

      if player.Character and player.Character:FindFirstChild("Humanoid") then
          player.Character.Humanoid.WalkSpeed = value
      end
        
		end,
	})


end

player.PlayerGui.NoCommentGui:SetAttribute("MenuReady", true)
