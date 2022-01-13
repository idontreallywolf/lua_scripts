local settings = {
	-- This is the actionID to be used on the lever..
	-- ..for teleporting players into the game.
	leverActionID = 14410,

	-- Set to 'true' if you wish that the talkactions..
	-- ..used in the game to be sent in the default chat.
	displayTalkActions = true,

	-- If displayTalkActions is set to false,
	-- this configuratino is not used.
	emoteTalkactions = true,

	-- How fast players can shoot bullets,
	-- higher => slower. Default 1 second.
	talkactionDelay   = 1, -- seconds
	talkactionStorage = 567890,

	-- How long a player should wait before playing again.
	-- Set to 0 for no delay.
	playDelay        = 10, -- seconds
	playDelayStorage = 567891,

	-- There needs to be atleast 2 players for the game to start
	minimumPlayers = 2,

	-- Storage to verify that the player is in the event
	storageInEvent = 567892
}

-- "export"
return settings