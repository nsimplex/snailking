--@@GLOBAL ENVIRONMENT BOOTUP
local _modname = assert( (assert(..., 'This file should be loaded through require.')):match('^[%a_][%w_%s]*') , 'Invalid path.' )
module( ..., package.seeall, require(_modname .. '.booter') )

--@@END ENVIRONMENT BOOTUP

require("stategraphs/commonstates")


local table = wickerrequire 'utils.table'

local death_anim_speed = TheMod:GetConfig("DEATH_ANIM_SPEED")


local actionhandlers = 
{
	--ActionHandler(ACTIONS.PICKUP, "doshortaction"),
	--ActionHandler(ACTIONS.EAT, "eat"),
	--ActionHandler(ACTIONS.CHOP, "chop"),
	--ActionHandler(ACTIONS.PICKUP, "pickup"),
}


local events=
{
	CommonHandlers.OnStep(),
	CommonHandlers.OnLocomote(true,true),
	CommonHandlers.OnSleep(),
	CommonHandlers.OnFreeze(),

	EventHandler("doattack", function(inst, data) if not inst.components.health:IsDead() then inst.sg:GoToState("attack", data.target) end end),
	EventHandler("death", function(inst) inst.sg:GoToState("death") end),
	EventHandler("attacked", function(inst) if inst.components.health:GetPercent() > 0 and not inst.sg:HasStateTag("attack") then inst.sg:GoToState("hit") end end),	
	
}


if TheMod:Debug() then
	table.append(events, {
		EventHandler(
			modname .. "_pause",
			function(inst)
				inst.sg:GoToState("pause")
			end
		),
		EventHandler(
			modname .. "_freeze",
			function(inst)
				inst.AnimState:Pause()
				inst.sg:GoToState("pause", true)
			end
		),
	})
end


local states=
{
	State{
		name = "idle",
		tags = {"idle", "canrotate"},
		
		onenter = function(inst, pushanim)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("idle_loop", true)
			inst.sg:SetTimeout(2 + 2*math.random())
		end,
		
		ontimeout=function(inst)
			local rand = math.random()
			if rand < .3 then
				inst.sg:GoToState("graze")
			elseif rand < .6 then
				inst.sg:GoToState("bellow")
			else
				inst.sg:GoToState("shake")
			end
		end,
	},

	State{
		name = "shake",
		tags = {"canrotate"},
		
		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("shake")
		end,
	   
		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},
	
	State{
		name = "bellow",
		tags = {"canrotate"},
		
		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("bellow")
			inst.SoundEmitter:PlaySound(inst.sounds.grunt)
		end,
	   
		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},
	
	State{
		name = "matingcall",
		tags = {},
		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("mating_taunt1")
			inst.SoundEmitter:PlaySound(inst.sounds.yell)
		end,
		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},
	
	State{
		name = "tailswish",
		tags = {},
		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("mating_taunt2")
		end,
		
		timeline=
		{
			TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.swish) end),
			TimeEvent(32*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.swish) end),
		},
		
		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},
	
	State{
		name="graze",
		tags = {"idle", "canrotate"},
		
		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("graze_loop", true)
			inst.sg:SetTimeout(5+math.random()*5)
		end,
		
		ontimeout= function(inst)
			inst.sg:GoToState("idle")
		end,

	},
	
	State{
		name = "alert",
		tags = {"idle", "canrotate"},
		
		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.SoundEmitter:PlaySound(inst.sounds.curious)
			inst.AnimState:PlayAnimation("alert_pre")
			inst.AnimState:PushAnimation("alert_idle", true)
		end,
	},
	
	State{
		name = "attack",
		tags = {"attack", "busy"},
		
		onenter = function(inst, target)	
			inst.sg.statemem.target = target
			inst.SoundEmitter:PlaySound(inst.sounds.angry)
			inst.components.combat:StartAttack()
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("atk_pre")
			inst.AnimState:PushAnimation("atk", false)
		end,
		
		
		timeline=
		{
			TimeEvent(15*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
		},
		
		events=
		{
			EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
		},
	},	
	
	State{
		name = "death",
		tags = {"busy"},
	
		--[[
		onenter = function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.yell)
			inst.AnimState:PlayAnimation("death")
			inst.Physics:Stop()
			RemovePhysicsColliders(inst)			
			inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))			
		end,
		]]--

		onenter = function(inst)
			inst.Physics:Stop()

			if death_anim_speed then
				inst.AnimState:SetDeltaTimeMultiplier(death_anim_speed)
				inst.components.health.nofadeout = true
			end

			if inst.components.health.nofadeout then
				inst:AddTag("NOCLICK")
				inst.persists = false
				inst:DoTaskInTime(2/death_anim_speed, inst.Remove)
			end
			
			inst.AnimState:PlayAnimation("hair_growth_pre")
		end,

		events = {
			EventHandler("animover", function(inst) inst.sg:GoToState("death_pop") end),
		},
		
	},

	State{
		name = "death_pop",
		tags = {"busy"},

		onenter = function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/explode")
			--inst.SoundEmitter:PlaySound("dontstarve/beefalo/hairgrow_pop")
			inst.AnimState:PlayAnimation("hair_growth")
		end,

		onexit = function(inst)
			inst.AnimState:SetBuild("snailking_death_build")
		end,
		
		events = {
			--EventHandler("animover", function(inst) inst.sg:GoToState("death_finalize") end),
		},

		timeline = {
			TimeEvent(TheMod:GetConfig("SNAILKING_HAIR_GROWTH_FRAMES")*FRAMES, function(inst) inst.sg:GoToState("death_finalize") end),
		},
	},

	State{
		name = "death_finalize",
		tags = {"busy"},

		onenter = function(inst)
			RemovePhysicsColliders(inst)			
			inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))			
			inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/death")
			inst.AnimState:PlayAnimation("death")
		end,
	},

	
	State{
		name = "hair_growth",
		tags = {"busy"},
		
		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("hair_growth_pre")
			inst.SoundEmitter:PlaySound("dontstarve/beefalo/hairgrow_vocal")
		end,
		
		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("hair_growth_pop") end),
		},
	},
}


if TheMod:Debug() then
	table.append(states, {
		State{
			name = "pause",
			tags = {"pause", "busy", "canrotate"},
			
			onenter = function(inst, skip_anim)
				if not inst:HasTag(modname .. "_paused") then
					inst:AddTag(modname .. "_paused")
				end
				inst.components.locomotor:StopMoving()
				inst:StopBrain()
				if not skip_anim then
					inst.AnimState:PlayAnimation("idle_loop", true)
				end
			end,

			onexit = function(inst)
				if inst:HasTag(modname .. "_paused") then
					inst:RemoveTag(modname .. "_paused")
				end
				inst:RestartBrain()
				inst.AnimState:Resume()
			end,

			events = {
				EventHandler(modname .. "_unpause", function(inst) inst.sg:GoToState("idle") end),
				EventHandler(modname .. "_unfreeze", function(inst) inst.AnimState:Resume() end),
			},
		},
	})
end



CommonStates.AddWalkStates(
	states,
	{
		walktimeline = 
		{ 
			TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.walk) end),
			TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.walk) end),
		}
	})
	
CommonStates.AddRunStates(
	states,
	{
		runtimeline = 
		{ 
			TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.walk) end),
		}
	})

CommonStates.AddSimpleState(states,"hit", "hit")
CommonStates.AddFrozenStates(states)

CommonStates.AddSleepStates(states,
{
	sleeptimeline = 
	{
		TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.grunt) end)
	},
})
	
return StateGraph("snailking", states, events, "idle", actionhandlers)

