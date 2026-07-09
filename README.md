# NoCommentMenu

A modular Roblox script loader that automatically loads the correct game-specific script based on the current Roblox PlaceId.

NoCommentMenu uses a single loader system that checks a configuration file, detects the current game, and loads the appropriate script from the repository. This allows individual game scripts to be updated independently without changing the main loader.

## Features

- Remote loading through GitHub
- Automatic game detection using PlaceId
- Separate scripts for different games
- Configuration-based script routing
- Fallback support for unsupported games
- Easy updates without modifying the loader
- Modular structure for adding new games

## Repository Structure

```
NoCommentMenu/
│
├── loader.lua
├── config.json
│
└── games/
    ├── Mafia.lua
    ├── PrisonLife.lua
    └── fallback.lua
```

## Usage

Run the loader using:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/LiquifyCD/NoCommentMenu/main/loader.lua"))()
```

The loader will:

1. Download the configuration file
2. Detect the current Roblox PlaceId
3. Find the matching game script
4. Download and execute the selected script

## Configuration

The `config.json` file controls which script is loaded for each game.

Example:

```json
{
    "games": {
        "113232329524315": "games/Mafia.lua",
        "83705601973004": "games/Mafia.lua",
        "155615604": "games/PrisonLife.lua"
    },
    "fallback": "games/fallback.lua"
}
```

Each key represents a Roblox PlaceId and each value represents the script that should be loaded.

## Adding Support For A New Game

1. Create a new script inside the `games` folder.

Example:

```
games/NewGame.lua
```

2. Add the game's PlaceId to `config.json`.

Example:

```json
{
    "123456789": "games/NewGame.lua"
}
```

3. The loader will automatically detect the game and load the new script.

## Creating Game Scripts

Each game has its own Lua file.

Example:

```lua
print("Loaded NewGame")

-- Game-specific code goes here
```

The loader only handles selecting and loading the correct file. All game-specific functionality should be placed inside the corresponding game script.

## Debugging

To find the current Roblox identifiers, run:

```lua
print("PlaceId:", game.PlaceId)
print("GameId:", game.GameId)
```

Use the `PlaceId` value when adding games to `config.json`.

## Supported Games

| Game | Status |
|------|--------|
| Mafia | Supported |
| Prison Life | Supported |
| Kohl's Admin House | Supported |
| Age Evolution Tycoon | Supported |

More games can be added by creating new scripts and updating the configuration.

## Contributing

To add support for a new game:

1. Create a new script in the `games` folder
2. Add the PlaceId and script path to `config.json`
3. Submit a pull request

## Disclaimer

This project is provided for educational purposes. Users are responsible for how they use this project and should respect Roblox's Terms of Service and individual game rules.

## License

This project is open source. See the repository license for more information.
