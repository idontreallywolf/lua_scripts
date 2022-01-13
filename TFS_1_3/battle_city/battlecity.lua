local cwd      = 'data.scripts.battle_city.'
local tools    = require(cwd .. 'toollib')
local settings = require(cwd .. 'settings')

local BattleCity = {}

-- This table is to keep track of players who have entered the event
BattleCity.players = {}

-- This table is to keep track of obstacle positions..
-- ..for restoring the arena after the event is finished.
BattleCity.obstaclePositions = {}

-- BattleCity configuration
BattleCity.config = {
	-- ID of the statue which will (hopefully) be..
	-- ..protected by the player who gets assigned to it.
	statueId = 17844,

	-- The following configuration is used for transforming..
	-- ..the initial statue (and the walls around it) when a certain amount of..
	-- ..damage has been dealt by other players' attacks ( "bullets" ).
	statueTransform = {
		[3] = { hp = 9, transformId = 17835 },
		[2] = { hp = 5, transformId = 17841 },
		[1] = { hp = 3, transformId = 17847 }
	},

	statueIds = { 17844, 17835, 17841, 17847 },

	-- how much 'hp' statues (& walls) will have at the start of the event.
	statueHealth = 10,

	-- how much 'hp' will be removed from statues when bullets hit them.
	bulletDamage = 1,

	obstacleId = 6972,
	obstacleHealth = 3,

	-- This is where the players are going to..
	-- ..stand before pulling the lever which will..
	-- ..initiate the game.
	enterTiles = {
		-- Tiles should be placed vertically..
		-- ..or horizontally.
		-- The current setting only allows this setup.
		--
		-- assume F = from, and T = to:
		-- +---------------+
		-- | F |   |   | T |
		-- +---------------+
		fromPosition = Position(209, 388, 7),
		toPosition   = Position(212, 388, 7)
	},

	-- Positions of the statues to be protected by the players.
	statuePositions = {
		[1] = Position(220, 389, 7), -- West  ( < )
		[2] = Position(231, 378, 7), -- North ( ^ )
		[3] = Position(242, 389, 7), -- East  ( > )
		[4] = Position(231, 400, 7), -- South ( V )
	},

	--[[
		how thick is the wall protecting the statues?
		Assume `S` = Statue
		---------------------------------------------
		+---+       |
		| S |       | wallThickness = 1  ( default )
		+---+       |
                    |
		+ +---+ +   |
		+ +---+ +   |
		| | S | |   | wallThickness = 2
		+ +---+ +   |
		+ +---+ +   |
	]]
	wallThickness = 1,

	-- How far a "bullet" can travel before dissapearing
	-- ..(player position being point of origin)
	maxShootRadius = 4,

	-- ID of the bag in which the reward items will be placed.
	rewardBagId = 1987,
	rewards = {
		{2160, 1}, -- 1x Crystal Coin
		{2159, 1}, -- 1x Scarab Coin
		{2322, 1}  -- Voodoo Doll
	},

	-- How long it should take a player to ..
	-- ..respawn after being hit by a bullet.
	playerRespawnDelay = 3,

	-- How many seconds the shield will last before..
	-- ..the player can be hit by a bullet again.
	respawnShieldStorage = 567893,
	respawnShieldTime    = 2,

	-- Frozen mage outfit to be used when player is hit by another bullet.
	outfitFrozen = 18008
}

-----------------------------------| Calculate player spawn positions |---------------------------------
local statuePos = BattleCity.config.statuePositions
local playerPosOffSet = (BattleCity.config.wallThickness + 1)
BattleCity.config.playerPositions = {
	[1] = Position(statuePos[1].x + playerPosOffSet, statuePos[1].y,                   statuePos[1].z),
	[2] = Position(statuePos[2].x,                   statuePos[2].y + playerPosOffSet, statuePos[2].z),
	[3] = Position(statuePos[3].x - playerPosOffSet, statuePos[3].y,                   statuePos[3].z),
	[4] = Position(statuePos[4].x,                   statuePos[4].y - playerPosOffSet, statuePos[4].z)
}
--------------------------------------------------------------------------------------------------------

BattleCity.initPlayer = function(self, player)
	-- nothing
end

