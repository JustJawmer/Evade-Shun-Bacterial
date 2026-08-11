local function spawn_mold_around(pos, radius)
    radius = radius or 2
    for x = -radius, radius do
        for z = -radius, radius do
            if math.abs(x) + math.abs(z) <= radius then
                local check_pos = {x = pos.x + x, y = pos.y, z = pos.z + z}
                local node = minetest.get_node(check_pos)
                if node.name == "air" then
                    local below_pos = {x = check_pos.x, y = check_pos.y - 1, z = check_pos.z}
                    local below_node = minetest.get_node(below_pos)
                    if below_node.name ~= "air" and below_node.name ~= "bacterial_mod:mold" then
                        minetest.set_node(check_pos, {name = "bacterial_mod:mold"})
                    end
                end
            end
        end
    end
end

local ep_storage = minetest.get_mod_storage()
if not ep_storage then
	ep_storage = {
		_store = {},
		get_string = function(self, k) return self._store[k] end,
		set_string = function(self, k, v) self._store[k] = v end,
	}
end


local nexus_stage_1_spawn_mobs = {
	"bacterial_mod:bacteria_blob",
	"bacterial_mod:small_flesh_amalgamation",
	"bacterial_mod:flesh_amalgamation",
}

local nexus_infected_mobs = {
	"bacterial_mod:bacteria_blob",
	"bacterial_mod:infected_cow",
	"bacterial_mod:infected_sheep",
	"bacterial_mod:infected_pig",
	"bacterial_mod:infected_human",
	"bacterial_mod:flesh_amalgamation",
	"bacterial_mod:small_flesh_amalgamation",
}

local function attempt_spawn_stage_1_nexus(pos)
	local phase = tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
	local max_roll

	if phase == 3 then
		max_roll = 21
	elseif phase == 4 then
		max_roll = 16
	elseif phase == 5 then
		max_roll = 11
	elseif phase == 6 then
		max_roll = 8
	elseif phase == 7 or phase == 8 then
		max_roll = 3
	else
		return
	end

	if math.random(max_roll) == max_roll then
		minetest.add_entity(pos, "bacterial_mod:nexus_stage_1")
	end
end

