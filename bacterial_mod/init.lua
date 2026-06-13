USE_SFINV = minetest.get_modpath("sfinv") ~= nil

local ep_storage = minetest.get_mod_storage()

if not ep_storage then
    -- Fallback stub to avoid runtime errors when storage is unavailable
    ep_storage = {
        _store = {},
        get_string = function(self, k) return self._store[k] end,
        set_string = function(self, k, v) self._store[k] = v end,
    }
end

bacterial_mod = {}
bacterial_mod.modpath = minetest.get_modpath("bacterial_mod")
bacterial_mod.music = bacterial_mod.music or {}
bacterial_mod.music.modpath = bacterial_mod.modpath

-- Register infected world nodes
minetest.register_node("bacterial_mod:Infected_Soil", {
    description = "Infected Soil",
    tiles = {"Infected_Soil.png"},
    groups = {crumbly = 3},
    drop = "",
})

minetest.register_node("bacterial_mod:Infected_Rock", {
    description = "Infected Rock",
    tiles = {"Infected_Rock.png"},
    groups = {cracky = 3},
    drop = "",
})

minetest.register_node("bacterial_mod:Infected_Log", {
    description = "Infected Log",
    tiles = {"LogTop.png", "LogTop.png", "LogSide.png"},
    groups = {choppy = 2},
    drop = "",
})

local infected_block_penalty = {
    ["bacterial_mod:Infected_Soil"] = 1,
    ["bacterial_mod:Infected_Rock"] = 1,
    ["bacterial_mod:Infected_Log"] = 1,
}

local last_infected_log_dig = {}
local function infected_log_dig_cooldown(name)
    local now = minetest.get_us_time() / 1000000
    if last_infected_log_dig[name] and now - last_infected_log_dig[name] < 1.0 then
        return true
    end
    last_infected_log_dig[name] = now
    return false
end

minetest.register_on_dignode(function(pos, oldnode, digger)
    if not (digger and digger:is_player()) then
        return
    end

    local penalty = infected_block_penalty[oldnode.name]
    if not penalty then
        return
    end

    if oldnode.name == "bacterial_mod:Infected_Log" then
        if infected_log_dig_cooldown(digger:get_player_name()) then
            return
        end
    end

    local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
    evolution_points = evolution_points - penalty
    if evolution_points < 0 then
        evolution_points = 0
    end
    ep_storage:set_string("evolution_points", tostring(evolution_points))
end)

minetest.register_node("bacterial_mod:mold", {
    description = "Mold",
    drawtype = "nodebox",
    paramtype = "light",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5},  -- 1/16 height for thin carpet-like block
    },
    tiles = {"Mold.png"},
    groups = {snappy = 3, flammable = 2, attached_node = 1},
    walkable = false,
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5},
    },
    collision_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5},
    },
})

-- Load additional entity definitions (InfEntities.lua) if present
-- (Previous infection/chat replacement system removed)
-- Hazmat Suit with durability tracking
-- Formula: 240 durability * ~273 wear per durability = ~65535 total wear
local HAZMAT_WEAR_PER_DURABILITY = 273
local HAZMAT_MAX_DURABILITY = 240
local HAZMAT_MAX_WEAR = HAZMAT_WEAR_PER_DURABILITY * HAZMAT_MAX_DURABILITY

minetest.register_tool("bacterial_mod:hazmat_suit", {
    description = "Hazmat Suit",
    inventory_image = "Hazmat_Suit.png",
    wear = 0,
})

minetest.register_craftitem("bacterial_mod:Flesh", {
    description = "Infected Flesh",
    inventory_image = "Infected_Flesh.png",
})