--[[
	Sets custom attributes to the statue at position..
	..with given index in the config.statuePositions table.
	pid          - player id; this is to keep track of who owns the current "base" / "tower" / "statue"
	health       - hp of the statue
	isMainStatue - to differentiate between the main- and wall statues
	lastIndex    - this is used for the transformation ( config.statueTransform )
	-------------------------------------------------------------------
	@param index  - statue position index from `config.statuePositions`
	@param player - reference to the player (statueOwner)
]]
BattleCity.bindStatueToPlayer = function(self, index, player)
	local statuePosition = self.config.statuePositions[index]
	local tile = Tile(statuePosition)
	local statue = tile:getItemById(self.config.statueId)
	if not statue then
		return false
	end

	local pid = player:getId()
	-- init main statue
	statue:setCustomAttribute('pid', pid)
	statue:setCustomAttribute('health', self.config.statueHealth)
	statue:setCustomAttribute('isMainStatue', 1)
	statue:setCustomAttribute('lastIndex', #self.config.statueTransform)

	-- init walls
	local wallThickness = self.config.wallThickness
	local z = statuePosition.z
	for x = statuePosition.x - wallThickness, statuePosition.x + wallThickness do
		for y = statuePosition.y - wallThickness, statuePosition.y + wallThickness do
			(function()
				if x == statuePosition.x and y == statuePosition.y then
					return
				end

				local t = Tile(x, y, z)
				if not t then
					return
				end

				local wall = t:getItemById(self.config.statueId)
				if not wall then
					return
				end

				wall:setCustomAttribute('pid', pid)
				wall:setCustomAttribute('health', self.config.statueHealth)
				wall:setCustomAttribute('isMainStatue', 0)
				wall:setCustomAttribute('lastIndex', #self.config.statueTransform)
			end)()
		end
	end
	return true
end

--[[
	Checks if enter tiles are in either of the expected orders:
	a) vertical
	b) horizontal
	----------------------------------------
	returns true, if a or b. Otherwise false.
]]
BattleCity.validateEnterTiles = function(self)
	local cfg = self.config.enterTiles

	-- if both dimensions are inequal,
	-- tiles are not placed as expected.
	if (cfg.fromPosition.x ~= cfg.toPosition.x)
	and (cfg.fromPosition.y ~= cfg.toPosition.y) then
		print('[Error - BattleCity:validateEnterTiles] Wrong tile setup.')
		return false
	end
	return true
end

--[[
	Iterates over statue and player positions in the arena.
	-----------------------------------------------------------------
	returns false if destination tile does not exist, otherwise true.
]]
BattleCity.validateDestinationSpots = function(self)
	-- check status positions
	local statuePositions = self.config.statuePositions
	for _, pos in pairs(statuePositions) do
		local tile = Tile(pos)
		if not tile then
			print('[Error - BattleCity:validateDestinationSpots] Tile not found '.. tools:positionToReadable(pos))
			return false
		end
	end
	-- check player positions
	local playerPositions = self.config.playerPositions
	for _, pos in pairs(playerPositions) do
		local tile = Tile(pos)
		if not tile then
			print('[Error - BattleCity:validateDestinationSpots] Tile not found '.. tools:positionToReadable(pos))
			return false
		end
	end
	return true
end

--[[
	Iterates over tiles `from` -> `to`,
	stores players in a table.
    -----------------------------------
	returns `false` if a tile is not found,
	otherwise a table containing players.
]]
BattleCity.getEnterPlayerCount = function(self)
	local cfg = self.config.enterTiles
	local players = {}
	local z = cfg.fromPosition.z
	for x = cfg.fromPosition.x, cfg.toPosition.x do
		for y = cfg.fromPosition.y, cfg.toPosition.y do
			local tile = Tile(x, y, z)
			if not tile then
				print('[Error - BattleCity:getEnterPlayerCount] Tile not found '.. tools:positionToReadable(nil, x, y, z))
				return false
			end

			local topCreature = tile:getTopCreature()
			if topCreature and topCreature:isPlayer() then
				self.players[topCreature:getId()] = topCreature
				table.insert(players, topCreature)
			end
		end
	end
	return players
end

BattleCity.kickPlayers = function(self)
	for _, player in pairs(self.players) do
		if player then
			player:teleportTo(player:getTown():getTemplePosition())
			player:setStorageValue(settings.storageInEvent, -1)
		end
	end
end

--[[
	returns the position for where a player is supposed to spawn.
	@param index - same index as the main statue
]]
BattleCity.getPlayerArenaPosition = function(self, index)
	return self.config.playerPositions[index]
end

--[[
	returns config value for how far a bullet can travel.
]]
BattleCity.getMaxShootRadius = function(self)
	return self.config.maxShootRadius
end

