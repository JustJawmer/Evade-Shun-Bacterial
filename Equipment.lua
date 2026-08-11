local ep_storage = minetest.get_mod_storage()



minetest.register_craftitem("bacterial_mod:spawn_blob", {
    description = "Bacterial Blob Spawn Egg",
    inventory_image = "Mound_Spawn.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.above
            local ent = minetest.add_entity(pos, "bacterial_mod:bacteria_blob")
            if ent then
                minetest.log("action", string.format("[bacterial_mod] spawn_blob: created bacterial_mod:bacteria_blob at %s", minetest.pos_to_string(pos)))
                local le = ent:get_luaentity()
                if le and le.name then
                    minetest.log("action", string.format("[bacterial_mod] spawn_blob: luaentity name = %s", tostring(le.name)))
                    -- diagnostic: does the luaentity include our callbacks?
                    minetest.log("action", string.format("[bacterial_mod] spawn_blob: has on_activate=%s on_step=%s", tostring(type(le.on_activate) == "function"), tostring(type(le.on_step) == "function")))
                else
                    minetest.log("action", "[bacterial_mod] spawn_blob: luaentity missing or has no name")        
                end
            end
            itemstack:take_item()
            return itemstack
        end
        return itemstack
    end,
})

minetest.register_craftitem("bacterial_mod:spawn_flesh_amalgamation", {
    description = "Flesh Amalgamation Spawn Egg",
    inventory_image = "Flesh_Amalgamation_Spawn.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.above
            local ent = minetest.add_entity(pos, "bacterial_mod:flesh_amalgamation")
            if ent then
                minetest.log("action", string.format("[bacterial_mod] spawn_blob: created bacterial_mod:flesh_amalgamation at %s", minetest.pos_to_string(pos)))
                local le = ent:get_luaentity()
                if le and le.name then
                    minetest.log("action", string.format("[bacterial_mod] spawn_blob: luaentity name = %s", tostring(le.name)))
                    -- diagnostic: does the luaentity include our callbacks?
                    minetest.log("action", string.format("[bacterial_mod] spawn_blob: has on_activate=%s on_step=%s", tostring(type(le.on_activate) == "function"), tostring(type(le.on_step) == "function")))
                else
                    minetest.log("action", "[bacterial_mod] spawn_blob: luaentity missing or has no name")        
                end
            end
            itemstack:take_item()
            return itemstack
        end
        return itemstack
    end,
})

-- ============================================================================
-- SMALL FLESH AMALGAMATION SPAWN EGG
-- ============================================================================
minetest.register_craftitem("bacterial_mod:spawn_small_flesh_amalgamation", {
    description = "Small Flesh Amalgamation Spawn Egg",
    inventory_image = "SmallFleshSpawn.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.above
            local ent = minetest.add_entity(pos, "bacterial_mod:small_flesh_amalgamation")
            if ent then
                minetest.log("action", string.format("[bacterial_mod] spawn_small_flesh_amalgamation: created bacterial_mod:small_flesh_amalgamation at %s", minetest.pos_to_string(pos)))
                local le = ent:get_luaentity() 
                if le and le.name then
                    minetest.log("action", string.format("[bacterial_mod] spawn_small_flesh_amalgamation: luaentity name = %s", tostring(le.name)))
                else
                    minetest.log("action", "[bacterial_mod] spawn_small_flesh_amalgamation: luaentity missing or has no name")
                end
            end
            itemstack:take_item()
            return itemstack
        end
        return itemstack
    end,
})

-- ============================================================================
-- INFECTED SHEEP SPAWN EGG
-- ============================================================================
minetest.register_craftitem("bacterial_mod:spawn_infected_sheep", {
    description = "Infected Sheep Spawn Egg",
    inventory_image = "InfSheepSpawn.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.above
            local ent = minetest.add_entity(pos, "bacterial_mod:infected_sheep")
            if ent then
                minetest.log("action", string.format("[bacterial_mod] spawn_infected_sheep: created bacterial_mod:infected_sheep at %s", minetest.pos_to_string(pos)))
                local le = ent:get_luaentity()
                if le and le.name then
                    minetest.log("action", string.format("[bacterial_mod] spawn_infected_sheep: luaentity name = %s", tostring(le.name)))
                else
                    minetest.log("action", "[bacterial_mod] spawn_infected_sheep: luaentity missing or has no name")
                end
            end
            itemstack:take_item()
            return itemstack
        end
        return itemstack
    end,
})

