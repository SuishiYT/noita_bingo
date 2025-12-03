# Noita Bingo Mod

A comprehensive bingo mod for Noita featuring solo and multiplayer modes, customizable objectives, and flexible UI positioning.

## Installation

1. Copy the entire mod folder to your Noita mods directory: `Noita/mods/Noita Bingo/`
2. Enable the mod in Noita's mod menu
3. Launch a new game

## Features

### Game Modes
- **Solo Mode**
  - Traditional Bingo: Get 5 in a row (horizontal, vertical, or diagonal)
  - Blackout: Complete all squares
  - Rush: Race against the clock
  
- **Multiplayer Mode**
  - Traditional Bingo: First to get 5 in a row wins
  - Lockout: Compete for squares - once claimed, others can't claim it

### UI Controls

#### Hotkeys (Default)
- F6: Full Screen mode
- F7: Large board
- F8: Small board
- F9: Toggle Hidden/Show

#### Display Modes
- **Full Screen**: Fills entire vertical space of game window
- **Large**: Freely positionable/resizable board (400x400 default)
- **Small**: Smaller freely positionable/resizable board (250x250 default)
  - Single-click anywhere on small board to expand to Large
- **Hidden**: Collapses to small "BINGO" button on screen edge

#### Interaction
- Click any objective square to mark it as completed (green)
- Use buttons above board to switch display modes
- Drag boards to reposition (Large/Small modes)
- Board positions auto-save every 5 seconds

### Customization

#### Custom Objectives
Edit `objectives/custom.lua` to add your own objectives. Example:
```lua
{
    id = "my_objective_01",
    title = "Your Objective Title",
    category = "combat", -- luck, combat, exploration, magic, items, general
    difficulty = "medium" -- easy, medium, hard
}
```

#### Category Weights & Limits
Edit `config/settings.lua` to adjust which objective types appear more often:

```lua
category_weights = {
    luck = 0.5,        -- Half as likely
    combat = 2.0,      -- Twice as likely
    exploration = 1.0, -- Normal
}

category_limits = {
    luck = 2,          -- Maximum 2 luck objectives
    combat = nil,      -- No limit
}
```

See `objectives/PRESETS.lua` for example configurations.

#### Objective Rewards
Edit reward mappings in `src/config/rewards.lua` to customize what you receive for completing objectives.

### Settings

The `config/settings.lua` file controls:
- Default display mode
- Board coupling behavior (separate vs. shared positions for Large/Small)
- Hotkey bindings
- Category weights and limits
- Animation settings

## Multiplayer

**IMPORTANT**: Noita does not have built-in multiplayer support. For multiplayer functionality, you'll need one of these options:

### Option 1: Noita Together (Recommended)
- Use the "Noita Together" mod (search Steam Workshop)
- This mod is designed to work alongside multiplayer mods
- Host's objective configuration and board will sync to all players
- Board state synchronizes automatically

### Option 2: Manual Coordination
- All players install the mod with identical objective lists
- Use same seed for board generation
- Manually share which squares are completed (honor system)
- Good for casual play with friends

### Option 3: Custom Network Implementation
- The mod includes a network framework (`src/multiplayer/network.lua`)
- Implement your own networking using:
  - WebSocket libraries
  - Socket.lua
  - HTTP polling
- Note: Requires programming knowledge and external server

### Host Authority Model
In multiplayer mode, the host's files are used for:
- Board generation (objective list)
- Reward configuration
- Game settings

This allows custom objectives/rewards without requiring all players to sync config files.

## File Structure

```
Noita Bingo/
├── init.lua                    # Main mod entry point
├── mod.xml                     # Mod metadata
├── config/
│   └── settings.lua           # User settings
├── objectives/
│   ├── custom.lua             # Your custom objectives
│   └── PRESETS.lua            # Example configurations
└── src/
    ├── config/
    │   ├── objectives.lua     # Default objectives
    │   ├── rewards.lua        # Reward system
    │   └── settings.lua       # Settings manager
    ├── core/
    │   ├── bingo_board.lua    # Board state management
    │   ├── game_modes.lua     # Game mode implementations
    │   ├── objective.lua      # Objective and category system
    │   ├── board_generator.lua # Board generation
    │   └── persistence.lua    # Save/load system
    ├── ui/
    │   ├── board_renderer_noita.lua  # Rendering using Noita GUI
    │   └── ui_manager_noita.lua      # UI state management
    └── multiplayer/
        ├── network.lua        # Network communication
        └── synchronization.lua # Board sync

## Troubleshooting

### Board doesn't appear
- Check that mod is enabled in Noita's mod menu
- Press F7 to ensure you're in Large mode
- Try pressing F9 twice to toggle visibility

### Objectives not saving
- Make sure you're completing a world update (game running)
- Auto-save happens every 5 seconds during gameplay
- Check Noita's save folder has write permissions

### Multiplayer not working
- Noita doesn't have native multiplayer - requires additional mods
- See Multiplayer section above for options
- Network code is a framework only - needs implementation

## Future Features (Planned)

- Auto-detection of objective completion in-game
- More game modes
- Achievement system
- Better multiplayer support when available
- Custom board sizes (3x3, 7x7)

## Credits

Created for the Noita community. Feel free to modify and share!
