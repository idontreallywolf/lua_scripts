local function secondsToReadable(s)
    local hours   = math.floor(s / 3600)
    local minutes = math.floor(math.mod(s, 3600)/60)
    local seconds = math.floor(math.mod(s, 60))
    return (hours   > 0 and (hours   .. ' hour'   .. (hours   > 1 and 's ' or ' ')) or '') ..
           (minutes > 0 and (minutes .. ' minute' .. (minutes > 1 and 's ' or ' ')) or '') ..
           (seconds > 0 and (seconds .. ' second' .. (seconds > 1 and 's ' or ' ')) or '')
end

local zombie = {}
-- keeps track of players & zombies
zombie.players = {}
zombie.zombies = {}
--#
zombie.config  = {
    startTime = '19:44:30', -- Hours:minutes:seconds
    -- How many players needed to start the event.
    minimumPlayers = 2,
    -- How many players can enter at most.
    maximumPlayers = 10,
    -- %chance of a player dying from zombie attack
    playerDeathChance = 20, -- %
    -- How many zombies should spawn in the beginning?
    zombieStartAmount = 3,
    -- Name of the monster to be spawned
    zombieName = 'zombski',
    -- This is used to check if zombie event has started.
    storageEventStarted = 191817,
    -- Position for the teleport which is going..
    -- ..to send players to the waiting room.
    teleportSpawnPosition = Position(80, 396, 7),
    waitingRoom = {
        topLeft     = Position(78, 392, 7),
        bottomRight = Position(82, 394, 7)
    },
    -- How long players will wait in the waiting room.
    waitingTime = 10, -- 10 seconds
    teleportId = 1387, -- ID of teleport item
    teleportActionId = 56783, -- action ID used on the teleport for detecting players
    -- Zombie arena; Where players will try to survive
    arena = {
        topLeft     = Position(61, 388, 7),
        bottomRight = Position(74, 395, 7)
    },
    -- set to `true` if you want the rewards..
    -- ..to be given randomly instead of all at once.
    randomReward = false,
    rewardBagId = 1987,
    rewards = {
        {2160, 1}, -- Crystal Coin
        {2159, 2}, -- Scarab Coin
        {9020, 5}  -- Vampire Token
    }
}
--#
zombie.initEvent = function(self)
    local teleportItem = Game.createItem(self.config.teleportId, 1, self.config.teleportSpawnPosition)
    teleportItem:setActionId(self.config.teleportActionId)
    Teleport(teleportItem.uid):setDestination(Position(
        math.random(self.config.waitingRoom.topLeft.x, self.config.waitingRoom.bottomRight.x),
        math.random(self.config.waitingRoom.topLeft.y, self.config.waitingRoom.bottomRight.y),
        self.config.waitingRoom.topLeft.z
    ))
    Game.broadcastMessage('Zombie event will begin in '.. secondsToReadable(self.config.waitingTime) ..', Hurry up!')
    addEvent(function(z)
        local tpTile = Tile(z.config.teleportSpawnPosition)
        local tpItem = tpTile:getItemById(z.config.teleportId)
        if tpItem then
            tpItem:remove()
        end
        if z:countPlayers() < z.config.minimumPlayers then
            Game.broadcastMessage('Zombie event shutting down... not enough players.', MESSAGE_STATUS_CONSOLE_RED)
            z:kickPlayers()
            return
        end
        z:startEvent()
    end, self.config.waitingTime * 1000, self)
end
--#
zombie.startEvent = function(self)
    Game.setStorageValue(self.config.storageEventStarted, 1)
    Game.broadcastMessage('Zombie event has begun, Good luck!')
    for _, player in pairs(self.players) do
        if player then
            player:teleportTo(Position(
                math.random(self.config.arena.topLeft.x, self.config.arena.bottomRight.x),
                math.random(self.config.arena.topLeft.y, self.config.arena.bottomRight.y),
                self.config.arena.topLeft.z
            ))
        end
    end
    for i = self.config.zombieStartAmount, 1, -1 do
        self:spawnZombie(Position(
            math.random(self.config.arena.topLeft.x, self.config.arena.bottomRight.x),
            math.random(self.config.arena.topLeft.y, self.config.arena.bottomRight.y),
            self.config.arena.topLeft.z
        ))
    end