local function nexus_random_spawn(name_list)
	return name_list[math.random(#name_list)]
end

local function nexus_spawn_mobs_around(pos, name_list, min_count, max_count)
	if not pos or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
		return
	end

	local count = math.random(min_count, max_count)
	for i = 1, count do
		local angle = math.random() * 2 * math.pi
		local distance = math.random(3, 10)
		local new_pos = {
			x = pos.x + math.cos(angle) * distance,
			y = pos.y + 1,
			z = pos.z + math.sin(angle) * distance,
		}
		local mobname = nexus_random_spawn(name_list)
		local obj = minetest.add_entity(new_pos, mobname)
		if obj then
			local ent = obj:get_luaentity()
			if ent then
				ent.spawn_reason = "nexus"
			end
		end
	end
end

-- Safe helper stubs for nexus behavior. These prevent runtime errors
-- when the functions are referenced by nexus entities. They are
-- conservative: do not change game state aggressively.
local function nexus_apply_gravity_step(self, dtime)
    if not self or not self.object or not dtime then return end
    local pos = self.object:get_pos()
    if not pos then return end

    -- Consider the node slightly below the entity as ground check
    local below_pos = {x = pos.x, y = pos.y - 0.6, z = pos.z}
    local below_node = minetest.get_node_or_nil(below_pos)
    local unsupported = false
    if not below_node then
        unsupported = true
    else
        unsupported = (below_node.name == "air")
    end

    local gravity = 9.8
    local terminal = -50
    local ok, vel = pcall(function() return self.object:get_velocity() end)
    vel = (ok and vel) or {x = 0, y = 0, z = 0}

    if unsupported then
        -- Apply downward acceleration (simple Euler integration)
        local newy = (vel.y or 0) - gravity * dtime
        if newy < terminal then newy = terminal end
        pcall(function() self.object:set_velocity({x = vel.x or 0, y = newy, z = vel.z or 0}) end)
        pcall(function() self.object:set_acceleration({x = 0, y = 0, z = 0}) end)
    else
        -- On ground: stop downward movement and zero vertical velocity
        if (vel.y or 0) < 0.1 then
            pcall(function() self.object:set_velocity({x = vel.x or 0, y = 0, z = vel.z or 0}) end)
            pcall(function() self.object:set_acceleration({x = 0, y = 0, z = 0}) end)
        end
    end
end

local function nexus_regenerate(self, dtime, hp_per_second)
    if not self or not dtime or not hp_per_second then return end
    if not (self.object and self.object.get_hp and self.object.set_hp) then return end
    local ok, hp = pcall(function() return self.object:get_hp() end)
    if not ok or type(hp) ~= "number" then return end
    local new_hp = math.min((self.hp_max or hp), hp + hp_per_second * dtime)
    pcall(function() self.object:set_hp(new_hp) end)
end

local function nexus_apply_damage_reduction(self, damage)
    -- Placeholder: currently a no-op to avoid altering damage mechanics.
    -- Implement reductions here if desired.
    return damage
end


mobs:register_mob("bacterial_mod:bacteria_blob", {
    type = "bacterial",
    passive = false,
    attack_type = "dogfight",
    attack_monsters = true, -- Attacks other monsters
    attack_animals = true, -- Attacks passive mobs like sheep or cows
    attack_players = true, --  This enables mob-on-mob aggression
    damage = 2,
    reach = 2.5,
    hp_max = 8,
    armor = 100,
    view_range = 50,
    collisionbox = {-0.1, 0, -0.1, 0.5, 0.8, 0.5},
    visual_size = {x = 3, y = 3},
    visual = "mesh",
    mesh = "Bacterial_Mound.b3d",
    textures = {
        {"blob_texture.png"},
    },
        attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_amalgamation",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = false,
    walk_velocity = 2,
    run_velocity = 3,
    jump = true,
    sounds = {
        distance = 7,
        random = "flesh_hit",
        death = "wet1",
        damage = "wet1",
    },
    drops = {
        {name = "bacterial_mod:Flesh", chance = 1, min = 1, max = 2},
    },
    lava_damage = 5,
    light_damage = 0,
    fear_height = 3,
    on_spawn = function(self, pos)
        -- Allow spawning in any phase for testing purposes
        return true
    end,

    on_step = function(self, dtime)
        self.mold_timer = (self.mold_timer or 0) + dtime
        if self.mold_timer >= 30 then
            local pos = self.object:get_pos()
            spawn_mold_around(pos, 2)
            self.mold_timer = 0
        end
    end,
    on_die = function(self, pos)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
        evolution_points = evolution_points - 1
        if evolution_points < 0 then evolution_points = 0 end
        ep_storage:set_string("evolution_points", tostring(evolution_points))
        
        -- 40% chance of normal death, 60% chance of explosion with mold spawn
        if math.random(100) <= 5 then
            -- Normal death
            attempt_spawn_stage_1_nexus(pos)
        else
            -- Explosion death: spawn 3x3 mold area after 3 seconds
            minetest.sound_play("Flesh_Explosion", {pos = pos, gain = 1.0, max_hear_distance = 32})
            minetest.after(0.1, function()
                -- Spawn 3x3 area of mold, only replacing air
                for x = 0, 1 do
                    for z = 0, 1 do
                        local check_pos = {x = pos.x + x, y = pos.y, z = pos.z + z}
                        local node = minetest.get_node(check_pos)
                        if node.name == "air" then
                            -- Check that there's solid ground below
                            local below_pos = {x = check_pos.x, y = check_pos.y - 1, z = check_pos.z}
                            local below_node = minetest.get_node(below_pos)
                            if below_node.name ~= "air" and below_node.name ~= "bacterial_mod:mold" then
                                minetest.set_node(check_pos, {name = "bacterial_mod:mold"})
                            end
                        end
                    end
                end
            end)
        end
    end,
})


-- ============================================================================
-- INFECTED COW MOB
-- ============================================================================
-- High-threat infected animal with long sight and large reach.

mobs:register_mob("bacterial_mod:infected_cow", {
    type = "bacterial",
    passive = false,
    attack_type = "dogfight",
    attack_monsters = true, -- Attacks other monsters
    attack_animals = true, -- Attacks passive mobs like sheep or cows
    attack_players = true, --  This enables mob-on-mob aggression
    damage = 8,
    reach = 2.5,
    hp_max = 20,
    armor = 100,
    view_range = 40,
    collisionbox = {-0.5, 0, -0.5, 0.5, 1.3, 0.5},
    visual_size = {x = 1, y = 1},
    visual = "mesh",
    mesh = "Infected_Cow.b3d",
    textures = {
        {"Infected_Cow.png"},
    },
        attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_amalgamation",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = false,
    sounds = {
        distance = 10,
        random = "cow1",
        damage = "cow2",
    },
    walk_velocity = 2,
    run_velocity = 5,
    jump = true,
    drops = {
        {name = "bacterial_mod:Flesh", chance = 1, min = 1, max = 2},
    },
    lava_damage = 5,
    light_damage = 0,
    fear_height = 10,
    on_spawn = function(self, pos)
        -- Allow Nexus spawns
        if self.spawn_reason == "nexus" then
            return true
        end

    -- No phase logic here
        return true
    end,

    animation = {
        stand_start = 0,
        stand_end = 40,
        walk_start = 41,
        walk_end = 100,
        run_start = 101,
        run_end = 145,
        die_start = 148,
        die_end = 170,
    },
    on_step = function(self, dtime)
        self.mold_timer = (self.mold_timer or 0) + dtime
        if self.mold_timer >= 30 then
            local pos = self.object:get_pos()
            spawn_mold_around(pos, 2)
            self.mold_timer = 0
        end
    end,
    on_die = function(self, pos)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
        evolution_points = evolution_points - 3
        if evolution_points < 0 then evolution_points = 0 end
        ep_storage:set_string("evolution_points", tostring(evolution_points))
        
        -- 40% chance of normal death, 60% chance of explosion with mold spawn
        if math.random(100) <= 35 then
            -- Normal death
            attempt_spawn_stage_1_nexus(pos)
        else
            -- Explosion death: spawn 3x3 mold area after 3 seconds
            minetest.sound_play("Explosions", {pos = pos, gain = 1.0, max_hear_distance = 32})
            minetest.after(0.1, function()
                -- Spawn 3x3 area of mold, only replacing air
                for x = -2, 2 do
                    for z = -2, 2 do
                        local check_pos = {x = pos.x + x, y = pos.y, z = pos.z + z}
                        local node = minetest.get_node(check_pos)
                        if node.name == "air" then
                            -- Check that there's solid ground below
                            local below_pos = {x = check_pos.x, y = check_pos.y - 1, z = check_pos.z}
                            local below_node = minetest.get_node(below_pos)
                            if below_node.name ~= "air" and below_node.name ~= "bacterial_mod:mold" then
                                minetest.set_node(check_pos, {name = "bacterial_mod:mold"})
                            end
                        end
                    end
                end
            end)
        end
    end,
})


-- ============================================================================
-- FLESH AMALGAMATION MOB
-- ============================================================================
-- This is the default replacement mob that appears when other mobs are killed
-- by bacterial_mod mobs. It represents a grotesque fusion of biological matter.

mobs:register_mob("bacterial_mod:flesh_amalgamation", {
    type = "bacterial",
    passive = false,
    attack_type = "dogfight",
    attack_monsters = true,
    attack_animals = true,
    attack_players = true,
    damage = 4,
    reach = 2.2,
    hp_max = 14,
    armor = 100,
    view_range = 50,
    collisionbox = {-0.35, -0.01, -0.35, 0.35, 1.0, 0.35},
    visual_size = {x = 1.2, y = 1.2},
    visual = "mesh",
    mesh = "Large_Flesh.b3d",  -- Reuse existing mesh or create specialized model
    textures = { 
        {"Small_Flesh_Texture.png"},
    },
        attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_amalgamation",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = true,
    sounds = {
        distance = 7,
        random = "flesh_hit",
        death = "wet1",
        damage = "wet1",
    },

    walk_velocity = 2,
    run_velocity = 5,
    jump = true,
    jump_height = 15,
    can_leap = true,
    fall_damage = false,

    lava_damage = 8,
    light_damage = 0,
    fear_height = 15,
    on_spawn = function(self, pos)
        -- Allow Nexus spawns
        if self.spawn_reason == "nexus" then
            return true
        end

    -- No phase logic here
        return true
    end,
    
    animation = {
        stand_start = 0,
        stand_end = 100,
        walk_start = 101,
        walk_end = 140,
        walk_speed = 17.5,
        run_start = 141,
        run_end = 155,
        run_speed = 25,
        jump_start = 156,
        jump_end = 170,
    },
        on_step = function(self, dtime)
        self.mold_timer = (self.mold_timer or 0) + dtime
        if self.mold_timer >= 30 then
            local pos = self.object:get_pos()
            spawn_mold_around(pos, 2)
            self.mold_timer = 0
        end
    end,
    on_die = function(self, pos)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
        evolution_points = evolution_points - 1
        if evolution_points < 0 then evolution_points = 0 end
        ep_storage:set_string("evolution_points", tostring(evolution_points))
        
        -- 40% chance of normal death, 60% chance of explosion with mold spawn
        if math.random(100) <= 20 then
            -- Normal death
            attempt_spawn_stage_1_nexus(pos)
        else
            -- Explosion death: spawn 3x3 mold area after 3 seconds
            minetest.sound_play("Flesh_Explosion", {pos = pos, gain = 1.0, max_hear_distance = 32})
            minetest.after(0.1, function()
                -- Spawn 3x3 area of mold, only replacing air
                for x = -1, 1 do
                    for z = -1, 1 do
                        local check_pos = {x = pos.x + x, y = pos.y, z = pos.z + z}
                        local node = minetest.get_node(check_pos)
                        if node.name == "air" then
                            -- Check that there's solid ground below
                            local below_pos = {x = check_pos.x, y = check_pos.y - 1, z = check_pos.z}
                            local below_node = minetest.get_node(below_pos)
                            if below_node.name ~= "air" and below_node.name ~= "bacterial_mod:mold" then
                                minetest.set_node(check_pos, {name = "bacterial_mod:mold"})
                            end
                        end
                    end
                end
            end)
        end
    end,
})



-- ============================================================================
-- SMALL FLESH AMALGAMATION MOB
-- ============================================================================
-- A smaller version of the flesh amalgamation.

mobs:register_mob("bacterial_mod:small_flesh_amalgamation", {
    type = "bacterial",
    passive = false,
    attack_type = "dogfight",
    attack_monsters = true,
    attack_animals = true,
    attack_players = true,
    damage = 5,
    reach = 2.5,
    hp_max = 4,
    armor = 100,
    view_range = 45,
    collisionbox = {-0.3, -0.01, -0.3, 0.3, 0.8, 0.3},
    visual_size = {x = 1.5, y = 1.5},
    visual = "mesh",
    mesh = "Small_Flesh.b3d",
    textures = { 
        {"Small_Flesh_Texture.png"},
    },
        attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_amalgamation",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = true,
    sounds = {
        distance = 7,
        random = "flesh_hit",
        death = "wet1",
        damage = "wet1",
    },

    walk_velocity = 4,
    run_velocity = 10,
    jump = true,
    jump_height = 10,
    can_leap = true,
    fall_damage = false,

    lava_damage = 8,
    light_damage = 0,
    fear_height = 15,
    on_spawn = function(self, pos)
        -- Allow Nexus spawns
        if self.spawn_reason == "nexus" then
            return true
        end

    -- No phase logic here
        return true
    end,
    
    animation = {
        stand_start = 0,
        stand_end = 100,
        walk_start = 101,
        walk_end = 140,
        walk_speed = 35,
        run_start = 141,
        run_end = 155,
        run_speed = 50,
        jump_start = 156,
        jump_end = 170,
    },
    on_step = function(self, dtime)
        self.mold_timer = (self.mold_timer or 0) + dtime
        if self.mold_timer >= 30 then
            local pos = self.object:get_pos()
            spawn_mold_around(pos, 2)
            self.mold_timer = 0
        end
    end,
    on_die = function(self, pos)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
        evolution_points = evolution_points - 1
        if evolution_points < 0 then evolution_points = 0 end
        ep_storage:set_string("evolution_points", tostring(evolution_points))
        
        -- 40% chance of normal death, 60% chance of explosion with mold spawn
        if math.random(100) <= 10 then
            -- Normal death
            attempt_spawn_stage_1_nexus(pos)
        else
            -- Explosion death: spawn 3x3 mold area after 3 seconds
            minetest.sound_play("Flesh_Explosion", {pos = pos, gain = 1.0, max_hear_distance = 32})
            minetest.after(0.1, function()
                -- Spawn 3x3 area of mold, only replacing air
                for x = 0, 2 do
                    for z = 0, 2 do
                        local check_pos = {x = pos.x + x, y = pos.y, z = pos.z + z}
                        local node = minetest.get_node(check_pos)
                        if node.name == "air" then
                            -- Check that there's solid ground below
                            local below_pos = {x = check_pos.x, y = check_pos.y - 1, z = check_pos.z}
                            local below_node = minetest.get_node(below_pos)
                            if below_node.name ~= "air" and below_node.name ~= "bacterial_mod:mold" then
                                minetest.set_node(check_pos, {name = "bacterial_mod:mold"})
                            end
                        end
                    end
                end
            end)
        end
    end,
})


-- ============================================================================
-- INFECTED SHEEP MOB
-- ============================================================================
-- Infected version of a sheep.

mobs:register_mob("bacterial_mod:infected_sheep", {
    type = "bacterial",
    passive = false,
    attack_type = "dogfight",
    attack_monsters = true,
    attack_animals = true,
    attack_players = true,
    damage = 6,
    reach = 2.5,
    hp_max = 18,
    armor = 100,
    view_range = 40,
    collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.0, 0.3},
    visual_size = {x = 1, y = 1},
    visual = "mesh",
    mesh = "InfSheep.b3d",
    textures = {
        {"Inf_Sheep_Texture.png"},
    },
        attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_amalgamation",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = true,
    sounds = {
        distance = 10,
        random = "sheep1",
        damage = "sheep2",
    },

    walk_velocity = 3,
    run_velocity = 7,
    jump = true,
    drops = {
        {name = "bacterial_mod:Flesh", chance = 1, min = 1, max = 2},
    },
    lava_damage = 8,
    light_damage = 0,
    fear_height = 4,
    on_spawn = function(self, pos)
        -- Allow Nexus spawns
        if self.spawn_reason == "nexus" then
            return true
        end

    -- No phase logic here
        return true
    end,
    
    animation = {
        stand_start = 0,
        stand_end = 100,
        walk_start = 101,
        walk_end = 200,
        walk_speed = 35,
        run_start = 206,
        run_end = 280,
        run_speed = 75,
    },
    on_step = function(self, dtime)
        self.mold_timer = (self.mold_timer or 0) + dtime
        if self.mold_timer >= 30 then
            local pos = self.object:get_pos()
            spawn_mold_around(pos, 2)
            self.mold_timer = 0
        end
    end,
    on_die = function(self, pos)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
        evolution_points = evolution_points - 3
        if evolution_points < 0 then evolution_points = 0 end
        ep_storage:set_string("evolution_points", tostring(evolution_points))
        
        -- 40% chance of normal death, 60% chance of explosion with mold spawn
        if math.random(100) <= 40 then
            -- Normal death
            attempt_spawn_stage_1_nexus(pos)
        else
            -- Explosion death: spawn 3x3 mold area after 3 seconds
            minetest.sound_play("Flesh_Explosion", {pos = pos, gain = 1.0, max_hear_distance = 32})
            minetest.after(0.1, function()
                -- Spawn 3x3 area of mold, only replacing air
                for x = -1, 1 do
                    for z = -1, 1 do
                        local check_pos = {x = pos.x + x, y = pos.y, z = pos.z + z}
                        local node = minetest.get_node(check_pos)
                        if node.name == "air" then
                            -- Check that there's solid ground below
                            local below_pos = {x = check_pos.x, y = check_pos.y - 1, z = check_pos.z}
                            local below_node = minetest.get_node(below_pos)
                            if below_node.name ~= "air" and below_node.name ~= "bacterial_mod:mold" then
                                minetest.set_node(check_pos, {name = "bacterial_mod:mold"})
                            end
                        end
                    end
                end
            end)
        end
    end,
})

-- ============================================================================
-- INFECTED PIG MOB
-- ============================================================================
-- Infected version of a pig.

mobs:register_mob("bacterial_mod:infected_pig", {
    type = "bacterial",
    passive = false,
    attack_type = "dogfight",
    attack_monsters = true,
    attack_animals = true,
    attack_players = true,
    damage = 5,
    reach = 2.8,
    hp_max = 15,
    armor = 100,
    view_range = 50,
    collisionbox = {-0.35, -0.01, -0.35, 0.35, 0.8, 0.35},
    visual_size = {x = 1.3, y = 1.3},
    visual = "mesh",
    mesh = "InfPig.b3d",
    textures = {
        {"InfPigTexture.png"},
    },
        attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_amalgamation",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = true,
    walk_velocity = 3,
    run_velocity = 6,
    jump = true,
    drops = {
        {name = "bacterial_mod:Flesh", chance = 1, min = 1, max = 2},
    },
    lava_damage = 8,
    light_damage = 0,
    fear_height = 4,
    on_spawn = function(self, pos)
        -- Allow Nexus spawns
        if self.spawn_reason == "nexus" then
            return true
        end

        -- No phase logic here
        return true
    end,
    animation = {
        stand_start = 0,
        stand_end = 70,
        walk_start = 71,
        walk_end = 140,
        run_start = 141,
        run_end = 180,
    },
    on_step = function(self, dtime)
        self.mold_timer = (self.mold_timer or 0) + dtime
        if self.mold_timer >= 30 then
            local pos = self.object:get_pos()
            spawn_mold_around(pos, 2)
            self.mold_timer = 0
        end
    end,
    on_die = function(self, pos)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
        evolution_points = evolution_points - 3
        if evolution_points < 0 then evolution_points = 0 end
        ep_storage:set_string("evolution_points", tostring(evolution_points))
        
        -- 40% chance of normal death, 60% chance of explosion with mold spawn
        if math.random(100) <= 40 then
            -- Normal death
        else
            -- Explosion death: spawn 3x3 mold area after 3 seconds
            minetest.sound_play("Explosions", {pos = pos, gain = 1.0, max_hear_distance = 32})
            minetest.after(0.1, function()
                -- Spawn 3x3 area of mold, only replacing air
                for x = -1, 1 do
                    for z = -1, 1 do
                        local check_pos = {x = pos.x + x, y = pos.y, z = pos.z + z}
                        local node = minetest.get_node(check_pos)
                        if node.name == "air" then
                            -- Check that there's solid ground below
                            local below_pos = {x = check_pos.x, y = check_pos.y - 1, z = check_pos.z}
                            local below_node = minetest.get_node(below_pos)
                            if below_node.name ~= "air" and below_node.name ~= "bacterial_mod:mold" then
                                minetest.set_node(check_pos, {name = "bacterial_mod:mold"})
                            end
                        end
                    end
                end
            end)
        end
    end,
})

-- ============================================================================
-- INFECTED HUMAN MOB
-- ============================================================================
-- Infected version of a human.

mobs:register_mob("bacterial_mod:infected_human", {
    type = "bacterial",
    passive = false,
    attack_type = "dogfight",
    attack_monsters = true,
    attack_animals = true,
    attack_players = true,
    damage = 8,
    reach = 3.5,
    hp_max = 18,
    armor = 100,
    view_range = 65,
    collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.8, 0.3},
    visual_size = {x = 1, y = 1},
    visual = "mesh",
    mesh = "InfHuman.b3d",
    textures = {
        {"InfHumanTexture.png"},
    },
        attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_amalgamation",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = true,
    sounds = {
        distance = 10,
        random = "human2",
        damage = "human1",
    },

    walk_velocity = 3,
    run_velocity = 8,
    jump = true,
    drops = {
        {name = "bacterial_mod:Flesh", chance = 1, min = 1, max = 3},
    },
    lava_damage = 8,
    light_damage = 0,
    fear_height = 4,
    on_spawn = function(self, pos)
        -- Allow Nexus spawns
        if self.spawn_reason == "nexus" then
            return true
        end

        -- No phase logic here
        return true
    end,
    animation = {
        stand_start = 0,
        stand_end = 100,
        walk_start = 101,
        walk_end = 205,
        walk_speed = 35,
        run_start = 206,
        run_end = 275,
        run_speed = 75,
    },
    on_step = function(self, dtime)
        self.mold_timer = (self.mold_timer or 0) + dtime
        if self.mold_timer >= 30 then
            local pos = self.object:get_pos()
            spawn_mold_around(pos, 2)
            self.mold_timer = 0
        end
    end,
    on_die = function(self, pos)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
        evolution_points = evolution_points - 3
        if evolution_points < 0 then evolution_points = 0 end
        ep_storage:set_string("evolution_points", tostring(evolution_points))
        
        -- 40% chance of normal death, 60% chance of explosion with mold spawn
        if math.random(100) <= 50 then
            -- Normal death
            attempt_spawn_stage_1_nexus(pos)
        else
            -- Explosion death: spawn 3x3 mold area after 3 seconds
            minetest.sound_play("Flesh_Explosion", {pos = pos, gain = 1.0, max_hear_distance = 32})
            minetest.after(0.1, function()
                -- Spawn 3x3 area of mold, only replacing air
                for x = -1, 1 do
                    for z = -1, 1 do
                        local check_pos = {x = pos.x + x, y = pos.y, z = pos.z + z}
                        local node = minetest.get_node(check_pos)
                        if node.name == "air" then
                            -- Check that there's solid ground below
                            local below_pos = {x = check_pos.x, y = check_pos.y - 1, z = check_pos.z}
                            local below_node = minetest.get_node(below_pos)
                            if below_node.name ~= "air" and below_node.name ~= "bacterial_mod:mold" then
                                minetest.set_node(check_pos, {name = "bacterial_mod:mold"})
                            end
                        end
                    end
                end
            end)
        end
    end,
})


