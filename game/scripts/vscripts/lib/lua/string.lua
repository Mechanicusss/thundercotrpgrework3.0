--[[

-- Get array of matches.
string.qmatch( source: string, pattern: string [, convert: function( match: string ) ] ) => matches: { string }

]]

function string.qmatch( sSource, sPattern, fConvert )
	fConvert = fConvert or function( ... ) return ... end
	local qMatches = {}

	for sMatch in string.gmatch( sSource, sPattern ) do
		table.insert( qMatches, fConvert( sMatch ) )
	end

	return qMatches
end