--[[

-- Find key by value.
table.key( table, value: ? ) => key: ?

-- Number of fields in table
table.size( table ) => size: number

-- Unpack itable to params sequence.
table.unpack( { params: ? ... } ) => params: ? ...

-- New table with same fields
table.copy( ? ) => copy: table

-- New table with same fields. All inner tables are copied too.
table.deepcopy( ? [, convert: function( value: ?, iskey: boolean ) => newValue: ? ) => copy: table

-- Deep merge tables by replacing conflicting non-table fields.
table.overlay( [ table ... ] ) => table

-- New itable as a sequential join.
table.contact( itable | nil, itable | nil ) => itable

-- Remove elements wich does not match condition.
table.filter( itable, condition: function( value, index, table ): boolean ) => itable

-- Get random table element. If use_weights is true, table values will be used as weights (assuming they are numbers).
table.random( table [, use_weights: ? -> boolean, stream: CScriptUniformRandomStream ] ) => key: ?, value: ?

-- Deep print table.
table.print( table [, options: table ] ) => nil | { string ... }
	options: {
		bMeta = ? -> boolean (false), -- Print __index metafield as a common field.
		bReturn = ? -> boolean (false), -- Return result as lines sequence without printing.
		bKey = ? -> boolean (false), -- Print as a key.
		bIgnoreFDesc = ? -> boolean (true),
		fPrint = function( string ) (print), -- Printing function.
		fIter = iterator (pairs | ipairs), -- Force the iterator over table.
		fContinue = ( function( ? ) => ? -> boolean )(true),
		xFormat = number | table {
			fTypestring = ( function( ? ) => string )(typestring),
			sKeyPrefix = string ("["),
			sKeyPostfix = string ("]"),
			sTablePrefix = string ("{"),
			sTablePostfix = string ("}"),
			sTableRecursion = string ("{...}"),
			sDelimiter = string (": "),
			sOffset = string ("    "),
		},
	}

]]

function table.key( t, xValue )
	for k, v in pairs( t ) do
		if v == xValue then
			return k
		end
	end
end

function table.size( t )
	local nSize = 0
	
	for _ in pairs( t ) do
		nSize = nSize + 1
	end
	
	return nSize
end

function table.unpack( qArgs )
	if #qArgs < 2 then
		return qArgs[1]
	end
	
	local qNew = {}
	for i = 2, #qArgs do
		table.insert( qNew, qArgs[i] )
	end
	
	return qArgs[1], table.unpack( qNew )
end

function table.conc(a1, a2)
	local a = {}
	for _, v in ipairs(a1) do
		table.insert(a, v)
	end
	for _, v in ipairs(a2) do
		table.insert(a, v)
	end
	return a
end

function table.copy( t )
	if not istable( t ) then
		return t
	end
	
	local tCopy = {}
	for k, v in pairs( t ) do
		tCopy[ k ] = v
	end
	
	return tCopy
end

function table.deepcopy( t, fCopy, _tCopied, _bKey )
	if not istable( t ) then
		if fCopy then
			return fCopy( t, _bKey or false )
		end
		return t
	end	

	_tCopied = _tCopied or {}
	local tCopy = _tCopied[ t ] 
	
	if tCopy then
		return tCopy
	end
	
	tCopy = {}
	_tCopied[ t ] = tCopy
	
	for k, v in pairs( t ) do
		tCopy[ table.deepcopy( k, fCopy, _tCopied, true ) ] = table.deepcopy( v, fCopy, _tCopied )
	end
	
	return tCopy
end

function table.contact( t1, t2 )
	local t = {}
	
	for _, v in ipairs( t1 or {} ) do
		table.insert( t, v )
	end
	
	for _, v in ipairs( t2 or {} ) do
		table.insert( t, v )
	end
	
	return t
end

function table.filter( t, f )
	local qNew = {}

	for k, v in ipairs( t ) do
		if f( v, k, t ) then
			table.insert( qNew, v )
		end
	end

	return qNew
end

function table.overlay( t1, t2, ... )
	if t1 == nil then
		return table.deepcopy( t2 )
	end
	
	if t2 == nil then
		return table.deepcopy( t1 )
	end
	
	local fOverlayPair
	fOverlayPair = function( t1, t2, _tOverlaying )
		_tOverlaying = _tOverlaying or {}
		
		if istable( t1 ) and istable( t2 ) then
			local tNew = table.deepcopy( t1 )
			_tOverlaying[ t1 ] = true
			
			for k2, v2 in pairs( t2 ) do
				local v1 = t1[ k2 ]
				
				if _tOverlaying[ v1 ] then
					tNew[ k2 ] = table.deepcopy( v2 )
				else
					tNew[ k2 ] = fOverlayPair( v1, v2, _tOverlaying )
				end
			end
			
			_tOverlaying[ t1 ] = nil
			return tNew
		else
			return table.deepcopy( t2 )
		end
	end
	
	return table.overlay( fOverlayPair( t1, t2 ), ... )
end

function table.equal( t1, t2, bParseKeys, _tEquals )
	if not istable( t1 ) or not istable( t2 ) then
		return t1 == t2
	end

	local t2_rem = table.copy( t2 )
	_tEquals = _tEquals or {}

	for _, tEqualPair in pairs( _tEquals ) do
		if tEqualPair[1] == t1 and tEqualPair[2] == t2 or tEqualPair[1] == t2 and tEqualPair[2] == t1 then
			return true
		end
	end

	local function fCheckEquals( t1, t2 )
		if table.equal( t1, t2, bParseKeys, _tEquals ) then
			table.insert( _tEquals, { t1, t2 } )
			return true
		end

		return false
	end

	for k1, v1 in pairs( t1 ) do
		local k2 = k1
		
		if bParseKeys then
			k2 = nil

			for _k2 in pairs( t2_rem ) do
				if fCheckEquals( k1, k2 ) then
					k2 = _k2
					break
				end
			end
		end

		if k2 == nil then
			return false
		end

		if not fCheckEquals( v1, t2_rem[ k2 ] ) then
			return false
		end
		
		t2_rem[ k2 ] = nil
	end

	return table.size( t2_rem ) < 1
end

function table.random( t, bWeighted, hStream )
	local tWeighted = {}
	local qIndexed = {}
	local nSumWeight = 0
	
	for k, v in pairs( t ) do
		local nWeight = bWeighted and tonumber( v ) or 1
		nSumWeight = nSumWeight + nWeight
		tWeighted[ k ] = nSumWeight
		table.insert( qIndexed, k )
	end
	
	local nRandomWeight
	if hStream and type( hStream.RandomFloat ) == 'function' then
		nRandomWeight = hStream:RandomFloat( 0, nSumWeight )
	else
		nRandomWeight = RandomFloat( 0, nSumWeight )
	end
	
	for _, k in ipairs( qIndexed ) do
		local nWeight = tWeighted[ k ]
		if nWeight >= nRandomWeight then
			return k, t[ k ]
		end
	end
end

local table_print_formats = {
	[1] = {
		fTypestring = function( obj )
			local s = typestring( obj )
			if type( obj ) == 'userdata' then
				s = 'userdata: ' .. s
			end
			return s
		end,
		sKeyPrefix = '[',
		sKeyPostfix = ']',
		sTablePrefix = '{',
		sTablePostfix = '}',
		sTableRecursion = '{...}',
		sDelimiter = ': ',
		sOffset = '    ',
	},
	[2] = {
		fTypestring = function( obj	)
			if type( obj ) == 'table' then
				return ''
			end
			return '"' .. tostring( obj ) .. '"'
		end,
		sKeyPrefix = '',
		sKeyPostfix = '',
		sTableRecursion = '{}',
		sDelimiter = '\t',
	}
}

function table.print( t, tParams, _tPrinted )	
	tParams = tParams or {}
	local fPrint = tParams.fPrint or print
	local fIter = tParams.fIter
	local bIgnoreFDesc = ( tParams.bIgnoreFDesc == nil ) or tParams.bIgnoreFDesc
	local fContinue = tParams.fContinue or function() return true end
	
	local tFormat = tParams.xFormat
	if type( tFormat ) == 'number' then
		tFormat = table_print_formats[ tFormat ]
	end
	if type( tFormat ) ~= 'table' then
		tFormat = {}
	end
	tFormat = table.overlay( table_print_formats[1], tFormat )

	local qPrint = { tFormat.fTypestring( t ) }
	local bContinue = fContinue( t )
	local sType = type( t )
	local bTable = ( sType == 'table' )

	if ( bTable or sType == 'userdata' ) and bContinue then
		_tPrinted = _tPrinted or {}

		qPrint[1] = qPrint[1] .. tFormat.sDelimiter
	
		if _tPrinted[ t ] then
			qPrint[1] = qPrint[1] .. tFormat.sTableRecursion
		else
			_tPrinted[ t ] = true
			
			local fForceIter = fIter
			local bVoid = true

			local fAddLine = function( k, v )
				bVoid = false
					
				for i = 1, #k do
					table.insert( qPrint, tFormat.sOffset .. k[i] )
				end
				
				qPrint[ #qPrint ] = qPrint[ #qPrint ] .. tFormat.sDelimiter .. v[1]
				for i = 2, #v do
					table.insert( qPrint, tFormat.sOffset .. v[i] )
				end
			end

			qPrint[1] = qPrint[1] .. tFormat.sTablePrefix
			
			if bTable then
				if type( fIter ) ~= 'function' then
					if isitable( t ) then
						fIter = ipairs
					else
						fIter = pairs
					end
				end

				for k, v in fIter( t ) do
					if not bIgnoreFDesc or k ~= 'FDesc' then
						fAddLine(
							table.print( k, {
								bReturn = true,
								bKey = true,
								bIgnoreFDesc = bIgnoreFDesc,
								bMeta = bMeta,
								fIter = fForceIter,
								fContinue = fContinue,
								xFormat = tFormat,
							}, _tPrinted ),
							table.print( v, {
								bReturn = true,
								bIgnoreFDesc = bIgnoreFDesc,
								bMeta = bMeta,
								fIter = fForceIter,
								fContinue = fContinue,
								xFormat = tFormat,
							}, _tPrinted )
						)
					end
				end
			end
			
			if tParams.bMeta then
				local tMeta = getmetatable( t )
				if type( tMeta ) == 'table' then
					if tMeta.__index ~= nil then
						fAddLine(
							{'__index'},
							table.print( tMeta.__index, {
								bReturn = true,
								bIgnoreFDesc = bIgnoreFDesc,
								bMeta = true,
								fIter = fForceIter,
								fContinue = fContinue,
								xFormat = tFormat,
							}, _tPrinted )
						)
					end
				end
			end
			
			if bVoid then
				qPrint[1] = qPrint[1] .. tFormat.sTablePostfix
			else
				table.insert( qPrint, tFormat.sTablePostfix )
			end
		end
	end
	
	if tParams.bKey then
		qPrint[1] = tFormat.sKeyPrefix .. qPrint[1]
		qPrint[ #qPrint ] =  qPrint[ #qPrint ] .. tFormat.sKeyPostfix
	end
	
	if tParams.bReturn then
		return qPrint
	end
	
	for _, s in ipairs( qPrint ) do
		fPrint( s )
	end
end