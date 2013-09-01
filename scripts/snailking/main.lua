-----
--[[ Snail King ]] VERSION="prealpha"
--
-- Last updated: 2013-09-01
-----

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

The images and animation files are not covered under the terms
of this license.
]]--

--@@ENVIRONMENT BOOTUP
local _modname = assert( (assert(..., 'This file should be loaded through require.')):match('^[%a_][%w_%s]*') , 'Invalid path.' )
module( ..., require(_modname .. '.booter') )

--@@END ENVIRONMENT BOOTUP

-- This just enables syntax conveniences.
BindTheMod()


local Lambda = wickerrequire 'paradigms.functional'
local Logic = wickerrequire 'paradigms.logic'

local Pred = wickerrequire 'lib.predicates'


local function greeter(inst)
	print('Thank you, ' .. (STRINGS.NAMES[inst.prefab:upper()] or "player") .. ', for using ' .. Modname .. ' mod v' .. modinfo.version .. '.')
	print(Modname .. ' is free software, licensed under the terms of the GNU GPLv2.')
end

TheMod:AddSimPostInit(greeter)

return function(...)
	assert( TheMod )

	if Debug() then
		modrequire 'debugtools'
	end
end
