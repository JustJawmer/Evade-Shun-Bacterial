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
		max_roll = 32
	elseif phase == 4 then
		max_roll = 24
	elseif phase == 5 then
		max_roll = 16
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
	local count = math.random(min_count, max_count)
	for i = 1, count do
		local angle = math.random() * 2 * math.pi
		local distance = math.random(3, 10)
		local new_pos = {
			x = pos.x + math.cos(angle) * distance,
			y = pos.y + 1,
			z = pos.z + math.sin(angle) * distance,
		}
        local obj = minetest.add_entity(spawn_pos, mobname)
        if obj then
            local ent = obj:get_luaentity()
            if ent then
                ent.spawn_reason = "nexus"
            end
        end
    end
end


mobs:register_mob("bacterial_mod:bacteria_blob", {
    type = "bacterial",
    passive = false,
    attack_type = "dogfight",
    attack_monsters = true, -- Attacks other monsters
    attack_animals = true, -- Attacks passive mobs like sheep or cows
    attack_players = true, --  This enables mob-on-mob aggression
    damage = 4,
    reach = 2.5,
    hp_max = 12,
    armor = 100,
    view_range = 18,
    collisionbox = {-0.1, -0.1, -0.1, 0.1, 1.0, 0.3},
    visual_size = {x = 3, y = 3},
    visual = "mesh",
    mesh = "Bacterial_Mound.b3d",
    textures = {
        {"Bacterial_Mound_Texture.png"},
    },
        attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_blob",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = false,
    walk_velocity = 1,
    run_velocity = 2,
    jump = true,
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
    animation = {
        speed_normal = 15,
        speed_run = 25,
        stand_start = 0,
        stand_end = 79,
        walk_start = 168,
        walk_end = 187,
        run_start = 168,
        run_end = 187,
        punch_start = 189,
        punch_end = 198,
    },
    do_custom = function(self, dtime)
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
    damage = 5,
    reach = 2.5,
    hp_max = 25,
    armor = 100,
    view_range = 25,
    collisionbox = {-0.1, -0.1, -0.1, 0.3, 1.0, 0.3},
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
        "bacterial_mod:small_flesh_blob",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = false,
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
        -- Allow spawning in any phase for testing purposes
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
    do_custom = function(self, dtime)
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
        attempt_spawn_stage_1_nexus(pos)
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
    damage = 5,
    reach = 2.2,
    hp_max = 15,
    armor = 100,
    view_range = 25,
    collisionbox = {-0.35, -0.01, -0.35, 0.35, 1.0, 0.35},
    visual_size = {x = 1.2, y = 1.2},
    visual = "mesh",
    mesh = "Bacterial_Mound.b3d",  -- Reuse existing mesh or create specialized model
    textures = {
        {"Flesh_Amalgamation.png"},  -- You'll need to create this texture
    },
        attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_blob",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = true,
    walk_velocity = 1.5,
    run_velocity = 3,
    jump = true,
    drops = {
        {name = "bacterial_mod:Flesh", chance = 1, min = 2, max = 3},
    },
    lava_damage = 4,
    light_damage = 0,
    fear_height = 3,
    on_spawn = function(self, pos)
        -- Allow spawning in any phase for testing purposes
        return true
    end,
    animation = {
        speed_normal = 15,
        speed_run = 20,
        stand_start = 0,
        stand_end = 79,
        walk_start = 168,
        walk_end = 187,
        run_start = 168,
        run_end = 187,
        punch_start = 189,
        punch_end = 198,
    },
    on_die = function(self, pos)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
        evolution_points = evolution_points - 1
        if evolution_points < 0 then evolution_points = 0 end
        ep_storage:set_string("evolution_points", tostring(evolution_points))
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
    damage = 3,
    reach = 2,
    hp_max = 5,
    armor = 100,
    view_range = 20,
    collisionbox = {-0.05, -0.05, -0.05, 0.15, 0.5, 0.15},
    visual_size = {x = 1.5, y = 1.5},
    visual = "mesh",
    mesh = "Bacterial_Mound.b3d",
    textures = {
        {"Small_Flesh_Blob.png"},
    },
        attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_blob",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = false,
    walk_velocity = 0.5,
    run_velocity = 1,
    jump = true,
    drops = {
        {name = "bacterial_mod:Flesh", chance = 1, min = 1, max = 1},
    },
    lava_damage = 5,
    light_damage = 0,
    fear_height = 3,
    on_spawn = function(self, pos)
        -- Allow spawning in any phase for testing purposes
        return true
    end,
    animation = {
        speed_normal = 15,
        speed_run = 25,
        stand_start = 0,
        stand_end = 79,
        walk_start = 168,
        walk_end = 187,
        run_start = 168,
        run_end = 187,
        punch_start = 189,
        punch_end = 198,
    },
    do_custom = function(self, dtime)
        self.mold_timer = (self.mold_timer or 0) + dtime
        if self.mold_timer >= 30 then
            local pos = self.object:get_pos()
            spawn_mold_around(pos, 1)
            self.mold_timer = 0
        end
    end,
    on_die = function(self, pos)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
        evolution_points = evolution_points - 1
        if evolution_points < 0 then evolution_points = 0 end
        ep_storage:set_string("evolution_points", tostring(evolution_points))
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
    damage = 4,
    reach = 2.5,
    hp_max = 20,
    armor = 100,
    view_range = 20,
    collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.0, 0.3},
    visual_size = {x = 1, y = 1},
    visual = "mesh",
    mesh = "Infected_Sheep.b3d",
    textures = {
        {"Infected_Sheep.png"},
    },
        attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_blob",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = true,
    walk_velocity = 2,
    run_velocity = 4,
    jump = true,
    drops = {
        {name = "bacterial_mod:Flesh", chance = 1, min = 1, max = 2},
    },
    lava_damage = 5,
    light_damage = 0,
    fear_height = 4,
    on_spawn = function(self, pos)
        -- Allow spawning in any phase for testing purposes
        return true
    end,
    animation = {
        stand_start = 0,
        stand_end = 40,
        walk_start = 41,
        walk_end = 99,
        run_start = 100,
        run_end = 145,
        die_start = 178,
        die_end = 205,
    },
    do_custom = function(self, dtime)
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
        attempt_spawn_stage_1_nexus(pos)
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
    hp_max = 25,
    armor = 100,
    view_range = 20,
    collisionbox = {-0.35, -0.01, -0.35, 0.35, 1.1, 0.35},
    visual_size = {x = 1, y = 1},
    visual = "mesh",
    mesh = "Infected_Pig.b3d",
    textures = {
        {"Infected_Pig.png"},
    },
        attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_blob",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = true,
    walk_velocity = 2.5,
    run_velocity = 4.5,
    jump = true,
    drops = {
        {name = "bacterial_mod:Flesh", chance = 1, min = 1, max = 2},
    },
    lava_damage = 5,
    light_damage = 0,
    fear_height = 4,
    on_spawn = function(self, pos)
        -- Allow spawning in any phase for testing purposes
        return true
    end,
    animation = {
        stand_start = 0,
        stand_end = 40,
        walk_start = 41,
        walk_end = 99,
        run_start = 100,
        run_end = 145,
        die_start = 178,
        die_end = 205,
    },
    do_custom = function(self, dtime)
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
    hp_max = 35,
    armor = 100,
    view_range = 20,
    collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.8, 0.3},
    visual_size = {x = 1, y = 1},
    visual = "mesh",
    mesh = "InfHuman.b3d",
    textures = {
        {"Infected_Human.png"},
    },
        attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_blob",
        "bacterial_mod:infected_sheep",
        "bacterial_mod:infected_pig",
        "bacterial_mod:infected_human",
    },
    makes_footstep_sound = true,
    walk_velocity = 2,
    run_velocity = 5,
    jump = true,
    drops = {
        {name = "bacterial_mod:Flesh", chance = 1, min = 1, max = 3},
    },
    lava_damage = 5,
    light_damage = 0,
    fear_height = 4,
    on_spawn = function(self, pos)
        -- Allow spawning in any phase for testing purposes
        return true
    end,
    animation = {
        stand_start = 0,
        stand_end = 40,
        walk_start = 41,
        walk_end = 99,
        run_start = 100,
        run_end = 145,
        die_start = 178,
        die_end = 205,
    },
    do_custom = function(self, dtime)
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
        attempt_spawn_stage_1_nexus(pos)
    end,
})

