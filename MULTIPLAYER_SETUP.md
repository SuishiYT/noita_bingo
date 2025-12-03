# Noita Bingo + evaisa.mp Multiplayer Setup Guide

## Overview

Your Noita Bingo mod has been successfully configured to work with the evaisa.mp multiplayer framework! This setup allows your mod to remain "safe" for Steam Workshop upload while providing multiplayer functionality through the evaisa.mp dependency.

## What Was Changed

### 1. Mod Configuration (`mod.xml`)
- Added `dependencies="evaisa.mp"` to require the framework
- Added translation support for the gamemode

### 2. Multiplayer Integration
- **New File**: `src/multiplayer/bingo_gamemode.lua` - Defines the bingo gamemode for evaisa.mp
- **New File**: `src/multiplayer/integration.lua` - Main integration layer between your mod and evaisa.mp
- **Updated**: `src/multiplayer/network.lua` - Now uses evaisa.mp's networking instead of placeholders
- **Updated**: `src/multiplayer/synchronization.lua` - Implements real board state sync via evaisa.mp

### 3. Board State Management
- Added `exportData()` and `importData()` methods to `BingoBoard` class
- Added helper functions to `BingoBoardState` for multiplayer operations
- Board synchronization happens automatically when players join/leave

### 4. Framework Detection
- The mod automatically detects if evaisa.mp is available
- Falls back to single-player mode if the framework isn't installed
- Late initialization ensures proper gamemode registration

## How It Works

### For Users
1. **Solo Play**: Works exactly as before if evaisa.mp isn't installed
2. **Multiplayer**: Users need both mods installed:
   - Your Noita Bingo mod (from Steam Workshop)  
   - evaisa.mp framework (from Steam Workshop or GitHub)

### In Multiplayer Lobbies
1. Host creates a lobby and selects "Noita Bingo" as the gamemode
2. Lobby settings allow configuration of:
   - Board size (3x3, 4x4, 5x5, 6x6)
   - Game mode (Traditional, Blackout, Lockout, Rush)
   - Difficulty (Easy, Normal, Hard, Extreme)
   - Custom seed
3. When the game starts, the host generates the board and syncs it to all players
4. Square clearing is synchronized in real-time across all players
5. Win conditions are announced to all players

### Network Messages
- `board_state`: Syncs the entire board (host to clients)
- `square_clear`: Syncs individual square completions
- `game_win`: Announces when someone wins

## Installation Steps

### For Development/Testing:
1. Ensure both mods are in your Noita mods folder:
   - `mods/noita_bingo/` (your mod)
   - `mods/evaisa.mp/` (the framework)

2. Enable both mods in Noita

3. The framework will automatically detect and register the bingo gamemode

### For Steam Workshop:
1. Upload your `noita_bingo` mod to Steam Workshop (it's safe - no API restrictions needed)
2. Users will need to subscribe to both:
   - Your bingo mod
   - The evaisa.mp framework mod

## Testing the Integration

1. Start Noita with both mods enabled
2. Look for console messages like:
   - "Bingo Multiplayer: evaisa.mp framework detected"
   - "Bingo Multiplayer: Late-registered gamemode with evaisa.mp"
3. In the evaisa.mp lobby interface, "Noita Bingo" should appear as a gamemode option
4. Create a lobby with the bingo gamemode and test multiplayer functionality

## Troubleshooting

### If the gamemode doesn't appear:
- Check that both mods are enabled
- Look for error messages in the console
- Ensure evaisa.mp is the latest version

### If multiplayer doesn't work:
- Verify all players have both mods installed
- Check network connectivity (evaisa.mp uses Steam networking)
- Look for sync-related error messages

### Console Commands for Debugging:
The integration includes detailed logging - check the console for messages starting with:
- "Bingo Multiplayer:"
- "Bingo Network:"
- "Bingo Sync:"

## Benefits of This Approach

1. **Steam Workshop Safe**: Your mod doesn't require unsafe API access
2. **Automatic Fallback**: Works in single-player if framework unavailable  
3. **Real Multiplayer**: Full networked multiplayer via Steam
4. **Lobby System**: Uses evaisa.mp's mature lobby management
5. **Persistent Boards**: Board state is saved in lobby data
6. **Clean Integration**: Minimal changes to your existing code

## Next Steps

1. Test the multiplayer functionality thoroughly
2. Consider adding multiplayer-specific UI elements (player list, sync status, etc.)
3. Add more sophisticated win condition handling for competitive modes
4. Potentially add spectator mode support
5. Upload to Steam Workshop and gather user feedback

The integration is now complete and ready for testing!