------
---- [Default configurations]
----
---- Modify rc.lua instead.
------


return function()
	---
	--- All measures of time are in seconds.
	---
	
	STRINGS.NAMES.SNAILKING = "Snail King"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.SNAILKING = "It's a... thing. A big one."
	
	---[[
	-- Which build to use. Options are "snailking_build" and "snailking_death_build",
	-- the latter being based on the "beefalo_shaved_build".
	-- 
	-- I don't think there's any point changing this anymore.
	---]]
	SNAILKING_BUILD = "snailking_build"
	
	--[[
	-- How many frames to play of the "hair growth" anim on death.
	--
	-- The full animation is 17 frames long.
	--]]
	SNAILKING_HAIR_GROWTH_FRAMES = 12
	
	--[[
	-- Speed of the death animation, relative to its base speed.
	--]]
	DEATH_ANIM_SPEED = 0.2
	
	
	-- Scaling of the Snail King, relative to a Beefalo's size.
	SCALE_X = 2
	SCALE_Y = SCALE_X
	SCALE_Z = SCALE_X
	
	
	-- Time between consecutive animations during testing.
	TESTING_ANIM_DELAY = 1
	
	-- List of animations to test.
	TESTING_ANIM_LIST = {"idle_loop", "shake", "bellow", "mating_taunt1", "mating_taunt2", "graze_loop", "alert_pre", "alert_idle", "atk_pre", "atk", "death", "hair_growth_pre", "hair_growth", "shave"}
	
		
	-- Turn on debugging.
	DEBUG = true
end