-- ============================================================================
-- NEXUS STAGE 1 ENTITY
-- ============================================================================
-- First stage of the Nexus. Stationary and counts down for 30 minutes before advancing.

minetest.register_entity("bacterial_mod:nexus_stage_1", {
    physical = true,
    collide_with_objects = false,
    pointable = true,
    visual = "mesh",
    mesh = "Nexus_Stage1.b3d",
    textures = {"Nexus_Stage1.png"},
    use_texture_alpha = false,
    visual_size = {x = 3, y = 2.5, z = 3},
    collisionbox = {-0.25, -0.01, -0.25, 0.25, 2, 0.25},
    hp_max = 35,
    groups = {immortal = 1},
    view_range = 25,
    attack_monsters = true,
    attack_animals = true,
    attack_players = true,
    attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_amalgamation",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
        "bacterial_mod:nexus_stage_1",
        "bacterial_mod:nexus_stage_2",
        "bacterial_mod:nexus_stage_3",
    },

    
    animation = {
        stand_start = 1,
        stand_end = 80,
        speed_normal = 15,
        summon_start = 150,
        summon_end = 190,
        speed_summon = 20,
    },
    
    -- Prevent despawning
    static_save = true,
    on_activate = function(self, staticdata)
        self.countdown = tonumber(staticdata) or 0
        self.infection_timer = 0
        self.ambient_timer = 0
        self.ambient_interval = math.random(10, 20)
        self.object:set_velocity({x = 0, y = 0, z = 0})
        self.object:set_acceleration({x = 0, y = 0, z = 0})
        if staticdata == "" or not staticdata then
            for _, player in ipairs(minetest.get_connected_players()) do
                minetest.sound_play("bell1", {
                    to_player = player:get_player_name(),
                    gain = 1.0,
                })
            end
        end
        -- Set initial animation
        self.object:set_animation({x = self.animation.stand_start, y = self.animation.stand_end}, self.animation.speed_normal, 0)
    end,

    on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir, damage)
    nexus_apply_damage_reduction(self, damage)

    local pos = self.object:get_pos()
    minetest.sound_play("bone_flesh_move", {
        pos = pos,
        gain = 0.8,
        max_hear_distance = 32,
    })
