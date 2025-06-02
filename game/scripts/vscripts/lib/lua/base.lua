--[[

xor( ... ) => boolean

binhas( source_flags: number, search_flags: number ) => boolean

binor( number ... ) => number

round( source: number, precision: number ) => number

-- js-like convertation to boolean.
toboolean( ? ) => boolean

-- Transform object to string, keeping information about type.
typestring( ? ) => string

-- Print message with stack trace.
printstack( msg: string, level: number )

-- Protected call with error printing.
ppcall( function( [ params: ? ... ] ) [, params: ? ... ] ) => status: boolean, result: ? ...

-- Run file in special environment with passed __index and __newindex metafields.
envrunfile(
	path: string,
	index: table | function( self: table, key: ? ) (_G),
	newindex: table | function( self: table, key: ?, value: ? ) (_G),
	error: function( err: string ) (error)
) => result: ? ...

mid( min: number, x: number, max: number ) => number

]]

function xor( b1, b2, ... )
	local qArgs = {...}
	local bResult = ( b1 and not b2 ) or ( not b1 and b2 )
	
	if #qArgs == 0 then
		return bResult and true or false
	end
	
	return xor( bResult, ... )
end

function binhas( nSource, ... )
	local qArgs = {...}
	
	for _, nSearchFlags in ipairs( qArgs ) do
		local bHas = true
		local nSourceFlags = nSource

		while nSearchFlags > 0 do
			if nSearchFlags % 2 == 1 and nSourceFlags % 2 == 0 then
				bHas = false
				break
			end
			
			nSourceFlags = math.floor( nSourceFlags / 2 )
			nSearchFlags = math.floor( nSearchFlags / 2 )
		end
	
		if bHas then
			return true
		end
	end

	return false
end

function binor( n1, n2, ... )
	if not n2 then
		return n1
	end
	
	local nNewFlags = n1
	local nFlag = 1
	
	while n2 > 0 do
		if n2 % 2 == 1 and n1 % 2 == 0 then
			nNewFlags = nNewFlags + nFlag
		end
		
		nFlag = nFlag * 2
		n2 = math.floor( n2 / 2 )
		n1 = math.floor( n1 / 2 )
	end
	
	return binor( nNewFlags, ... )
end

function round( n, p )
	if not p then
		p = 1
	end

	return math.floor( n * p + 0.5 ) / p
end

function toboolean( obj )
	return ( obj and obj ~= 0 and obj ~= '' ) or false
end

function typestring( obj )
	local sType = type( obj )
	
	if sType == 'string' then
		return '"' .. obj .. '"'
	end
	
	return tostring( obj )
end

function printstack( sMsg, nLevel )
	if sMsg == nil then
		sMsg = ''
	end
	
	nLevel = tonumber( nLevel ) or 1
	
	print( debug.traceback( sMsg, 1 + nLevel ) )
end

function ppcall( fCode, ... )
	local qArgs = {...}

	return xpcall( function()
		return fCode( table.unpack( qArgs ) )
	end, function( sErr )
		printstack( sErr, 2 )
	end )
end

function envrunfile( sPath, xIndex, xNewIndex, fError )
	local tClones = {}
	local tMetaFields = {
		__index = true,
		__newindex = true,
	}

	local fConvertIndex fConvertIndex = function( xIndex )
		if type( xIndex ) == 'table' then
			local xClone = tClones[ xIndex ]

			if not xClone then
				local tMeta = {}
				local bMeta = false
				xClone = table.copy( xIndex )

				for sMetaField in pairs( tMetaFields ) do
					if xClone[ sMetaField ] then
						bMeta = true
						tMeta[ sMetaField ] = fConvertIndex( xClone[ sMetaField ] )
						xClone[ sMetaField ] = nil
					end
				end

				if bMeta then
					setmetatable( xClone, tMeta )
				end

				tClones[ xIndex ] = xClone
			end

			return xClone
		end

		return xIndex
	end

	local tEnv = fConvertIndex{
		__index = xIndex or _G,
		__newindex = xNewIndex or _G,
	}
	
	local fCode, sErr = loadfile( sPath )
	
	if type( fCode ) == 'function' then
		setfenv( fCode, tEnv )
		local bStatus, xResult = pcall( fCode )
		if bStatus then
			return xResult
		else
			sErr = xResult
		end
	end
	
	if type( fError ) ~= 'function' then
		fError = error
	end

	fError( sErr )
end

function mid( nMin, nVal, nMax )
	return math.min( nMax, math.max( nMin, nVal ) )
end

function args( tArgs, qConditions )
	local tNewArgs = {}
	local tChecked = {}
	local nArgs = #qConditions

	for nArg, xCond in ipairs( qConditions ) do
		local sCondType = type( xCond )
		local xMatch

		if sCondType ~= 'function' then
			local xVal = xCond
			if sCondType == 'string' then
				xCond = function( x )
					return type( x ) == xVal
				end
			else
				xCond = function()
					return xVal
				end
			end
		end

		for nCheckArg = 1, nArgs do
			if not tChecked[ nCheckArg ] then
				local xCheckArg = tArgs[ nCheckArg ]
				if xCond( xCheckArg, nCheckArg, tNewArgs ) then
					tChecked[ nCheckArg ] = true
					tNewArgs[ nArg ] = xCheckArg
					break
				end
			end
		end
	end

	return tNewArgs
end

require 'lib/lua/table'
require 'lib/lua/string'
require 'lib/lua/dota'
require 'lib/lua/vector'