minetest.register_craftitem("bacterial_mod:flask_sanitizer", {
    description = "Flask of Sanitizer",
    inventory_image = "Sanitizer.png",
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.under
            local radius = 10

            -- Find all infected blocks in the area
            local infected_positions = minetest.find_nodes_in_area(
                vector.subtract(pos, radius),
                vector.add(pos, radius),
                {
                    "bacterial_mod:Infected_Soil",
                    "bacterial_mod:Infected_Rock",
                    "bacterial_mod:Infected_Log"
                }
            )

            -- If no infected blocks found, do nothing
            if #infected_positions == 0 then
                return itemstack
            end

            -- Shuffle the positions for random removal order
            for i = #infected_positions, 2, -1 do
                local j = math.random(i)
                infected_positions[i], infected_positions[j] = infected_positions[j], infected_positions[i]
            end

            -- Function to remove blocks gradually
            local function remove_blocks(index, total_removed)
                if total_removed >= 30 or index > #infected_positions then
                    return
                end

                -- Remove up to 2 blocks this iteration
                local blocks_to_remove = math.min(2, #infected_positions - index + 1)
                for i = 1, blocks_to_remove do
                    if index <= #infected_positions then
                        local pos = infected_positions[index]
                        local node = minetest.get_node(pos)
                        -- Convert infected blocks to their respective replacements
                        if node.name == "bacterial_mod:Infected_Soil" then
                            minetest.set_node(pos, {name = "default:gravel"})
                        elseif node.name == "bacterial_mod:Infected_Rock" then
                            minetest.set_node(pos, {name = "default:cobble"})
                        elseif node.name == "bacterial_mod:Infected_Log" then
                            minetest.set_node(pos, {name = "default:tree"})
                        end
                        index = index + 1
                        total_removed = total_removed + 1
                    end
                end

                -- Schedule next removal after 0.5 seconds (2 blocks per second)
                minetest.after(0.5, remove_blocks, index, total_removed)
            end

            -- Start the removal process
            remove_blocks(1, 0)

            -- Consume the item
            itemstack:take_item()
            return itemstack
        end
        return itemstack
    end,
})
local infected_players = {}

local function init_hazmat_inventory(player)
    local name = player:get_player_name()
    local detname = "hazmat_" .. name

    -- Avoid duplicate creation
    if minetest.get_inventory({type="detached", name=detname}) then
        return
    end

    local function save_slot(inv)
        local stack = inv:get_stack("main", 1)
        local meta = player:get_meta()
        meta:set_string("hazmat_suit", stack:to_string())
    end

    local inv = minetest.create_detached_inventory(detname, {
        allow_put = function(inv, listname, index, stack, player2)
            return stack:get_name() == "bacterial_mod:hazmat_suit" and 1 or 0
        end,
        allow_take = function(inv, listname, index, stack, player2)
            return stack:get_count()
        end,
        on_put = function(inv, listname, index, stack, player2)
            save_slot(inv)
        end,
        on_take = function(inv, listname, index, stack, player2)
            save_slot(inv)
        end,
        on_move = function(inv)
            save_slot(inv)
        end,
    })
    inv:set_size("main", 1)

    -- Restore saved suit immediately on creation
    local saved = player:get_meta():get_string("hazmat_suit")
    if saved and saved ~= "" then
        inv:set_stack("main", 1, ItemStack(saved))
    end
end


sfinv.register_page("bacterial_mod:hazmat", {
    title = "Hazmat",
    get = function(self, player, context)
        local name = player:get_player_name()
        local inv = minetest.get_inventory({type="detached", name="hazmat_" .. name})
        if not inv then
            init_hazmat_inventory(player)
        end
        return sfinv.make_formspec(
            player, context,
            "size[8,7]" ..
            "label[0.2,0.2;Hazmat Gear]" ..
            "label[0.2,0.7;Suit:]" ..
            "list[detached:hazmat_" .. name .. ";main;1.3,0.5;1,1;]" ..
            "list[current_player;main;0,3;8,4;]" ..
            "listring[detached:hazmat_" .. name .. ";main]" ..
            "listring[current_player;main]",
            false
        )
    end,
})

minetest.register_on_joinplayer(init_hazmat_inventory)

local function is_wearing_hazmat(player)
    local name = player:get_player_name()
    local inv = minetest.get_inventory({type="detached", name="hazmat_" .. name})
    if not inv or inv:is_empty("main") then
        return false
    end
    local item = inv:get_stack("main", 1)
    return item:get_name() == "bacterial_mod:hazmat_suit"
end

-- Track durability degradation for hazmat suits (every 5 seconds)
local hazmat_timers = {}

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        hazmat_timers[name] = (hazmat_timers[name] or 0) + dtime

        -- Check every 5 seconds
        if hazmat_timers[name] >= 5 then
            hazmat_timers[name] = 0

            -- Degrade hazmat suit durability
            if is_wearing_hazmat(player) then
                local inv = minetest.get_inventory({type="detached", name="hazmat_" .. name})
                if inv then
                    local stack = inv:get_stack("main", 1)
                    if stack:get_name() == "bacterial_mod:hazmat_suit" then
                        local wear = stack:get_wear()
                        local new_wear = wear + HAZMAT_WEAR_PER_DURABILITY

                        -- Check if suit is completely worn out
                        if new_wear >= HAZMAT_MAX_WEAR then
                            inv:set_stack("main", 1, ItemStack(""))
                            minetest.chat_send_player(name, "Your Hazmat Suit has deteriorated beyond repair!")
                            -- Save to player metadata
                            player:get_meta():set_string("hazmat_suit", "")
                        else
                            stack:set_wear(new_wear)
                            inv:set_stack("main", 1, stack)
                            -- Save to player metadata
                            player:get_meta():set_string("hazmat_suit", stack:to_string())
                        end
                    end
                end
            end
        end

        -- Skip if already infected (original infection logic)
        if not infected_players[name] then
            local pos = player:get_pos()
            local below = vector.round({ x = pos.x, y = pos.y - 1, z = pos.z })
            local node = minetest.get_node_or_nil(below)

            if node and (node.name == "bacterial_mod:Infected_Soil" or node.name == "bacterial_mod:Infected_Rock") then
                if not is_wearing_hazmat(player) then
                    infected_players[name] = { timer = 0, stage = "incubation" }
                    minetest.chat_send_player(name, "You feel... off.")
                    minetest.log("action", "[bacterial_mod] Infection triggered for " .. name)
                end
            end
        end
    end
end)


