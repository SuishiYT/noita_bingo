# Noita Bingo Mod (In Development)

Online Multiplayer Bingo for Noita!

## Getting Started

### Installation
#### Steam
If you're playing the Steam version of Noita, you can download [Noita_Bingo] directly from the Steam Workshop => [Download on Steam](steam/download/link)

#### Manual Installation
1. Copy the entire mod folder to your Noita mods directory: `{install_folder}/Noita/mods/`
2. Enable the mod in the Mod Menu
3. Launch a new game

### Online Setup
Since Noita doesn't have it's own network system, you need to provide one (don't worry, it's easy)
You have two options for this;
```
┌─────────────────┬──────────────┬──────────────┬───────────────────┬────────────┐
│ Network Option  │ Multiplayer? │ Leaderboard? │ Win/Loss Records? │ Recommend? │
├─────────────────┼──────────────┼──────────────┼───────────────────┼────────────┤
│  Noita Online   │     Yes      │     Yes      │        Yes        │    Yes     │
├─────────────────┼──────────────┼──────────────┼───────────────────┼────────────┤
│  Self Hosting   │     Yes      │      No      │      Limited      │     No     │
└─────────────────┴──────────────┴──────────────┴───────────────────┴────────────┘
```

#### Noita Online (Recommended)
Noita Online is a standale multiplayer framework mod. In simple terms you install this mod and online just works now.
1. [Download Noita Online](https://github.com/EvaisaDev/evaisa.mp/releases) (The latest release version)
2. Extract `evaisa.mp-{version-number}.zip` directly into your Noita mods folder `{install_folder}/Noita/mods/`
3. Enable Noita Online in the Mod Menu
4. Load into a game to test (You should see a lobby window appear on load)

#### Local HTTP Hosting
If you're unable to use Noita Online for any reason, there's a Docker and Setup Instructions included for hosting your own server.
1. Refer to `{install_folder}/Noita/mods/{bingo_mod}/path_to/SERVER_SETUP.md` for instructions


## Features

### Multiple Gamemodes!
#### Singleplayer
  - Traditional Bingo: Get 5 in a row as fast as you can!
  - Blackout: Complete all objectives on the board as fast as you can!
  - Rush: Race to complete as many randomized objectives as you can before time runs out!
  
#### Multiplayer
  - Traditional Bingo: First to get 5 in a row wins!
  - Lockout: Compete for squares. First to 13 wins!

### Optional Objective Rewards (Roadmap)
Receive random (or fixed) rewards for each objective you complete!
Can be enabled/disabled in mod settings.

### Fully Customizable!
#### Customize every aspect of your game board!
The data driven objective system allows for complete board customization, including;
- Limit of total number of objectives that can appear by category or even disable entire objective categories all together
    Categories: Combat | Death | Wandbuilding | Inventory | Exploration | Events/Misc
- Luck Influence: How luck based the objectives should be
- Difficulty
- Save/Load custom game settings

#### Custom Objectives (Roadmap)
Create and play with your own custom Bingo objectives! You can choose to play with the default objectives, use your own, merge your custom objectives with the default ones, or even use multiple custom objective lists at the same time.
Play however you want!

Place your custom objectives file in `path_to/custom/objectives` and configure objectives in mod settings.
Example file provided in `path_to/custom/objectives_sample.lua`.

#### Custom Objective Rewards (Roadmap)
Add your own list of custom objective rewards! Load one, load two, load as many as you want, with or without the default rewards. Do whatever you want, I'm not your dad.

Place your custom rewards file in `path_to/custom/objective_rewards` and configure rewards in mod settings.
Example file provided in `path_to/custom/rewards_sample.lua`

### Flexible UI
Four board display options
- Full Screen (F7 - Toggle)
- Large Board (F8)
- Small Board (F9)
- Hidden (F10 - Toggle)

Large and Small boards can be easily and resized and moved to fit any display size or preference.
Board sizes and positions can be linked/unlinked in the mod settings.

### Auto Tracking (Roadmap)
Because who wants to click squares by hand? The mod detects when you complete an objective and automatically claims the square for you in both Singleplayer and Multiplayer modes!

## Roadmap

### Initial Release
- Auto-Detect Objective Completion
- Win/Loss Tracking
- Custom Objective Support

### Post Release
- Gamemodes
  - Rush (Multiplayer)
  - Stockpile (Single/Multiplayer)
    - Race/Compete to complete multiple bingo boards (Traditional/Blackout)
  - Snake Rush (Single/Multiplayer)
    - Rolls a few initial objectives and generates a new objective after each one is completed
- Achievements
- Objective Rewards
- Custom Objective Rewards
- Custom Board Dimensions
- Global Rush Leaderboard

## Credits
Created by Suishi. Special thank you to BuffYoda, Evaisa and the Noita Community!