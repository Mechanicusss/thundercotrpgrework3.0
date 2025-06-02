--[[

-- 
isdotaobject( ? ) => boolean

-- Check if object is indexable but is not a regular table
isobject( ? ) => boolean

-- Check if object is a regular table (not a class or an instance)
istable( ? ) => boolean

-- Check if object is an ordered table.
isitable( ? ) => boolean

-- Check if object can be indexed.
isindexable( ? ) => boolean

-- Check if object is not null and not IsNull
exist( ? ) => boolean

-- Get object's superclass
super( instance ) => class

]]

function isdotaobject( obj )
	local sType = type( obj )
	
	if sType == 'userdata' then
		return true
	end
	
	if sType == 'table' and type( obj.IsNull ) == 'function' then
		return true
	end
	
	return false
end

function isobject( obj )
	if isdotaobject( obj ) then
		return true
	end
	
	if type( obj ) == 'table' then
		if getmetatable( obj ) then
			return true
		end

		if isclass( obj ) then
			return true
		end
		
		if getclass( obj ) then
			return true
		end
	end
	
	return false
end

function istable( obj )
	return type( obj ) == 'table' and not isobject( obj )
end

function isitable( obj )
	if istable( obj ) then
		return table.size( obj ) == #obj
	end
	
	return false
end

function isindexable( obj )
	local sType = type( obj )

	if sType == 'table' then
		return true
	end

	if sType == 'userdata' then
		local bStatus = pcall( function()
			local test = obj.test
		end )
		return bStatus
	end
end

function exist( obj )
	if isindexable( obj ) then
		if type( obj.IsNull ) == 'function' then
			return not obj:IsNull()
		end
	end
	
	return obj ~= nil
end

function super( obj )
	return getbase( getclass( obj ) )
end