if USE_SFINV then
    sfinv.pages = sfinv.pages or {}
    if not sfinv.pages["bacterial_mod:hazmat"] then
        sfinv.register_page("bacterial_mod:hazmat", {
            title = "Hazmat",
            get = function(self, player, context)
                local name = player:get_player_name()
                return sfinv.make_formspec(
                    player, context,
                    "size[8,7]" ..
                    "label[0.2,0.2;Hazmat Gear]" ..
                    "label[0.2,0.7;Suit:]" ..
                    "list[detached:hazmat_" .. name .. ";main;1.3,0.5;1,1;]" ..
                    "list[current_player;main;0,3;8,4;]" ..
                    "listring[detached:hazmat_" .. name .. ";main]" ..
                    "listring[current_player;main]",
                    false
                )
            end,
        })
    end
end


local function show_hazmat_formspec(player)
    local name = player:get_player_name()
    local det = "detached:hazmat_" .. name
    local fs =
        "size[8,7]" ..
        "label[0.2,0.2;Hazmat Gear]" ..
        "label[0.2,0.7;Suit:]" ..
        "list[" .. det .. ";main;1.3,0.5;1,1;]" ..
        "list[current_player;main;0,3;8,4;]" ..
        "listring[" .. det .. ";main]" ..
        "listring[current_player;main]"
    minetest.show_formspec(name, "bacterial_mod:hazmat_fs", fs)
end

-- One command that works in both cases
minetest.register_chatcommand("hazmat", {
    description = "Open Hazmat Gear UI",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found." end
        -- Ensure detached inv exists
        if init_hazmat_inventory then init_hazmat_inventory(player) end

        if USE_SFINV then
            -- Only safe to call if sfinv exists
            sfinv.set_page(player, "bacterial_mod:hazmat")
        else
            show_hazmat_formspec(player)
        end
        return true, "Opened Hazmat UI."
    end
})

local infected_block_count = 0
local max_infected_blocks = 100 -- tweak this based on performance
local infection_timer = 0

minetest.register_globalstep(function(dtime)
    infection_timer = infection_timer + dtime
    if infection_timer > 5 then
        infected_block_count = 0
        infection_timer = 0
    end
end)

local phase_infection_settings = { -- Unused variable?
    [0] = {interval = 80, chance = 80},
    [1] = {interval = 70, chance = 70},
    [2] = {interval = 60, chance = 60},
    [3] = {interval = 50, chance = 50},
    [4] = {interval = 40, chance = 40},
    [5] = {interval = 30, chance = 30},
    [6] = {interval = 20, chance = 20},
    [7] = {interval = 15, chance = 10},
    [8] = {interval = 5, chance = 10},
}

