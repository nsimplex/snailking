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

local package = package

--@@ENVIRONMENT BOOTUP
local _modname = assert( (assert(..., 'This file should be loaded through require.')):match('^[%a_][%w_%s]*') , 'Invalid path.' )
module( ..., require(_modname .. '.booter') )

--@@END ENVIRONMENT BOOTUP

local Lambda = wickerrequire 'paradigms.functional'
local Iterator = Lambda.iterator
local Logic = wickerrequire 'paradigms.logic'

local Pred = wickerrequire 'lib.predicates'

local Debuggable = wickerrequire 'gadgets.debuggable'


-- Key, used as an index to a Mod object, leading to a table with a field
-- 'add', storing the direct Add methods (such as AddLevel) specs, and 
-- 'hook', storing the AddPostInit and AddPreInit methods specs.
local initspec_key = {}


local Mod = Class(Debuggable, function(self)
	Debuggable._ctor(self, 'TheMod', false)

	self[initspec_key] = { add = {}, hook = {} }
end)

Pred.IsMod = Pred.IsInstanceOf(Mod)

function ModCheck(self)
	assert( Pred.IsMod(self), "Don't forget to use ':'!" )
end


-- Normalizes an Add- or hook id.
local function normalize_id(id)
	assert( Pred.IsWordable(id), "Invalid id given to Add- method." )
	return tostring(id):lower()
end

-- Assumes normalized.
local function get_add_spec(self, id)
	return self[initspec_key].add[id]
end

-- Assumes normalized.
local function get_hook_spec(self, id)
	return self[initspec_key].hook[id]
end


-- Slurps a mod environment (either from modmain or modworldgenmain)
function Mod:SlurpEnvironment(env, overwrite)
	assert( type(env) == "table" )

	if overwrite == nil then overwrite = true end

	local add_specs = self[initspec_key].add
	local hook_specs = self[initspec_key].hook

	for k, v in pairs(env) do
		if type(k) == 'string' then
			local stem = k:match('^Add(.+)$')
			if stem then
				local id, when
				local specs_table = hook_specs

				id = stem:match("^(.-)PostInit$")
				if id then
					when = "Post"
				else
					id = stem:match("^(.-)PreInit$")
					if id then
						when = "Pre"
					else
						id = stem
						specs_table = add_specs
					end
				end

				local norm_id = normalize_id(id)

				if overwrite or specs_table[norm_id] == nil then
					specs_table[norm_id] = {
						id = id,
						fn = v,
						full_name = k,
					}

					if when then
						specs_table[norm_id].when = when:lower()
					end
				end

				if rawget(self, k) == nil then
					local method
					if when then
						method = self["Add" .. when .. "Init"]
					else
						method = self.Add
					end

					assert( Lambda.IsFunctional(method) )

					self[k] = function(self, ...)
						ModCheck(self)
						return method(self, norm_id, ...)
					end
				end
			end
		end
	end
end


local function do_main(mainname, ...)
	local main
	local M = modrequire(mainname)
	if type(M) == "function" then
		main = M
	elseif type(M) == "table" then
		main = M.main
		if not Lambda.IsFunctional( main ) then
			main = M[mainname]
			if not Lambda.IsFunctional( main ) then
				main = Lambda.Find(
					function(v, k) return Lambda.IsFunctional(v) and Pred.IsString(k) and k:lower() == 'main' end,
					pairs( M )
				)
				if not Lambda.IsFunctional( main ) then
					local lowmain = mainname:lower()
					main = Lambda.Find(
						function(v, k) return Lambda.IsFunctional(v) and Pred.IsString(k) and k:lower() == lowmain end,
						pairs( M )
					)
				end
			end
		end
	end

	if not Lambda.IsFunctional( main ) then
		--self:Notify("Unable to find a suitable main function from the return value of wickerrequire('" .. mainname .. "').")
		return
	end

	return main(...)
end

local function raw_Run(self, mainname, ...)
	ModCheck(self)

	assert( Pred.IsWordable(mainname), "The main's name should be a string." )
	mainname = tostring(mainname)

	return do_main(mainname, ...)
end

function Mod:Run(mainname, ...)
	return RobustlyCall(raw_Run, self, mainname, ...)
end


local function call_add_fn(self, spec, ...)
	if self:Debug() then
		local ArgNames = Lambda.CompactlyMap(function(arg, i)
			if Pred.IsWordable(arg) then
				return ("%q"):format(tostring(arg))
			else
				return '[' .. tostring(arg) .. ']'
			end
		end, ipairs{...})
		self:Notify('Calling ', spec.full_name, '(' .. table.concat(ArgNames, ', '), ')')
	end

	local Rets = {spec.fn( ... )}

	return unpack(Rets)
end


function Mod:Add(id, ...)
	ModCheck(self)
	local spec = get_add_spec( self, normalize_id(id) )
	if not spec then return error(("Invalid Add- id %q"):format(id)) end
	return call_add_fn(self, spec, ...)
end


local function Mod_HookAdder(self, spec, branch, reached_leaf)
	local function parameter_iterator(x, ...)
		if x == nil then
			assert( select('#', ...) == 0, "nil given as a hook-adding argument." )
			return parameter_iterator
		end

		assert( not reached_leaf or Lambda.IsFunctional(x), "Function expected as a postinit setup argument." )

		if Lambda.IsFunctional(x) then
			table.insert(branch, x)
			call_add_fn(self, spec, unpack(branch))
			table.remove(branch)
			reached_leaf = true
		elseif type(x) == "table" then
			-- We create new closures that leave our current upvalues alone.
			local hookadder_branches = Lambda.CompactlyMap(function(v, i)
				return Mod_HookAdder(self, spec, Lambda.InjectInto({}, ipairs(branch)), reached_leaf)(v)
			end, ipairs(x))
			
			local function multiplier(...)
				for i, v in ipairs(hookadder_branches) do
					hookadder_branches[i] = v(...)
				end
				return multiplier
			end

			return multiplier(...)
		else
			if Pred.IsWordable(x) then
				x = tostring(x)
			end

			table.insert(branch, x)
		end

		return parameter_iterator(...)
	end

	return parameter_iterator
end

function Mod:AddHook(id, ...)
	ModCheck(self)
	local spec = get_hook_spec( self, normalize_id(id) )
	if not spec then return error(("Invalid hook id %q"):format(id)) end
	return Mod_HookAdder(self, spec, {})(...)
end

for _, when in ipairs{"Pre", "Post"} do
	local when_low = when:lower()

	Mod["Add" .. when .. "Init"] = function(self, id, ...)
		ModCheck(self)
		local spec = get_hook_spec( self, normalize_id(id) )
		if not spec or spec.when ~= when_low then return error(("Invalid %sInit id %q"):format(when, id)) end
		return Mod_HookAdder(self, spec, {})(...)
	end
end


return function()
	local TheMod = Mod()

	_M.TheMod = TheMod

	Lambda.ConceptualizeSingletonObject( TheMod, _M )

	package.loaded[_NAME] = _M

	return TheMod
end