end,
    
    get_staticdata = function(self)
        return tostring(self.countdown)
    end,

    on_step = function(self, dtime)
        nexus_apply_gravity_step(self, dtime)

        nexus_regenerate(self, dtime, 5 / 60)

        -- Ambient sound timer
        self.ambient_timer = (self.ambient_timer or 0) + dtime
        if self.ambient_timer >= (self.ambient_interval or 15) then
            local pos = self.object:get_pos()
            minetest.sound_play("Nexus_Ambient", {pos = pos, gain = 0.4, max_hear_distance = 32})
            self.ambient_timer = 0
            self.ambient_interval = math.random(10, 20)
        end
        
        -- Add to countdown (30 minutes = 1800 seconds)
        self.countdown = (self.countdown or 0) + dtime
        
        -- Check and convert block below periodically (convert any block except air)
        self.infection_timer = (self.infection_timer or 0) + dtime
        if self.infection_timer >= 1 then
            local pos = self.object:get_pos()
            local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
            local node = minetest.get_node(below_pos)
            if node and node.name and node.name ~= "air" then
                minetest.set_node(below_pos, {name = "bacterial_mod:Infected_Soil"})
            end
            self.infection_timer = 0
        end
        
-- Check for attackable entities and spawn mobs
		self.pod_timer = (self.pod_timer or 0) + dtime
		if self.pod_timer >= 30 then
			local pos = self.object:get_pos()
			local view_range = 25
			local objs = minetest.get_objects_inside_radius(pos, view_range)
			local should_summon = false
			
			for _, obj in ipairs(objs) do
				if obj ~= self.object then
					local entity = obj:get_luaentity()
					-- Check if it's a player or mob
					if entity then
						if entity.is_mob or entity.name then
							should_summon = true
							break
						end
					elseif obj:is_player() then
						should_summon = true
						break
					end
				end
			end
			
			if should_summon then
				-- Summon sound + animation
				local pos = self.object:get_pos()
				minetest.sound_play("bacterial_mod:nexus_summon", {pos = pos, gain = 1.0, max_hear_distance = 32})
				self.object:set_animation({x = self.animation.summon_start, y = self.animation.summon_end}, self.animation.speed_summon, 0)
				self.summoning = true
				
				nexus_spawn_mobs_around(pos, nexus_stage_1_spawn_mobs, 2, 3)
                
                -- Schedule animation reset after summoning
                minetest.after(2, function()
                    if self.object then
                        self.object:set_animation({x = self.animation.stand_start, y = self.animation.stand_end}, self.animation.speed_normal, 0)
                        self.summoning = false
                    end
                end)
            end
            
            self.pod_timer = 0
        end
        
        if self.countdown >= 1800 then
            local pos = self.object:get_pos()
            self.object:remove()
            -- Spawn Nexus Stage 2 at the same position
            if not bacterial_mod.is_nexus_nearby(pos) then
                minetest.add_entity(pos, "bacterial_mod:nexus_stage_2")
            end
        end
    end,
    on_die = function(self, pos)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
        evolution_points = evolution_points - 15
        if evolution_points < 0 then evolution_points = 0 end
        ep_storage:set_string("evolution_points", tostring(evolution_points))
    end,
})

