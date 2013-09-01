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

--@@ENVIRONMENT BOOTUP
local _modname = assert( (assert(..., 'This file should be loaded through require.')):match('^[%a_][%w_%s]*') , 'Invalid path.' )
module( ..., require(_modname .. '.booter') )

--@@END ENVIRONMENT BOOTUP


local Lambda = wickerrequire 'paradigms.functional'
local Logic = wickerrequire 'paradigms.logic'

local Pred = wickerrequire 'lib.predicates'


SNAILKING_BUILD = Pred.IsString

SNAILKING_HAIR_GROWTH_FRAMES = Pred.IsNonNegativeNumber

for _, coord in ipairs{'X', 'Y', 'Z'} do
	_M["SCALE_" .. coord] = Pred.IsPositiveNumber
end


TESTING_ANIM_DELAY = Pred.IsNonNegativeNumber

TESTING_ANIM_LIST = Lambda.And(
	Pred.IsTable,
	Lambda.Compose( Lambda.BindFirst(Logic.ForAll, Pred.IsString), ipairs )
)


DEBUG = Pred.IsBoolean


return _M
