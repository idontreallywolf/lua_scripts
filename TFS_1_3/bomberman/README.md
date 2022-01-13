# Bomberman

## How to play
- to place bombs use `!bomb` command

## Setup
Place `bomberman.lua` inside `data/scripts` folder.


* Create 15x11 area
* Configure from-to positions where the players will stand before entering the game.

```lua
--| Where players will stand before starting the game.
ENTER_TILES = {
    FROM = Position(52, 424, 7),
    TO   = Position(55, 424, 7)
},
```

* Configure corner positions.
* \- 1st spot ( top left )
* \- 2nd spot ( bottom right )
* \- 3rd spot ( top right )
* \- 4th spot ( bottom left )

```lua
START_POSITIONS = {
    [1] = Position(47, 412, 7), -- top left     | 1 |   |   |   | 3 |
    [2] = Position(61, 422, 7), -- bottom right |   |   |   |   |   |
    [3] = Position(61, 412, 7), -- top right    |   |   |   |   |   |
    [4] = Position(47, 422, 7)  -- bottom left  | 4 |   |   |   | 2 |
},
```

* \- Configure and set lever action id
```lua
LEVER_ENTER_AID     = 13442
```

![setup](https://github.com/idontreallywolf/lua_scripts/blob/main/TFS_1_3/bomberman/setup/1.png)

![winner](https://github.com/idontreallywolf/lua_scripts/blob/main/TFS_1_3/bomberman/setup/winner.png)

![preview](https://github.com/idontreallywolf/lua_scripts/blob/main/TFS_1_3/bomberman/setup/preview.gif)