-- ============================================================================
-- NEXUS STAGE 2 ENTITY
-- ============================================================================
-- Second stage of the Nexus. Stationary and counts down for 40 minutes before advancing.

minetest.register_entity("bacterial_mod:nexus_stage_2", {
    physical = true,
    collide_with_objects = false,
    pointable = true,
    visual = "mesh",
    mesh = "Nexus_Stage2.b3d",
    textures = {"Nexus_Stage2.png"},
    use_texture_alpha = false,
    visual_size = {x = 2.5, y = 2.5},
    collisionbox = {-0.2, -0.5, -0.2, 0.2, 3.99, 0.2},
    hp_max = 75,
    groups = {immortal = 1},
    view_range = 35,
    attack_monsters = true,
    attack_animals = true,
    attack_players = true,
    attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_amalgamation",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
        "bacterial_mod:nexus_stage_1",
        "bacterial_mod:nexus_stage_2",
        "bacterial_mod:nexus_stage_3",
    },
    
    animation = {
        stand_start = 1,
        stand_end = 140,
        speed_normal = 15,
        summon_start = 150,
        summon_end = 240,
        speed_summon = 20,
    },
    
    -- Prevent despawning
    static_save = true,
    on_activate = function(self, staticdata)
        self.countdown = tonumber(staticdata) or 0
        self.infection_timer = 0
        self.ambient_timer = 0
        self.ambient_interval = math.random(10, 20)
        self.object:set_velocity({x = 0, y = 0, z = 0})
        self.object:set_acceleration({x = 0, y = 0, z = 0})
        if staticdata == "" or not staticdata then
            for _, player in ipairs(minetest.get_connected_players()) do
                minetest.sound_play("bell2", {
                    to_player = player:get_player_name(),
                    gain = 1.0,
                })
            end
        end
        -- Set initial animation
        self.object:set_animation({x = self.animation.stand_start, y = self.animation.stand_end}, self.animation.speed_normal, 0)
    end,

    on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir, damage)
    nexus_apply_damage_reduction(self, damage)

    local pos = self.object:get_pos()
    minetest.sound_play("bone_flesh_move", {
        pos = pos,
        gain = 0.8,
        max_hear_distance = 32,
    })