local function nexus_in_lava(pos)
    local node = minetest.get_node_or_nil(vector.round(pos))
    if not node then
        return false
    end
    return node.name == "default:lava_source" or node.name == "default:lava_flow"
end

local function nexus_handle_lava(self, dtime, reduction)
    if not self.object then
        return
    end
    local pos = self.object:get_pos()
    if not pos or not nexus_in_lava(pos) then
        return
    end
    self._lava_accum = (self._lava_accum or 0) + dtime * 5 * reduction
    local damage = math.floor(self._lava_accum)
    if damage > 0 then
        local hp = self.object:get_hp() or 0
        local new_hp = hp - damage
        self.object:set_hp(new_hp)
        self._lava_accum = self._lava_accum - damage
        if new_hp <= 0 then
            local death_pos = self.object:get_pos()
            if self.on_die then
                self:on_die(death_pos)
            end
            self.object:remove()
            return true
        end
    end
end

local function nexus_regenerate(self, dtime, rate)
    if not self.object then
        return
    end
    local hp = self.object:get_hp() or 0
    local max_hp = self.hp_max or 0
    if hp < max_hp then
        self._regen_acc = (self._regen_acc or 0) + dtime * rate
        local heal = math.floor(self._regen_acc)
        if heal > 0 then
            self.object:set_hp(math.min(max_hp, hp + heal))
            self._regen_acc = self._regen_acc - heal
        end
    end
