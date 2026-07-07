local HttpService = game:GetService("HttpService")

local BASE = "https://raw.githubusercontent.com/LiquifyCD/NoCommentMenu/main/"

local config = HttpService:JSONDecode(game:HttpGet(BASE .. "config.json"))

local placeId = tostring(game.PlaceId)

print("Current PlaceId:", placeId)

local scriptPath = config.games[placeId] or config.fallback

print("Loading:", scriptPath)

local source = game:HttpGet(BASE .. scriptPath)

local func, err = loadstring(source)

if not func then
    warn("Failed to compile script:", err)
    return
end

func()
