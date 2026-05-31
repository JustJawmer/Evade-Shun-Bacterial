local bacterial_spawns = {
	"default:dirt_with_grass",
	"default:dirt",
	"default:sand",
	"default:stone",
	"default:gravel",
	"default:snow",
	"default:snowblock",
	"default:desert_sand",
	"default:desert_stone",
	"default:cobble",
	"default:mossycobble",
}

local ep_storage = minetest.get_mod_storage()
if not ep_storage then
	ep_storage = {
		_store = {},
		get_string = function(self, k) return self._store[k] end,
		set_string = function(self, k, v) self._store[k] = v end,
	}
end

-- Function to check if any Nexus entities are within 100 blocks
local function is_nexus_nearby(pos)
	return bacterial_mod.is_nexus_nearby(pos)
end

-- Phase 0: Bacterial Mound
mobs:spawn({
	name = "bacterial_mod:bacteria_blob",
	nodes = bacterial_spawns,
	neighbors = "air",
	min_light = 0,
	max_light = 7,
	chance = 1000,
	on_spawn = function(self, pos)
		local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
		if unlocked_phase_index ~= 0 then
			return false
		end
		return true
	end,
})

-- Phase 1: Small Flesh Blob
mobs:spawn({
	name = "bacterial_mod:small_flesh_amalgamation",
	nodes = bacterial_spawns,
	neighbors = "air",
	min_light = 0,
	max_light = 7,
	chance = 1000,
	on_spawn = function(self, pos)
		local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
		if unlocked_phase_index ~= 1 then
			return false
		end
		return true
	end,
})

-- Phase 1: Flesh Amalgamation
mobs:spawn({
	name = "bacterial_mod:flesh_amalgamation",
	nodes = bacterial_spawns,
	neighbors = "air",
	min_light = 0,
	max_light = 7,
	chance = 2000,
	on_spawn = function(self, pos)
		local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
		if unlocked_phase_index ~= 1 then
			return false
		end
		return true
	end,
})

-- Phase 2+: Infected Animals (placeholder for Phase 4 Primitive mobs)
mobs:spawn({
	name = "bacterial_mod:infected_cow",
	nodes = bacterial_spawns,
	neighbors = "air",
	min_light = 0,
	max_light = 7,
	chance = 1000,
	on_spawn = function(self, pos)
		local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
		if unlocked_phase_index < 2 then
			return false
		end
		return true
	end,
})

mobs:spawn({
	name = "bacterial_mod:infected_sheep",
	nodes = bacterial_spawns,
	neighbors = "air",
	min_light = 0,
	max_light = 7,
	chance = 1000,
	on_spawn = function(self, pos)
		local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
		if unlocked_phase_index < 2 then
			return false
		end
		return true
	end,
})

mobs:spawn({
	name = "bacterial_mod:infected_pig",
	nodes = bacterial_spawns,
	neighbors = "air",
	min_light = 0,
	max_light = 7,
	chance = 1000,
	on_spawn = function(self, pos)
		local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
		if unlocked_phase_index < 2 then
			return false
		end
		return true
	end,
})

mobs:spawn({
	name = "bacterial_mod:infected_human",
	nodes = bacterial_spawns,
	neighbors = "air",
	min_light = 0,
	max_light = 7,
	chance = 1000,
	on_spawn = function(self, pos)
		local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
		if unlocked_phase_index < 2 then
			return false
		end
		return true
	end,
})

