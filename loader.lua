local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local BASE = "https://raw.githubusercontent.com/LiquifyCD/No-Comment-Menu/main/"
local FRAMEWORK_URL = "https://raw.githubusercontent.com/LiquifyCD/No-Comment-Framework/main/Framework.lua"

local player = Players.LocalPlayer

-- Fetch a URL with error handling
local function fetch(url)
    local ok, result = pcall(game.HttpGet, game, url)
    if not ok then
        warn("Failed to fetch:", url, result)
        return nil
    end
    return result
end

-- Compile and run remote source with error handling
local function execute(url)
    local source = fetch(url)
    if not source then return false end

    local func, err = loadstring(source)
    if not func then
        warn("Failed to compile:", url, err)
        return false
    end

    local ok, runErr = pcall(func)
    if not ok then
        warn("Runtime error in:", url, runErr)
        return false
    end
    return true
end

-- Wait for GUI elements along a path
local function waitForGui(...)
    local current = player:WaitForChild("PlayerGui")
    for _, name in ipairs({ ... }) do
        current = current:WaitForChild(name)
    end
    return current
end

-- 1. Load framework
if not execute(FRAMEWORK_URL) then return end
waitForGui("NoCommentGui", "Root")

-- 2. Load menu
if not execute(BASE .. "menu.lua") then return end
waitForGui("NoCommentGui", "Root", "Window_MainMenu")

-- 3. Load game-specific script from config
local rawConfig = fetch(BASE .. "config.json")
if not rawConfig then return end

local ok, config = pcall(HttpService.JSONDecode, HttpService, rawConfig)
if not ok then
    warn("Failed to parse config.json:", config)
    return
end

local placeId = tostring(game.PlaceId)
local scriptPath = config.games[placeId] or config.fallback
print("PlaceId:", placeId, "| Loading:", scriptPath)

execute(BASE .. scriptPath)
