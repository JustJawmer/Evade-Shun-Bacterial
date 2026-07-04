USE_SFINV = minetest.get_modpath("sfinv") ~= nil
local infected_players = bacterial_mod.infected_players

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
                        local ipos = infected_positions[index]
                        local node = minetest.get_node(ipos)
                        -- Convert infected blocks to their respective replacements
                        if node.name == "bacterial_mod:Infected_Soil" then
                            minetest.set_node(ipos, {name = "default:gravel"})
                        elseif node.name == "bacterial_mod:Infected_Rock" then
                            minetest.set_node(ipos, {name = "default:cobble"})
                        elseif node.name == "bacterial_mod:Infected_Log" then
                            minetest.set_node(ipos, {name = "default:tree"})
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

-- Infect unprotected players who stand on infected nodes
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