end,
    
    get_staticdata = function(self)
        return tostring(self.countdown)
    end,

    on_step = function(self, dtime)
        nexus_apply_gravity_step(self, dtime)

        nexus_regenerate(self, dtime, 15 / 60)

        -- Ambient sound timer
        self.ambient_timer = (self.ambient_timer or 0) + dtime
        if self.ambient_timer >= (self.ambient_interval or 15) then
            local pos = self.object:get_pos()
            minetest.sound_play("Nexus_Ambient", {pos = pos, gain = 0.4, max_hear_distance = 32})
            self.ambient_timer = 0
            self.ambient_interval = math.random(10, 20)
        end
        
        -- Add to countdown (40 minutes = 2400 seconds)
        self.countdown = (self.countdown or 0) + dtime
        
        -- Check and convert block below periodically (convert any block except air)
        self.infection_timer = (self.infection_timer or 0) + dtime
        if self.infection_timer >= 1 then
            local pos = self.object:get_pos()
            local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
            local node = minetest.get_node(below_pos)
            if node and node.name and node.name ~= "air" then
                minetest.set_node(below_pos, {name = "bacterial_mod:Infected_Soil"})
            end
            self.infection_timer = 0
        end
        
-- Check for attackable entities and spawn mobs
		self.pod_timer = (self.pod_timer or 0) + dtime
		if self.pod_timer >= 27 then
			local pos = self.object:get_pos()
			local view_range = 35
			local objs = minetest.get_objects_inside_radius(pos, view_range)
			local should_summon = false
			
			for _, obj in ipairs(objs) do
				if obj ~= self.object then
					local entity = obj:get_luaentity()
					-- Check if it's a player or mob
					if entity then
						if entity.is_mob or entity.name then
							should_summon = true
							break
						end
					elseif obj:is_player() then
						should_summon = true
						break
					end
				end
			end
			
			if should_summon then
				-- Summon sound + animation
				local pos = self.object:get_pos()
				minetest.sound_play("bacterial_mod:nexus_summon", {pos = pos, gain = 1.0, max_hear_distance = 32})
				self.object:set_animation({x = self.animation.summon_start, y = self.animation.summon_end}, self.animation.speed_summon, 0)
				self.summoning = true
				
				nexus_spawn_mobs_around(pos, nexus_infected_mobs, 3, 4)
                
                -- Schedule animation reset after summoning
                minetest.after(2, function()
                    if self.object then
                        self.object:set_animation({x = self.animation.stand_start, y = self.animation.stand_end}, self.animation.speed_normal, 0)
                        self.summoning = false
                    end
                end)
            end
            
            self.pod_timer = 0
        end
        
        if self.countdown >= 2400 then
            local pos = self.object:get_pos()
            self.object:remove()
            -- Spawn Nexus Stage 3 at the same position
            if not bacterial_mod.is_nexus_nearby(pos) then
                minetest.add_entity(pos, "bacterial_mod:nexus_stage_3")
            end
        end
    end,
    on_die = function(self, pos)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
        evolution_points = evolution_points - 55
        if evolution_points < 0 then evolution_points = 0 end
        ep_storage:set_string("evolution_points", tostring(evolution_points))
    end,
})