-- ============================================================================
-- INFECTED PIG SPAWN EGG
-- ============================================================================
minetest.register_craftitem("bacterial_mod:spawn_infected_pig", {
    description = "Infected Pig Spawn Egg",
    inventory_image = "InfPigSpawn.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.above
            local ent = minetest.add_entity(pos, "bacterial_mod:infected_pig")
            if ent then
                minetest.log("action", string.format("[bacterial_mod] spawn_infected_pig: created bacterial_mod:infected_pig at %s", minetest.pos_to_string(pos)))
                local le = ent:get_luaentity()
                if le and le.name then
                    minetest.log("action", string.format("[bacterial_mod] spawn_infected_pig: luaentity name = %s", tostring(le.name)))
                else
                    minetest.log("action", "[bacterial_mod] spawn_infected_pig: luaentity missing or has no name")
                end
            end
            itemstack:take_item()
            return itemstack
        end
        return itemstack
    end,
})

-- ============================================================================
-- INFECTED COW SPAWN EGG
-- ============================================================================
minetest.register_craftitem("bacterial_mod:spawn_infected_cow", {
    description = "Infected Cow Spawn Egg",
    inventory_image = "InfCowSpawn.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.above
            local ent = minetest.add_entity(pos, "bacterial_mod:infected_cow")
            if ent then
                minetest.log("action", string.format("[bacterial_mod] spawn_infected_cow: created bacterial_mod:infected_cow at %s", minetest.pos_to_string(pos)))
                local le = ent:get_luaentity()
                if le and le.name then
                    minetest.log("action", string.format("[bacterial_mod] spawn_infected_cow: luaentity name = %s", tostring(le.name)))
                else
                    minetest.log("action", "[bacterial_mod] spawn_infected_cow: luaentity missing or has no name")
                end
            end
            itemstack:take_item()
            return itemstack
        end
        return itemstack
    end,
})

-- ============================================================================
-- INFECTED HUMAN SPAWN EGG
-- ============================================================================
minetest.register_craftitem("bacterial_mod:spawn_infected_human", {
    description = "Infected Human Spawn Egg",
    inventory_image = "InfHumanSpawn.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.above
            local ent = minetest.add_entity(pos, "bacterial_mod:infected_human")
            if ent then
                minetest.log("action", string.format("[bacterial_mod] spawn_infected_human: created bacterial_mod:infected_human at %s", minetest.pos_to_string(pos)))
                local le = ent:get_luaentity()
                if le and le.name then
                    minetest.log("action", string.format("[bacterial_mod] spawn_infected_human: luaentity name = %s", tostring(le.name)))
                else
                    minetest.log("action", "[bacterial_mod] spawn_infected_human: luaentity missing or has no name")
                end
            end
            itemstack:take_item()
            return itemstack
        end
        return itemstack
    end,
})

-- ============================================================================
-- NEXUS STAGE 1 SPAWN EGG
-- ============================================================================
minetest.register_craftitem("bacterial_mod:spawn_nexus_stage_1", {
    description = "Nexus Stage 1 Spawn Egg",
    inventory_image = "NexusStage1Spawn.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.above
            local ent = minetest.add_entity(pos, "bacterial_mod:nexus_stage_1")
            if ent then
                minetest.log("action", string.format("[bacterial_mod] spawn_nexus_stage_1: created bacterial_mod:nexus_stage_1 at %s", minetest.pos_to_string(pos)))
            end
            itemstack:take_item()
            return itemstack
        end
        return itemstack
    end,
})

-- ============================================================================
-- NEXUS STAGE 2 SPAWN EGG
-- ============================================================================
minetest.register_craftitem("bacterial_mod:spawn_nexus_stage_2", {
    description = "Nexus Stage 2 Spawn Egg",
    inventory_image = "NexusStage2Spawn.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.above
            local ent = minetest.add_entity(pos, "bacterial_mod:nexus_stage_2")
            if ent then
                minetest.log("action", string.format("[bacterial_mod] spawn_nexus_stage_2: created bacterial_mod:nexus_stage_2 at %s", minetest.pos_to_string(pos)))
            end
            itemstack:take_item()
            return itemstack
        end
        return itemstack
    end,
})

-- ============================================================================
-- NEXUS STAGE 3 SPAWN EGG
-- ============================================================================
minetest.register_craftitem("bacterial_mod:spawn_nexus_stage_3", {
    description = "Nexus Stage 3 Spawn Egg",
    inventory_image = "NexusStage3Spawn.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.above
            local ent = minetest.add_entity(pos, "bacterial_mod:nexus_stage_3")
            if ent then
                minetest.log("action", string.format("[bacterial_mod] spawn_nexus_stage_2: created bacterial_mod:nexus_stage_2 at %s", minetest.pos_to_string(pos)))
            end
            itemstack:take_item()
            return itemstack
        end
        return itemstack
    end,
})
