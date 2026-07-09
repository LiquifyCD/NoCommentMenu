local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

loadstring(game:HttpGet("https://raw.githubusercontent.com/LiquifyCD/No-Comment-Framework/main/Framework.lua"))()

local BASE = "https://raw.githubusercontent.com/LiquifyCD/No-Comment-Menu/main/"

local config = HttpService:JSONDecode(game:HttpGet(BASE .. "config.json"))

local placeId = tostring(game.PlaceId)

print("Current PlaceId:", placeId)

local scriptPath = config.games[placeId] or config.fallback

print("Loading:", scriptPath)

-- Wait for the framework GUI to be fully created
local player = Players.LocalPlayer
player:WaitForChild("PlayerGui")
    :WaitForChild("NoCommentGui")
    :WaitForChild("Root")
    :WaitForChild("Window_MainMenu")

print("Framework loaded, running game script...")

local source = game:HttpGet(BASE .. scriptPath)

local func, err = loadstring(source)

if not func then
    warn("Failed to compile script:", err)
    return
end

func()