minetest.register_abm({
    minetest.log("action", "[bacterial_mod] Infection globalstep running"),
    label = "Bacterial Infection Spread",
    nodenames = {"bacterial_mod:Infected_Rock", "bacterial_mod:Infected_Soil"},
    interval = 50,
    chance = 50,
    action = function(pos, node)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0

        local adjacent_positions = {
            {x=pos.x+1, y=pos.y, z=pos.z},
            {x=pos.x-1, y=pos.y, z=pos.z},
            {x=pos.x, y=pos.y+1, z=pos.z},
            {x=pos.x, y=pos.y-1, z=pos.z},
            {x=pos.x, y=pos.y, z=pos.z+1},
            {x=pos.x, y=pos.y, z=pos.z-1},
        }

        for _, adj_pos in ipairs(adjacent_positions) do
            local adj_node = minetest.get_node_or_nil(adj_pos)
            if adj_node then
                local def = minetest.registered_nodes[adj_node.name]
                if def and def.groups then
                    local target_node = nil
                    if def.groups.crumbly and def.groups.crumbly > 0 then
                        target_node = "bacterial_mod:Infected_Soil"
                    elseif def.groups.cracky and def.groups.cracky > 0 then
                        target_node = "bacterial_mod:Infected_Rock"
                    elseif def.groups.choppy and def.groups.choppy > 0 then
                        target_node = "bacterial_mod:Infected_Log"
                    end

                    if target_node and infected_block_count < max_infected_blocks then
                        minetest.set_node(adj_pos, {name = target_node})
                        infected_block_count = infected_block_count + 1
                        evolution_points = evolution_points + 25
                        ep_storage:set_string("evolution_points", tostring(evolution_points))
                        check_phase_unlock()
                    end
                end
            end
        end
    end
})



local phases = {

    {threshold = 250, name = "Phase 1", unlock = function()
        -- Enable faster spread or new infected block types
        minetest.chat_send_all("One")
    for _, player in ipairs(minetest.get_connected_players()) do
        minetest.sound_play("Phase_1", {
            to_player = player:get_player_name(),
            gain = 1.0,
            pitch = 1.0,
        })
    end
end},
    {threshold = 700, name = "Phase 2", unlock = function()
        -- Spawn infected mobs or unlock new biomes
        minetest.chat_send_all("Two")
    for _, player in ipairs(minetest.get_connected_players()) do
        minetest.sound_play("Phase_2", {
            to_player = player:get_player_name(),
            gain = 1.0,
            pitch = 1.0,
        })
    end
end},
    {threshold = 1200, name = "Phase 3", unlock = function()
        -- Enable faster spread or new infected block types and NEXUS
        minetest.chat_send_all("Three")
    for _, player in ipairs(minetest.get_connected_players()) do
        minetest.sound_play("Phase_3", {
            to_player = player:get_player_name(),
            gain = 1.0,
            pitch = 1.0,
        })
    end
end},
    {threshold = 9750, name = "Phase 4", unlock = function()
        -- Spawn infected mobs or unlock new biomes
        minetest.chat_send_all("Four")
    for _, player in ipairs(minetest.get_connected_players()) do
        minetest.sound_play("Phase_4", {
            to_player = player:get_player_name(),
            gain = 1.0,
            pitch = 1.0,
        })
    end
end},
    {threshold = 32500, name = "Phase 5", unlock = function()
        -- Enable faster spread or new infected block types
        minetest.chat_send_all("Five")
    for _, player in ipairs(minetest.get_connected_players()) do
        minetest.sound_play("Phase_5", {
            to_player = player:get_player_name(),
            gain = 1.0,
            pitch = 1.0,
        })
    end
end},
    {threshold = 135000, name = "Phase 6", unlock = function()
        -- Spawn infected mobs or unlock new biomes
        minetest.chat_send_all("Six")
    for _, player in ipairs(minetest.get_connected_players()) do
        minetest.sound_play("Phase_6", {
            to_player = player:get_player_name(),
            gain = 1.0,
            pitch = 1.0,
        })
    end
end},
    {threshold = 850000, name = "Phase 7", unlock = function()
        -- Enable faster spread or new infected block types
        minetest.chat_send_all("Seven")
    for _, player in ipairs(minetest.get_connected_players()) do
        minetest.sound_play("Phase_7", {
            to_player = player:get_player_name(),
            gain = 1.0,
            pitch = 1.0,
        })
    end
end},
    {threshold = 2250000, name = "Phase 8", unlock = function()
        -- Spawn infected mobs or unlock new biomes
        minetest.chat_send_all("Eight")
    for _, player in ipairs(minetest.get_connected_players()) do
        minetest.sound_play("Phase_8", {
            to_player = player:get_player_name(),
            gain = 1.0,
            pitch = 1.0,
        })
    end
end},

}

local function get_current_phase()
    return tonumber(ep_storage:get_string("unlocked_phase_index")) or 0
end

local function set_current_phase(phase)
    if phase < 0 then
        phase = 0
    end
    if phase > #phases then
        phase = #phases
    end
    ep_storage:set_string("unlocked_phase_index", tostring(phase))
    return phase
end

local current_phase = get_current_phase() -- This is saved, but never accessed?