--[[
	This method is called when the 'bullet' has hit a statue object.
	The statue is transformed if the `bullet` deals enough damage..
	..and statue-hp reaches a certain amount. ( config.statueTransform )

	If one of the main statues is destroyed, the corresponding..
	..statue-owner gets 'erased' from the players list, notified..
	..and sent to the temple.
	--------------------------------------------------------------------
	@param player - reference to attacker
	@param statue - reference to statue object
]]
BattleCity.checkStatueDamage = function(self, player, statue)
	local transformCfg   = self.config.statueTransform
	local statueHealth   = tonumber(statue:getCustomAttribute('health'))
	local newHealth      = statueHealth - self.config.bulletDamage
	local lastId         = tonumber(statue:getCustomAttribute('lastIndex'))
	local isMainStatue   = tonumber(statue:getCustomAttribute('isMainStatue')) == 1
	local statuePosition = statue:getPosition()

	if newHealth <= 0 then
		if isMainStatue then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You have destroyed enemy base!')
			local statueOwner = Player(statue:getCustomAttribute('pid'))
			if not statueOwner then
				return
			end

			self.players[statueOwner:getId()] = nil
			statueOwner:sendTextMessage(MESSAGE_EVENT_ADVANCE,'!! YOUR BASE HAS BEEN DESTROYED !!')
			statueOwner:setStorageValue(settings.storageInEvent, -1)
			statueOwner:teleportTo(statueOwner:getTown():getTemplePosition())
		end
		statuePosition:sendMagicEffect(CONST_ME_BIGCLOUDS)
		statue:remove()
		return
	end

	statue:setCustomAttribute('health', newHealth)
	player:say(newHealth, TALKTYPE_MONSTER_SAY, false, nil, statue:getPosition())
	if lastId < 1 then
		return
	end

	for i = lastId, 1, -1 do
		if (newHealth <= transformCfg[i].hp) then
			local pid = statue:getCustomAttribute('pid')
			local ims = statue:getCustomAttribute('isMainStatue')
			-- change statue to broken/damaged form
			statue:transform(transformCfg[i].transformId)
			-- re-set attributes
			statue:setCustomAttribute('pid', pid)
			statue:setCustomAttribute('lastIndex', i-1)
			statue:setCustomAttribute('isMainStatue', ims)
			statue:getPosition():sendMagicEffect(CONST_ME_BIGCLOUDS)
			break
		end
	end
end

--[[
	After the command is executed, the 'bullet' starts 'moving'..
	..in the direction where the player is looking.
	This process is repeated until the bullet either..
	..reaches maximum radius or hits an object.
	----------------------------------------------------------------
	@param position  - current bullet position. ( changes )
	@param direction - where the player is looking.
	@param step      - how many steps are left for the bullet to travel.
	@param pid       - player id ( whoever executed the command )
]]
BattleCity.moveBullet = function(self, position, direction, step, pid)
	local player = Player(pid)
	if not player then
		position:sendMagicEffect(CONST_ME_POFF)
		return
	end

	local tile = Tile(position)
	if not tile then
		position:sendMagicEffect(CONST_ME_POFF)
		return
	end

	if not tile:isWalkable() then
		local statue = nil
		for _, statueId in pairs(self.config.statueIds) do
			statue = tile:getItemById(statueId)
			if statue then
				break
			end
		end

		if not statue then
			local obstacle = tile:getItemById(self.config.obstacleId)
			if obstacle then
				self:checkObstacleDamage(player, obstacle)
				return
			end
			position:sendMagicEffect(CONST_ME_POFF)
			return
		end

		local statuePid = statue:getCustomAttribute('pid')
		if not statuePid then
			player:sendTextMessage(MESSAGE_STATUS_SMALL, 'This base is not occupied.')
			position:sendMagicEffect(CONST_ME_POFF)
			return
		end

		if statuePid == pid then
			player:sendTextMessage(MESSAGE_STATUS_SMALL, 'You may not attack your own base!')
			position:sendMagicEffect(CONST_ME_POFF)
			return
		end

		position:sendMagicEffect(CONST_ME_GROUNDSHAKER)
		self:checkStatueDamage(player, statue)
		if self:countPlayers() == 1 then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You have won the Battle!')
			player:setStorageValue(settings.storageInEvent, -1)
			self:giveRewards(player)
		end
		return
	end

	local topCreature = tile:getTopCreature()
	if  topCreature
	and topCreature:isPlayer()
	and (topCreature:getId() ~= player:getId())
	and self.players[topCreature:getId()] then
		if topCreature:isMovementBlocked()
		or topCreature:getStorageValue(self.config.respawnShieldStorage) > os.time() then
			topCreature:getPosition():sendMagicEffect(CONST_ME_POFF)
			return
		end

		-- freeze player
		topCreature:setMovementBlocked(true);
		topCreature:sendTextMessage(
			MESSAGE_STATUS_CONSOLE_BLUE,
			'You were killed by the enemy. Respawning in ' .. self.config.playerRespawnDelay .. ' seconds.'
		)

		-- unfreeze after x seconds
		addEvent(function(cid, outfit)
			local p = Player(cid)
			if not p then
				return
			end
			p:setMovementBlocked(false);
			p:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 'You have respawned.')
			p:setOutfit(outfit)
			p:setStorageValue(self.config.respawnShieldStorage, os.time() + self.config.respawnShieldTime)
			local radius = 2
			local effectOffset = {
				{x = -radius, y = -radius}, -- top    left
				{x =  radius, y =  radius}, -- top    right
				{x = -radius, y =  radius}, -- bottom left
				{x =  radius, y = -radius}  -- bottom right
			}
			local positionEx = p:getPosition()
			for _, offset in pairs(effectOffset) do
				Position(
					positionEx.x + offset.x,
					positionEx.y + offset.y,
					positionEx.z
				):sendDistanceEffect(positionEx, CONST_ANI_SMALLICE)
			end
		end, self.config.playerRespawnDelay * 1000, topCreature:getId(), topCreature:getOutfit())

		topCreature:setOutfit({ lookTypeEx = self.config.outfitFrozen })
		return
	end

	-- send bullet to next position
	local p = Position(position)
	p:getNextPosition(direction)
	position:sendDistanceEffect(p, CONST_ANI_FIRE)
	position:getNextPosition(direction)
	if step > 0 then
		addEvent(
			function(pos, dir, n, pid)
				self:moveBullet(pos, dir, n, pid)
			end,
		100, position, direction, step - 1, pid)
		return true
	end
	position:sendMagicEffect(CONST_ME_FIREATTACK)
	return true
