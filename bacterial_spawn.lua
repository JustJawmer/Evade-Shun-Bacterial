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
    "default:sandstone",
    "default:ice",
    "default:desert_sandstone",
    "default:permafrost",
    "default:permafrost_with_most",
    "default:permafrost_with_stones",
    "default:silver_sandstone",
    "default:silver_sand",
    "default:cobblestone",
    "default:desert_cobble",
    "default:mossycobblestone",
    "default:wood",
    "default:junglewood",
    "default:pine_wood",
    "default:acacia_wood",
    "default:aspen_wood",
    "default:stone_block",
    "default:stonebrick",
    "default:stone_block",
    "default:desert_stone_block",
    "default:desert_stonebrick",
    "default:obsidian_block",
    "default:obsidianbrick",
    "default:glass",
    "default:sandstone_block",
}

local ep_storage = minetest.get_mod_storage()
if not ep_storage then
	ep_storage = {
		_store = {},
		get_string = function(self, k) return self._store[k] end,
		set_string = function(self, k, v) self._store[k] = v end,
	}
end


-- Phase 0: Bacterial Mound
mobs:spawn({
    name = "bacterial_mod:bacteria_blob",
    nodes = bacterial_spawns,
    neighbors = "air",
    min_light = 0,
    max_light = 10,
    chance = 3,
    on_spawn = function(self, pos)
        if self.spawn_reason == "nexus" then
            return true
        end

        local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
        if unlocked_phase_index ~= 0 then
            self.object:remove()
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
	chance = 3,
    on_spawn = function(self, pos)
        if self.spawn_reason == "nexus" then
            return true
        end

        local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
        if unlocked_phase_index ~= 0 and unlocked_phase_index ~= 1 then
            self.object:remove()
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
	chance = 10,
    on_spawn = function(self, pos)
        if self.spawn_reason == "nexus" then
            return true
        end

        local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
        if unlocked_phase_index ~= 1 then
            self.object:remove()
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
	chance = 5,
    on_spawn = function(self, pos)
        if self.spawn_reason == "nexus" then
            return true
        end

        local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
        if unlocked_phase_index ~= 2 and unlocked_phase_index ~= 3 then
            self.object:remove()
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
	chance = 5,
    on_spawn = function(self, pos)
        if self.spawn_reason == "nexus" then
            return true
        end

        local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
        if unlocked_phase_index ~= 2 and unlocked_phase_index ~= 3 then
            self.object:remove()
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
	chance = 5,
    on_spawn = function(self, pos)
        if self.spawn_reason == "nexus" then
            return true
        end

        local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
        if unlocked_phase_index ~= 2 and unlocked_phase_index ~= 3 then
            self.object:remove()
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
	chance = 5,
    on_spawn = function(self, pos)
        if self.spawn_reason == "nexus" then
            return true
        end

        local unlocked_phase_index = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
        if unlocked_phase_index ~= 2 and unlocked_phase_index ~= 3 then
            self.object:remove()
            return false
        end

        return true
    end,
})