end

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
        "bacterial_mod:small_flesh_blob",
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
        -- Set initial animation
        self.object:set_animation({x = self.animation.stand_start, y = self.animation.stand_end}, self.animation.speed_normal, 0)
    end,

    get_staticdata = function(self)
        return tostring(self.countdown)
    end,

    do_custom = function(self, dtime)
        -- Prevent any movement
        self.object:set_velocity({x = 0, y = 0, z = 0})

        nexus_regenerate(self, dtime, 5 / 60)
        if nexus_handle_lava(self, dtime, 0.15) then
            return
        end

        -- Ambient sound timer
        self.ambient_timer = (self.ambient_timer or 0) + dtime
        if self.ambient_timer >= (self.ambient_interval or 15) then
            local pos = self.object:get_pos()
            minetest.sound_play("bacterial_mod:nexus_ambient", {pos = pos, gain = 0.4, max_hear_distance = 32})
            self.ambient_timer = 0
            self.ambient_interval = math.random(10, 20)
        end

        -- Add to countdown (30 minutes = 1800 seconds)
        self.countdown = (self.countdown or 0) + dtime

        -- Check and convert block below periodically
        self.infection_timer = (self.infection_timer or 0) + dtime
        if self.infection_timer >= 1 then
            local pos = self.object:get_pos()
            local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
            minetest.set_node(below_pos, {name = "bacterial_mod:Infected_Soil"})
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
        "bacterial_mod:small_flesh_blob",
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
        -- Set initial animation
        self.object:set_animation({x = self.animation.stand_start, y = self.animation.stand_end}, self.animation.speed_normal, 0)
    end,

    get_staticdata = function(self)
        return tostring(self.countdown)
    end,

    do_custom = function(self, dtime)
        -- Prevent any movement
        self.object:set_velocity({x = 0, y = 0, z = 0})

        nexus_regenerate(self, dtime, 15 / 60)
        if nexus_handle_lava(self, dtime, 0.15) then
            return
        end

        -- Ambient sound timer
        self.ambient_timer = (self.ambient_timer or 0) + dtime
        if self.ambient_timer >= (self.ambient_interval or 15) then
            local pos = self.object:get_pos()
            minetest.sound_play("bacterial_mod:nexus_ambient", {pos = pos, gain = 0.4, max_hear_distance = 32})
            self.ambient_timer = 0
            self.ambient_interval = math.random(10, 20)
        end

        -- Add to countdown (40 minutes = 2400 seconds)
        self.countdown = (self.countdown or 0) + dtime

        -- Check and convert block below periodically
        self.infection_timer = (self.infection_timer or 0) + dtime
        if self.infection_timer >= 1 then
            local pos = self.object:get_pos()
            local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
            minetest.set_node(below_pos, {name = "bacterial_mod:Infected_Soil"})
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
    view_range = 50,
    attack_monsters = true,
    attack_animals = true,
    attack_players = true,
    attack_ignore = {
        "bacterial_mod:bacteria_blob",
        "bacterial_mod:infected_cow",
        "bacterial_mod:flesh_amalgamation",
        "bacterial_mod:small_flesh_blob",
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
        -- Set initial animation
        self.object:set_animation({x = self.animation.stand_start, y = self.animation.stand_end}, self.animation.speed_normal, 0)
    end,

    do_custom = function(self, dtime)
        -- Prevent any movement
        self.object:set_velocity({x = 0, y = 0, z = 0})

        nexus_regenerate(self, dtime, 35 / 60)
        if nexus_handle_lava(self, dtime, 0.15) then
            return
        end

        -- Ambient sound timer
        self.ambient_timer = (self.ambient_timer or 0) + dtime
        if self.ambient_timer >= (self.ambient_interval or 15) then
            local pos = self.object:get_pos()
            minetest.sound_play("bacterial_mod:nexus_ambient", {pos = pos, gain = 0.4, max_hear_distance = 32})
            self.ambient_timer = 0
            self.ambient_interval = math.random(10, 20)
        end

        -- Check and convert block below periodically
        self.infection_timer = (self.infection_timer or 0) + dtime
        if self.infection_timer >= 1 then
            local pos = self.object:get_pos()
            local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
            minetest.set_node(below_pos, {name = "bacterial_mod:Infected_Soil"})
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
