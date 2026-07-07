local HttpService = game:GetService("HttpService")

local BASE = "https://raw.githubusercontent.com/LiquifyCD/NoCommentMenu/main/"

-- Get config
local config = HttpService:JSONDecode(game:HttpGet(BASE .. "config.json"))

-- Use Experience ID (or change to PlaceId if you prefer)
local id = tostring(game.GameId)

-- Get the correct script
local path = config.games[id] or config.fallback

print("[NoCommentMenu] Loading:", path)

-- Download and run it
local source = game:HttpGet(BASE .. path)
loadstring(source)()