end

--[[
	This method is called when the bullet hits..
	..one of the obstacles in the arena.
	--------------------------------------------
	@param player   - reference to attacker
	@param obstacle - reference to the object
]]
BattleCity.checkObstacleDamage = function(self, player, obstacle)
	local health = tonumber(obstacle:getCustomAttribute('health'))
	if not health then
		obstacle:setCustomAttribute('health', self.config.obstacleHealth)
		health = self.config.obstacleHealth
	end

	local obstaclePos = obstacle:getPosition()
	if (health - self.config.bulletDamage) <= 0 then
		obstaclePos:sendMagicEffect(CONST_ME_POFF)
		obstacle:remove()
		table.insert(self.obstaclePositions, obstaclePos)
		return
	end

	player:say(health - self.config.bulletDamage, TALKTYPE_MONSTER_SAY, false, nil, obstacle:getPosition())
	obstaclePos:sendMagicEffect(CONST_ME_MORTAREA)
	obstacle:setCustomAttribute('health', health - self.config.bulletDamage)
end

--[[
	returns number of players in the arena
]]
BattleCity.countPlayers = function(self)
	local p = 0
	for _, player in pairs(self.players) do
		if player then
			p = p + 1
		end
	end
	return p;
end

--[[
	Prepares and sends game reward to the player depot.
	---------------------------------------------------
	@param player - reference to the winner
]]
BattleCity.giveRewards = function(self, player)
	local rewardBag = Game.createItem(self.config.rewardBagId, 1)
	-- create & move items to bag
	for _, reward in pairs(self.config.rewards) do
		local itemId = reward[1]
		local count  = reward[2]
		local it = ItemType(itemId)
		if it then
			rewardBag:addItemEx(Game.createItem(itemId, count), INDEX_WHEREEVER, FLAG_NOLIMIT)
		else
			print('[Warning - BattleCity::giveRewards] Unknown ItemType ' .. reward[1])
		end
	end

	-- send to depot
	local depot = player:getDepotChest(player:getTown():getId(), true)
	depot:addItemEx(rewardBag)
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, '[BattleCity] You have received reward items. Check your depot.')
	player:teleportTo(player:getTown():getTemplePosition())
	self:resetArena()
end

BattleCity.resetArena = function(self)
	-- reset table
	self.players = {}

	-- clear arena
	for _, position in pairs(self.config.statuePositions) do
		local z = position.z
		for x = position.x - 1, position.x + 1 do
			for y = position.y - 1, position.y + 1 do
				(function()
				-------------------------------------
				local tile = Tile(x, y, z)
				if not tile or not tile:isWalkable() then
					return
				end

				local tileItems = tile:getItems()
				for _, item in pairs(tileItems) do
					item:remove()
				end

				Game.createItem(self.config.statueId, 1, Position(x, y, z))
				-------------------------------------
				end)()
			end
		end
	end

	-- place obstacles
	for _, position in pairs(self.obstaclePositions) do
		Game.createItem(self.config.obstacleId, 1, position)
	end
	return true
end

-- " export "
return BattleCity