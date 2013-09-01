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

local EventChain = wickerrequire 'gadgets.eventchain'

local game = wickerrequire 'utils.game'



--[[
--
-- Generic console utilities.
--
--]]

local RADIUS = 2^4


local function gimme(prefab)
	local inst
	if GLOBAL.TheSim and GLOBAL.TheInput then
		GLOBAL.TheSim:LoadPrefabs({prefab})
		inst = GLOBAL.SpawnPrefab(prefab)
		if inst.Transform then
			inst.Transform:SetPosition(GLOBAL.TheInput:GetWorldPosition():Get())
		elseif inst then
			inst:Remove()
			inst = nil
		end
	end
	return inst
end


local function FindAll(fn, tags)
	return game.FindAllEntities( GetPlayer(), RADIUS, fn, tags or {"snailking"} )
end


local function NewCountFolder(f)
	return function(x, total)
		if f(x) then
			return 1 + (total or 0)
		else
			return total
		end
	end
end


local function kill(inst)
	if inst.components.health then
		inst.components.health:SetVal(0)
	else
		inst:Remove()
	end
	return true
end

local kill_folder = NewCountFolder(kill)


local function pause(inst)
	if not inst:HasTag(modname .. "_paused") then
		inst:PushEvent(modname .. "_pause")
		return true
	end
end

-- Assumes inst is paused for effect of counting.
local function unpause(inst)
	inst:PushEvent(modname .. "_unpause")
	return true
end

local pause_folder, unpause_folder = NewCountFolder(pause), NewCountFolder(unpause)


local function freeze(inst)
	inst:PushEvent(modname .. "_freeze")
	return true
end

local function unfreeze(inst)
	inst:PushEvent(modname .. "_unfreeze")
	return true
end

local freeze_folder, unfreeze_folder = NewCountFolder(freeze), NewCountFolder(unfreeze)


function _G.sk()
	return gimme "snailking"
end

function _G.killsk()
	local count = Lambda.Fold( kill_folder, ipairs(FindAll()) )

	TheMod:Say("Killed ", count or 0, " Snail Kings.")
end

function _G.pausesk()
	local count = Lambda.Fold( pause_folder, ipairs(FindAll()) )

	TheMod:Say("Paused ", count or 0, " Snail Kings.")
end

function _G.unpausesk()
	local tags = {"snailking", modname .. "_paused"}

	local count = Lambda.Fold( unpause_folder, ipairs(FindAll(nil, tags)) )

	TheMod:Say("Unpaused ", count or 0, " Snail Kings.")
end

function _G.freezesk()
	local count = Lambda.Fold( freeze_folder, ipairs(FindAll()) )

	TheMod:Say("Froze ", count or 0, " Snail Kings.")
end

function _G.unfreezesk()
	local tags = {"snailking", modname .. "_paused"}

	local count = Lambda.Fold( unfreeze_folder, ipairs(FindAll(nil, tags)) )

	TheMod:Say("Unfroze ", count or 0, " Snail Kings. (estimate)")
end



--[[
--
-- Testing anims EventChain.
--
--]]

local AnimTestEventChain = EventChain(modname .. "_testanims")
do
	local c = AnimTestEventChain

	
	c:SetStartFn(pause)
	c:SetCancelFn(unpause)
	c:SetFinishFn(unpause)


	local function start(inst)
		if inst.components.talker then
			inst.components.talker:Say("Starting animation test...", 2, true)
		end
		return true
	end

	local function finish(inst)
		if inst.components.talker then
			inst.components.talker:Say("Finished animation test.", 2, true)
		end
		return true
	end

	local function AnimDoer(anim)
		return function(inst)
			if inst.components.talker then
				inst.components.talker:Say('Starting animation "' .. anim .. '"...', 2, true)
			end
			inst.AnimState:PlayAnimation(anim)
			return true
		end
	end

	local function AnimEnder(anim)
		return function(inst)
			if inst.components.talker then
				inst.components.talker:Say('Finished animation "' .. anim .. '".', 2, true)
			end
			return true
		end
	end


	local dt = TheMod:GetConfig("TESTING_ANIM_DELAY")
	local anims = TheMod:GetConfig("TESTING_ANIM_LIST")


	c:Append( start )
	c:Append( dt + 1 )
	
	for _, a in ipairs(anims) do
		c:Append( AnimDoer(a) )
		c:Append( "animover" )
		c:Append( AnimEnder(a) )
		c:Append( dt )
	end

	c:Append( 1 )
	c:Append( finish )
end
TheMod:AddPrefabPostInit("snailking", function(inst)
	if not inst.Label then
		inst.entity:AddLabel()
	end

	inst.Label:SetFontSize(32)
	inst.Label:SetFont(_G.TALKINGFONT)
	inst.Label:SetPos(0,4.5,0)
	inst.Label:SetColour(0.3, 0.1, 0.1)
	inst.Label:Enable(false)


	if not inst.components.talker then
		inst:AddComponent("talker")
	end

	AnimTestEventChain:Copy():Attach(inst):Enable()
end)


local function test_anims(inst)
	inst:PushEvent(modname .. "_testanims")
	return true
end

local function test_anims_folder(inst, total)
	local anim_angles = { 0, 180, 90, 270 }

	total = total or 0
	
	inst.Transform:SetRotation( anim_angles[1 + total%4] )
	test_anims(inst)

	return total + 1
end

function _G.playskanims()
	local count = Lambda.Fold( test_anims_folder, ipairs(FindAll()) )

	TheMod:Say("Playing the animations of ", count or 0, " Snail Kings.")
end
_G.testskanims = _G.playskanims