function check_phase_unlock()
    local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
    local phase_now = get_current_phase()
    local new_phase = phase_now

    for i = phase_now + 1, #phases do
        if evolution_points >= phases[i].threshold then
            new_phase = i
        else
            break
        end
    end

    if new_phase > phase_now then
        for i = phase_now + 1, new_phase do
            phases[i].unlock()
        end
        set_current_phase(new_phase)
        current_phase = new_phase
    end
end

minetest.register_chatcommand("getpoints", {
    description = "Get current evolution points",
    func = function(name)
        local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
        return true, "Evolution Points: " .. evolution_points
    end
})

minetest.register_chatcommand("getphase", {
    description = "Get current phase",
    func = function(name)
        local phase = get_current_phase()
        return true, "Current Phase: " .. phase
    end
})

minetest.register_chatcommand("setpoints", {
    description = "Set evolution points",
    privs = {server = true},
    func = function(name, param)
        local amount = tonumber(param)
        if not amount or amount < 0 then
            return false, "Invalid amount. Must be a non-negative number."
        end
        ep_storage:set_string("evolution_points", tostring(amount))
        check_phase_unlock()
        return true, "Evolution points set to " .. amount
    end
})

minetest.register_chatcommand("setphase", {
    description = "Set current phase",
    privs = {server = false},
    func = function(name, param)
        local phase = tonumber(param)
        if not phase then
            return false, "Invalid phase. Must be a number."
        end

        local old_phase = get_current_phase()
        phase = set_current_phase(phase)
        if phase > old_phase then
            phases[phase].unlock()
        end

        -- Set evolution points to the threshold of the target phase
        if phase > 0 and phases[phase] then
            ep_storage:set_string("evolution_points", tostring(phases[phase].threshold))
        else
            ep_storage:set_string("evolution_points", "0")
        end

        current_phase = phase
        return true, "Phase set to " .. phase .. " and Evolution Points set to " .. (phases[phase] and phases[phase].threshold or 0)
    end
})

minetest.register_chatcommand("infect_me", {
    description = "Force infection",
    func = function(name)
        infected_players[name] = {timer = 0, stage = "incubation"}
        return true, "You have been infected."
    end
})

minetest.register_chatcommand("hazmat", {
    description = "Open Hazmat Gear tab",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            init_hazmat_inventory(player) -- ensure inventory exists
            sfinv.set_page(player, "bacterial_mod:hazmat")
        end
    end,
})


local infected_nodes = {
    "bacterial_mod:Infected_Soil",
    "bacterial_mod:Infected_Rock",
}

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < 1 then return end
    timer = 0

    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        local minp = vector.subtract(pos, 32)
        local maxp = vector.add(pos, 32)
        local found = minetest.find_nodes_in_area(minp, maxp, infected_nodes)

        for _, p in ipairs(found) do
            if math.random(50) == 1 then
                minetest.add_particle({
                    pos = vector.add(p, {x=math.random()-0.5, y=1, z=math.random()-0.5}),
                    velocity = {x=0, y=2, z=0},
                    expirationtime = 1,
                    size = 1.2,
                    texture = "Bacterial_Particle.png",
                    glow = 5,
                })
            end
        end
    end
end)


minetest.register_globalstep(function(dtime)
    for name, data in pairs(infected_players) do
        data.timer = data.timer + dtime
        minetest.log("action", "[bacterial_mod] Infection check running")

        local player = minetest.get_player_by_name(name)
        if player then
            local pos = vector.floor(player:get_pos())
            local node_below = minetest.get_node_or_nil({x=pos.x, y=pos.y - 1, z=pos.z}) -- Unused variable?
        end

        if data.stage == "incubation" and data.timer > 5 then
            data.stage = "symptomatic"
            minetest.chat_send_player(name, "You start coughing...")
        elseif data.stage == "symptomatic" and data.timer > 30 then
            local player = minetest.get_player_by_name(name)
            if player then
                player:set_hp(0)
                minetest.chat_send_all(name .. " succumbed to the bacterial infection.")
            end
            infected_players[name] = nil
        end
    end
end)

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        if not infected_players[name] then
            local pos = vector.floor(player:get_pos())
            local below = {x = pos.x, y = pos.y - 1, z = pos.z}
            local node = minetest.get_node_or_nil(below)

            if node and (node.name == "bacterial_mod:Infected_Soil" or node.name == "bacterial_mod:Infected_Rock") then
                if not is_wearing_hazmat(player) then
                    infected_players[name] = { timer = 0, stage = "incubation" }
                    minetest.chat_send_player(name, "You feel... off.")
                    minetest.log("action", "[bacterial_mod] Infection triggered for " .. name)
                end
            end
        end
    end
