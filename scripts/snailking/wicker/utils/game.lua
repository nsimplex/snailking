--[[
Copyright (C) 2013  simplex

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--


local EntityScript = EntityScript
local Point = Point


--@@ENVIRONMENT BOOTUP
local _modname = assert( (assert(..., 'This file should be loaded through require.')):match('^[%a_][%w_%s]*') , 'Invalid path.' )
module( ..., require(_modname .. '.booter') )

--@@END ENVIRONMENT BOOTUP


local Lambda = wickerrequire 'paradigms.functional'
local Logic = wickerrequire 'paradigms.logic'

local Pred = wickerrequire 'lib.predicates'

function ToPoint(x, y, z)
	if y then
		x = Point(x, y, z)
	elseif Pred.IsEntityScript(x) then
		x = x:GetPosition()
	end

	if not Pred.IsPoint(x) then
		return nil
	end

	return x
end

function FindAllEntities(center, radius, fn, tags)
	center = ToPoint(center)
	return Lambda.CompactlyFilter(
		function(v)
			return Pred.IsOk(v) and (not fn or fn(v))
		end,
		ipairs(TheSim:FindEntities(center.x, center.y, center.z, radius, tags) or {})
	)
end

function FindSomeEntity(center, radius, fn, tags)
	center = ToPoint(center)
	return Lambda.Find(
		function(v)
			return Pred.IsOk(v) and (not fn or fn(v))
		end,
		ipairs(TheSim:FindEntities(center.x, center.y, center.z, radius, tags) or {})
	)
end

function ListenForEventOnce(inst, event, fn, source)
	-- Currently, inst2 == source, but I don't want to make that assumption.
	local function gn(inst2, data)
		inst:RemoveEventCallback(event, gn, source)
		return fn(inst2, data)
	end
	
	return inst:ListenForEvent(event, gn, source)
end

return _M
