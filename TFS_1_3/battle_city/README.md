# Battle City

## Preview
gamepreview (https://streamable.com/45m0vj)

## Setup

Place `battlecity.lua`, `main.lua`, `settings.lua` and `toollib.lua` inside `data/scripts/battlecity`


* Begin by mapping an area (the pictue below is 23x23 tiles) with 4 places where the statues are gonna be placed.
* Configure `BattleCity.config.statuePositions` according to **Figure #1**

* Set PZ flag ![pzflag](https://github.com/idontreallywolf/lua_scripts/blob/main/TFS_1_3/battle_city/setup/icon.png) to the whole area in order to prevent combat between players.
* Place statues on the darker tiles as shown in **Figure #2** (repeat this for all 4 places)
* Setup a 1x4 area along with a lever having an actionid as shown in **Figure #3** and configure `'from'` and `'to'` positions in `BattleCity.config.enterTiles`
* Place obstacles in the arena in anyway you like but make sure the ID is same as `BattleCity.config.obstacleId`

**Figure #1**
![f1](https://github.com/idontreallywolf/lua_scripts/blob/main/TFS_1_3/battle_city/setup/1.png)
**Figure #2**
![f2](https://github.com/idontreallywolf/lua_scripts/blob/main/TFS_1_3/battle_city/setup/2.png)
**Figure #3**
![f3](https://github.com/idontreallywolf/lua_scripts/blob/main/TFS_1_3/battle_city/setup/3.png)