end
--#
zombie.stopEvent = function(self)
    Game.setStorageValue(self.config.storageEventStarted, -1)
    local winner = self:getWinner()
    if not winner then return end
    local depot = winner:getDepotChest(winner:getTown():getId(), true)
    local bag   = Game.createItem(self.config.rewardBagId, 1)
    local itemId = nil
    local itemCount = nil
    if self.config.randomReward then
        local randomRewardItem = self.config.rewards[math.random(1, #self.config.rewards)]
        itemId = randomRewardItem[1]
        itemCount = randomRewardItem[2]
        bag:addItemEx(Game.createItem(itemId, itemCount), INDEX_WHEREEVER, FLAG_NOLIMIT)
        depot:addItemEx(bag)
        winner:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, '[Zombie] You have received a reward item. Check your depot.')
        return
    end
    for _, reward in pairs(self.config.rewards) do
        itemId = reward[1]
        itemCount = reward[2]
        bag:addItemEx(Game.createItem(itemId, itemCount), INDEX_WHEREEVER, FLAG_NOLIMIT)
    end
    depot:addItemEx(bag)
    winner:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, '[Zombie] You have received reward items. Check your depot.')
    Game.broadcastMessage(winner:getName() .. ' has won zombie event.')
    zombie:kickPlayers()
    zombie:clearZombies()
end
--#
zombie.addPlayer = function(self, p)
    self.players[p:getId()] = p
end
--#
zombie.removePlayer = function(self, player)
    self.players[player:getId()] = nil
    player:teleportTo(player:getTown():getTemplePosition())
    player:addHealth(player:getMaxHealth())
    if self:countPlayers() == 1 then
        self:stopEvent()
    end
end
--#
zombie.countPlayers = function(self)
    local n = 0
    for _, player in pairs(self.players) do
        if player then n = n + 1 end
    end
    return n
end
--#
zombie.kickPlayers = function(self)
    for _, player in pairs(self.players) do
        if player then
            self:removePlayer(player)
        end
    end
    self.players = {}
end
--#
zombie.getWinner = function(self)
    for _, player in pairs(self.players) do
        if player then
            return player
        end
    end
    return nil
end
--#
zombie.clearZombies = function(self)
    for _, zombski in pairs(self.zombies) do
        if zombski then
            zombski:remove()
        end
    end
end
--#
zombie.spawnZombie = function(self, position)
    local zombie = Game.createMonster(self.config.zombieName, position, false, true)
    self.zombies[zombie:getId()] = zombie
    position:sendMagicEffect(CONST_ME_MAGIC_RED)
end
--#
local ge = GlobalEvent('zombieStart')
function ge.onTime(interval)
    local eventStorage = Game.getStorageValue(zombie.config.storageEventStarted)
    local hasStarted = (eventStorage and (eventStorage == 1)) or false
    if hasStarted then
        print('[Error - ZombieEvent:onTime] The event has already started.')
        return true
    end
    local tile = Tile(zombie.config.teleportSpawnPosition)
    if not tile then
        print('[Error - ZombieEvent:onTime] Could not create teleport, tile not found!')
        return true
    end
    zombie:initEvent()
    return true
end
ge:time(zombie.config.startTime)
ge:register()
--#
local enterZombie = MoveEvent('enterZombie')
function enterZombie.onStepIn(player, item, position, fromPosition)
    if not item:getId() == zombie.config.teleportId then
        return true
    end
    zombie:addPlayer(player)
    Game.broadcastMessage(player:getName() .. ' has entered zombie event.', MESSAGE_STATUS_CONSOLE_RED)
    if zombie:countPlayers() >= zombie.config.maximumPlayers then
        Game.broadcastMessage('Zombie event will begin in a moment... Get ready!')
        addEvent(function() zombie:startEvent() end, 3 * 1000)
    end
    return true
end
enterZombie:aid(zombie.config.teleportActionId)
enterZombie:register()
--#
local eventCallback = EventCallback
function eventCallback.onTargetCombat(creature, target)
    if (not creature:isMonster())
    or (creature:getName():lower() ~= zombie.config.zombieName:lower())
    or (not target:isPlayer()) then
        return true
    end
    local deathChance = zombie.config.playerDeathChance
    math.randomseed(os.time())
    if math.random(1, 100) <= deathChance then
        local targetPos = target:getPosition()
        targetPos:sendMagicEffect(CONST_ME_MORTAREA)
        targetPos:sendMagicEffect(CONST_ME_BIGPLANTS)
        target:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'You have been killed by a zombie.')
        zombie:spawnZombie(targetPos)
        zombie:removePlayer(target)
        return true
    end
    target:say('!survived!', TALKTYPE_MONSTER_SAY)
    target:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
    return true
end
eventCallback:register(-1)