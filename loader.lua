local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local BASE = "https://raw.githubusercontent.com/LiquifyCD/No-Comment-Menu/main/"
local FRAMEWORK_URL = "https://raw.githubusercontent.com/LiquifyCD/No-Comment-Framework/main/Framework.lua"
local READY_TIMEOUT = 15

local player = Players.LocalPlayer

--// Helpers ------------------------------------------------------------

-- Fetch a URL with error handling
local function fetch(url)
    local ok, result = pcall(game.HttpGet, game, url)
    if not ok then
        warn("[Loader] Failed to fetch:", url, result)
        return nil
    end
    return result
end

-- Compile and run remote source, returning (success, scriptReturnValue)
local function execute(url)
    local source = fetch(url)
    if not source then return false end

    local func, err = loadstring(source)
    if not func then
        warn("[Loader] Failed to compile:", url, err)
        return false
    end

    local ok, result = pcall(func)
    if not ok then
        warn("[Loader] Runtime error in:", url, result)
        return false
    end
    return true, result
end

-- Wait for GUI elements along a path (with timeout)
local function waitForGui(...)
    local current = game:GetService("CoreGui")
    for _, name in ipairs({ ... }) do
        current = current:WaitForChild(name, READY_TIMEOUT)
        if not current then
            warn("[Loader] Timed out waiting for GUI element:", name)
            return nil
        end
    end
    return current
end

-- Wait until an attribute flags a stage as fully initialized
local function waitForReady(gui, attributeName)
    local elapsed = 0
    while not gui:GetAttribute(attributeName) do
        if elapsed >= READY_TIMEOUT then
            warn("[Loader] Timed out waiting for:", attributeName)
            return false
        end
        elapsed += task.wait(0.1)
    end
    return true
end

--// 1. Framework -------------------------------------------------------

local ok, Framework = execute(FRAMEWORK_URL)
if not ok then return end

Framework = Framework or shared.Framework
if not Framework then
    warn("[Loader] Framework did not expose an API")
    return
end

local gui = waitForGui("NoCommentGui")
if not gui then return end
if not waitForReady(gui, "FrameworkReady") then return end

--// 2. Menu ------------------------------------------------------------

if not execute(BASE .. "menu.lua") then
    Framework.Notify({
        Title = "Error",
        Text = "Failed loading menu",
    })
    return
end
if not waitForReady(gui, "MenuReady") then
    Framework.Notify({
        Title = "Error",
        Text = "Menu did not finish initializing",
    })
    return
end

--// 3. Game-specific script --------------------------------------------

local rawConfig = fetch(BASE .. "config.json")
if not rawConfig then
    Framework.Notify({
        Title = "Error",
        Text = "Failed fetching config.json",
    })
    return
end

local parsed, config = pcall(HttpService.JSONDecode, HttpService, rawConfig)
if not parsed then
    warn("[Loader] Failed to parse config.json:", config)
    Framework.Notify({
        Title = "Error",
        Text = "Failed parsing config.json",
    })
    return
end

local placeId = tostring(game.PlaceId)
local scriptPath = config.games[placeId] or config.fallback
print("[Loader] PlaceId:", placeId, "| Loading:", scriptPath)

if not execute(BASE .. scriptPath) then
    Framework.Notify({
        Title = "Error",
        Text = "Failed loading " .. tostring(scriptPath),
    })
    return
end

Framework.Notify({
    Title = "No-Comment",
    Text = "Loaded successfully",
})
