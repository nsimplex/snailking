-----
--[[ Snail King ]] VERSION="prealpha"
--
-- Last updated: 2013-08-28
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

TheMod = GLOBAL.require(modinfo.name:lower():gsub("%s", "") .. '.wicker.init')(env)

PrefabFiles = {
	"snailking",
}

TheMod:Run("main")