end)

minetest.register_craftitem("bacterial_mod:antibiotics", {
    description = "Antibiotics",
    inventory_image = "Antibiotics.png",
    on_use = function(itemstack, user, pointed_thing)
    local name = user:get_player_name()
    if infected_players[name] then
        infected_players[name] = nil
        minetest.chat_send_player(name, "Infection cured.")
        itemstack:take_item()  -- Removes one item from the stack
        return itemstack
    else
        minetest.chat_send_player(name, "You're not infected.")
        return itemstack
    end
end
})

minetest.register_craft({
    output = "bacterial_mod:rubber_sheet",
    recipe = {
        {"default:tree", "default:coal_lump"},
    }
})

minetest.register_craftitem("bacterial_mod:rubber_sheet", {
    description = "Rubber Sheet",
    inventory_image = "Rubber_Sheet.png",
})

minetest.register_craftitem("bacterial_mod:hazmat_filter", {
    description = "Hazmat Filter",
    inventory_image = "Hazmat_Filter.png",
})

minetest.register_craft({
    output = "bacterial_mod:hazmat_filter",
    recipe = {
        {"", "default:steel_ingot", ""},
        {"default:steel_ingot", "wool:white", "default:steel_ingot"},
        {"default:tin_ingot", "default:steel_ingot", "default:tin_ingot"},
    }
})

minetest.register_craft({
    output = "bacterial_mod:hazmat_suit",
    recipe = {
        {"bacterial_mod:rubber_sheet", "bacterial_mod:rubber_sheet", "dye:yellow"},
        {"bacterial_mod:rubber_sheet", "default:glass", "bacterial_mod:rubber_sheet"},
        {"bacterial_mod:rubber_sheet", "bacterial_mod:hazmat_filter", "bacterial_mod:rubber_sheet"},
    }
})

-- Shapeless recipe: Repair Hazmat Suit with Hazmat Filter
minetest.register_craft({
    type = "shapeless",
    output = "bacterial_mod:hazmat_suit",
    recipe = {"bacterial_mod:hazmat_suit", "bacterial_mod:hazmat_filter"},
})


-- Safe loader for additional module files


-- Safe loader for additional module files
local function safe_load(filename)
    local filepath = minetest.get_modpath("bacterial_mod") .. "/" .. filename
    local success, err = pcall(dofile, filepath)
    if success then
        minetest.log("action", "[bacterial_mod] Successfully loaded " .. filename)
    else
        minetest.log("error", "[bacterial_mod] Failed to load " .. filename .. ": " .. tostring(err))
    end
    return success
end

-- Function to check if any Nexus entities are within 100 blocks
function bacterial_mod.is_nexus_nearby(pos)
	local entities = minetest.get_objects_inside_radius(pos, 100)
	for _, obj in ipairs(entities) do
		local luaentity = obj:get_luaentity()
		if luaentity and luaentity.name and (
			luaentity.name == "bacterial_mod:nexus_stage_1" or
			luaentity.name == "bacterial_mod:nexus_stage_2" or
		luaentity.name == "bacterial_mod:nexus_stage_3"
		) then
			return true
		end
	end
	return false
end

-- Track time for sleeping detection
local last_time

-- Globalstep to detect sleeping (time jump to morning)
minetest.register_globalstep(function(dtime)
    local current_time = minetest.get_timeofday()
    if not current_time then return end
    if last_time and last_time > 0.8 and current_time > 0.1 and current_time < 0.3 then  -- Time jumped to morning from late night, likely due to sleeping
        for _, player in ipairs(minetest.get_connected_players()) do
            local phase = get_current_phase()
            local multiplier = phase == 0 and 1 or (4 * phase - 1)
            local points = 20 * multiplier
            local evolution_points = tonumber(ep_storage:get_string("evolution_points")) or 0
            evolution_points = evolution_points + points
            ep_storage:set_string("evolution_points", tostring(evolution_points))
            check_phase_unlock()
            minetest.chat_send_player(player:get_player_name(), "You gained " .. points .. " evolution points from sleeping.")
        end
    end
    last_time = current_time
end)

-- Load InfEntities and Equipment modules
safe_load("InfEntities.lua")
safe_load("bacterial_spawn.lua")
safe_load("Equipment.lua")
safe_load("Musical.lua")
