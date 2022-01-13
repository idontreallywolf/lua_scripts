local Tools = {}

--[[
	Usage:
		positionToReadable(Position(x, y, z))
		positionToReadable(nil, x, y, z)
	------------------------------------------------------
	@param position - Position(x, y, z)
	@param x, y, z
	------------------------------------------------------
	returns a string containing dimensions "( x / y / z )"
]]
Tools.positionToReadable = function(self, position, x, y, z)
	if position then
		return "( ".. position.x .." / ".. position.y .." / ".. position.z .." )"
	else
		return "( ".. x .." / ".. y .." / ".. z .." )"
	end
end

-- " export "
return Tools