local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local MainMenu = Framework.CreateWindow({
	Id = "MainMenu",
	Title = "No comment",
	Size = UDim2.fromOffset(720, 480),
})

if #MainMenu.Tabs == 0 then
	local General = MainMenu:AddTab("General")
  local Visual = MainMenu:AddTab("Visual")
  local Visual = MainMenu:AddTab("Player")
  local External = MainMenu:AddTab("External")

	External:AddButton({
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

  External:AddButton({
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

	intro:AddToggle({
		Text = "Example toggle",
		Default = true,
		Callback = function(value)
			print("Toggle:", value)
		end,
	})

	Player:AddSlider({
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
