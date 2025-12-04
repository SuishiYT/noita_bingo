- schema needs a boolean field for tracking across multiple runs or not


- Bingo game start flow
    - Select bingo game mode
    - Lock all player inputs, movement and health (freeze game state if possible)
        - Bingo menu opens on load prompting single or multiplayer mode
            - singleplayer opens game settings
            - multiplayer checks of noita online lobby
                - host = opens multiplayer game settings
                - not host = displays waiting for host to start game`