-- ============================================================================
-- NEXUS STAGE 3 ENTITY
-- ============================================================================
-- Final stage of the Nexus. Stationary and immovable. Does not advance further.

minetest.register_entity("bacterial_mod:nexus_stage_3", {
    physical = true,
    collide_with_objects = false,
    pointable = true,
    visual = "mesh",
    mesh = "Nexus_Stage_3.b3d",
    textures = {"Nexus_Stage_3.png"},
    use_texture_alpha = false,
    visual_size = {x = 3, y = 3},
    collisionbox = {-0.2, -0.01, -0.2, 0.2, 3.99, 0.2},
    hp_max = 150,
    groups = {immortal = 1},
    view_range = 55,
    attack_monsters = true,
    attack_animals = true,
    attack_players = true,
    attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_amalgamation",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
        "bacterial_mod:nexus_stage_1",
        "bacterial_mod:nexus_stage_2",
        "bacterial_mod:nexus_stage_3",
    },
    
    animation = {
        stand_start = 0,
        stand_end = 40,
        speed_normal = 15,
        summon_start = 41,
        summon_end = 80,
        speed_summon = 20,
    },
    
    -- Prevent despawning
    static_save = true,
    on_activate = function(self, staticdata)
        self.infection_timer = 0
        self.ambient_timer = 0
        self.ambient_interval = math.random(10, 20)
        self.object:set_velocity({x = 0, y = 0, z = 0})
        self.object:set_acceleration({x = 0, y = 0, z = 0})
        if staticdata == "" or not staticdata then
            for _, player in ipairs(minetest.get_connected_players()) do
                minetest.sound_play("bell3", {
                    to_player = player:get_player_name(),
                    gain = 1.0,
                })
            end
        end
        -- Set initial animation
        self.object:set_animation({x = self.animation.stand_start, y = self.animation.stand_end}, self.animation.speed_normal, 0)
    end,

    on_punch = function(self, hitter, time_from_last_punch, tool_capabilities, dir, damage)
        nexus_apply_damage_reduction(self, damage)
    end,

    on_step = function(self, dtime)
        nexus_apply_gravity_step(self, dtime)

        nexus_regenerate(self, dtime, 35 / 60)

        -- Ambient sound timer
        self.ambient_timer = (self.ambient_timer or 0) + dtime
        if self.ambient_timer >= (self.ambient_interval or 15) then
            local pos = self.object:get_pos()
            minetest.sound_play("Nexus_Ambient", {pos = pos, gain = 0.4, max_hear_distance = 32})
            self.ambient_timer = 0
            self.ambient_interval = math.random(10, 20)
        end
        
        -- Check and convert block below periodically (convert any block except air)
        self.infection_timer = (self.infection_timer or 0) + dtime
        if self.infection_timer >= 1 then
            local pos = self.object:get_pos()
            local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
            local node = minetest.get_node(below_pos)
            if node and node.name and node.name ~= "air" then
                minetest.set_node(below_pos, {name = "bacterial_mod:Infected_Soil"})
            end
            self.infection_timer = 0
        end
        
        -- Check for attackable entities and summon pods
        self.pod_timer = (self.pod_timer or 0) + dtime
        if self.pod_timer >= 24 then
            local pos = self.object:get_pos()
            local view_range = 50
            local objs = minetest.get_objects_inside_radius(pos, view_range)
            local should_summon = false
            
            for _, obj in ipairs(objs) do
                if obj ~= self.object then
                    local entity = obj:get_luaentity()
                    -- Check if it's a player or mob
                    if entity then
                        if entity.is_mob or entity.name then
                            should_summon = true
                            break
                        end
                    elseif obj:is_player() then
                        should_summon = true
                        break
                    end
                end
            end
            
            if should_summon then
                -- Set summoning animation
                self.object:set_animation({x = self.animation.summon_start, y = self.animation.summon_end}, self.animation.speed_summon, 0)
                self.summoning = true
                
                nexus_spawn_mobs_around(pos, nexus_infected_mobs, 4, 5)
                
                -- Schedule animation reset after summoning
                minetest.after(2, function()
                    if self.object then
                        self.object:set_animation({x = self.animation.stand_start, y = self.animation.stand_end}, self.animation.speed_normal, 0)
                        self.summoning = false
                    end
                end)
            end
            
            self.pod_timer = 0
        end
    end,
    on_die = function(self, pos)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
        evolution_points = evolution_points - 125
        if evolution_points < 0 then evolution_points = 0 end
        ep_storage:set_string("evolution_points", tostring(evolution_points))
    end,
})


