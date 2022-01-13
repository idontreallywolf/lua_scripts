--[[
	+---------------+-----------------------------------------------------+
	| Author:       | Snavy ( https://otland.net/members/snavy.155163/ )  |
	| Engine:       | TFS 1.3 ( 48167ef )                                 |
	| Version:      | 1.0                                                 |
    +---------------+-----------------------------------------------------+
	| Note:         | if you find any bugs / errors,                      |
	|               | feel free to open a thread on the support board.    |
	|               | https://otland.net/forums/support.16/               |
	+---------------+-----------------------------------------------------+

    ______   _______ __________________ _        _______
    (  ___ \ (  ___  )\__   __/\__   __/( \      (  ____ \
    | (   ) )| (   ) |   ) (      ) (   | (      | (    \/
    | (__/ / | (___) |   | |      | |   | |      | (__
    |  __ (  |  ___  |   | |      | |   | |      |  __)
    | (  \ \ | (   ) |   | |      | |   | |      | (
    | )___) )| )   ( |   | |      | |   | (____/\| (____/\
    |/ \___/ |/     \|   )_(      )_(   (_______/(_______/

     _______ __________________           |--|    __       _______
    (  ____ \\__   __/\__   __/|\     /|  |--|   /   \    (  __   )
    | (    \/   ) (      ) (   ( \   / )  |--|   \/) )    | (  )  |
    | |         | |      | |    \ (_) /   |--|     | |    | | /   |
    | |         | |      | |     \   /    |--|     | |    | (/ /) |
    | |         | |      | |      ) (     |--|     | |    |   / | |
    | (____/\___) (___   | |      | |     |--|   __) (_ _ |  (__) |
    (_______/\_______/   )_(      \_/     |--|   \____/(_)(_______)
]]

------------------------------------------------------------
local cwd        = 'data.scripts.battle_city.'
local settings   = require(cwd .. 'settings')
local tools      = require(cwd .. 'toollib')
local battleCity = require(cwd .. 'battlecity')
------------------------------------------------------------
-- ACTION -- BEGIN
------------------------------------------------------------
local lever = Action()
function lever.onUse(player, item, fromPosition, itemEx, toPosition)
	local lastPlayed = player:getStorageValue(settings.playDelayStorage)
	if lastPlayed > os.time() then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, 'You have to wait ' .. tools:secondsToReadable(lastPlayed - os.time()) .. ' before playing again.')
		fromPosition:sendMagicEffect(CONST_ME_POFF)
		return true
	end

	local players = battleCity:getEnterPlayerCount()
	if (not battleCity:validateEnterTiles())
	or (not players)
	or (not battleCity:validateDestinationSpots()) then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, 'An error occured. Contact admin.')
		fromPosition:sendMagicEffect(CONST_ME_POFF)
		return true
	end

	if #players < settings.minimumPlayers then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, 'Minimum ' .. settings.minimumPlayers .. ' players!')
		return true
	end

	-- Teleport players to the arena
	for i, p in ipairs(players) do
		if not battleCity:bindStatueToPlayer(i, p) then
			print('[Error - BattleCity:bindStatueToPlayer] Statue not found. (index: '.. i ..')')
			-- in case somebody was teleported earlier.
			battleCity:kickPlayers()
			break
		end
		battleCity:initPlayer(p)
		p:teleportTo(battleCity:getPlayerArenaPosition(i))
		p:setStorageValue(settings.storageInEvent, 1)
	end
	return true
end
lever:aid(settings.leverActionID)
lever:register()

------------------------------------------------------------
-- TALKACTION -- BEGIN
------------------------------------------------------------
local shoot = TalkAction('!shoot')
function shoot.onSay(player, words, param)
	if (player:getStorageValue(settings.talkactionStorage) > os.time())
	or (player:getStorageValue(settings.storageInEvent) < 1) then
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	player:setStorageValue(settings.talkactionStorage, os.time() + settings.talkactionDelay)
	if settings.displayTalkActions then
		player:say(words, settings.emoteTalkactions and TALKTYPE_MONSTER_SAY or TALKTYPE_SAY)
	end

	local playerPos = player:getPosition()
	battleCity:moveBullet(playerPos, player:getDirection(), battleCity:getMaxShootRadius(), player:getId())
	return false
end
shoot:register()