--@@ENVIRONMENT BOOTUP
local _modname = assert( (assert(..., 'This file should be loaded through require.')):match('^[%a_][%w_%s]*') , 'Invalid path.' )
module( ..., require(_modname .. '.booter') )

--@@END ENVIRONMENT BOOTUP

local assets=
{
	Asset("ANIM", "anim/snailking_build.zip"),
	Asset("ANIM", "anim/snailking_death_build.zip"),

	Asset("ANIM", "anim/beefalo_basic.zip"),
	Asset("ANIM", "anim/beefalo_actions.zip"),
	Asset("ANIM", "anim/beefalo_heat_build.zip"),
	Asset("ANIM", "anim/beefalo_shaved_build.zip"),
	Asset("SOUND", "sound/beefalo.fsb"),
}

local prefabs =
{
	"slurtle_shellpieces",
}

local loot = {"slurtle_shellpieces", "slurtle_shellpieces"}

local sounds = 
{
    walk = "dontstarve/beefalo/walk",
    grunt = "dontstarve/beefalo/grunt",
    yell = "dontstarve/beefalo/yell",
    swish = "dontstarve/beefalo/tail_swish",
    curious = "dontstarve/beefalo/curious",
    angry = "dontstarve/beefalo/angry",
}


local function Retarget(inst)
end

local function KeepTarget(inst, target)
	return distsq(inst:GetPosition(), target:GetPosition()) < 64
end

local function OnNewTarget(inst, data)
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end


local function fn(Sim)
	local CONFIG = TheMod:GetConfig()

	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local sound = inst.entity:AddSoundEmitter()
	local shadow = inst.entity:AddDynamicShadow()
	inst.sounds = sounds

	inst:AddTag("snailking")

	trans:SetTwoFaced()
	trans:SetScale( CONFIG.SCALE_X, CONFIG.SCALE_Y, CONFIG.SCALE_Z )
	shadow:SetSize( 6*CONFIG.SCALE_X, 2*CONFIG.SCALE_Z )

	_G.MakeCharacterPhysics(inst, 1000, .5)
	
	anim:SetBank("beefalo")
	--anim:SetBuild("snailking_build")
	anim:SetBuild(CONFIG.SNAILKING_BUILD)
	anim:PlayAnimation("idle_loop", true)
	
	inst:AddTag("animal")
	inst:AddTag("largecreature")
	inst:AddTag("epic")


	inst:AddComponent("eater")
	inst.components.eater:SetElemental()
	
	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "beefalo_body"
	inst.components.combat:SetDefaultDamage(10)
	inst.components.combat:SetRetargetFunction(1, Retarget)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	 
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth( 250 )
	--TEMPORARY!!!
	if TheMod:GetConfig("DEATH_ANIM_SPEED") then
		inst.components.health.nofadeout = true
	end

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot(loot)
	
	inst:AddComponent("inspectable")
	
	_G.MakeLargeBurnableCharacter(inst, "beefalo_body")
	_G.MakeLargeFreezableCharacter(inst, "beefalo_body")
	
	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.walkspeed = 1.5
	inst.components.locomotor.runspeed = 3


	inst:ListenForEvent("newcombattarget", OnNewTarget)
	inst:ListenForEvent("attacked", OnAttacked)

	
	inst:SetBrain(require "brains/snailkingbrain")
	inst:SetStateGraph("SGsnailking")

	return inst
end

return Prefab( "cave/snailking", fn, assets, prefabs) 
