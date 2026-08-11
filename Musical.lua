local modpath = bacterial_mod and bacterial_mod.music and bacterial_mod.music.modpath or minetest.get_modpath("bacterial_mod")
local music_dir = modpath .. "/sounds"

-- Client-directed timer and randomizer state
local Timer = 600
local Randomizer = 0
local second_accumulator = 0

math.randomseed(os.time())

minetest.register_on_mods_loaded(function()
    Timer = 600
    Randomizer = 0
end)

local function play_sound_to_player(player, name)
    if not player or not player:is_player() then return end
    local pname = player:get_player_name()
    if not pname or pname == "" then return end

    -- name should be something like "ambDEMO"
    minetest.sound_play(name, {
        to_player = pname,
        gain = 3.0,
        max_hear_distance = 0,
    })
end

local function play_random_track(player)
    if Randomizer == 1 then
        play_sound_to_player(player, "ambDEMO")
    elseif Randomizer == 2 then
        play_sound_to_player(player, "beingWatched")
    elseif Randomizer == 3 then
        play_sound_to_player(player, "failedSubject")
    end
end

minetest.register_globalstep(function(dtime)
    second_accumulator = second_accumulator + dtime
    while second_accumulator >= 1 do
        second_accumulator = second_accumulator - 1
        Timer = Timer - 1

        if Timer == 0 then
            Randomizer = math.random(1, 3)
            for _, player in ipairs(minetest.get_connected_players()) do
                play_random_track(player)
            end
        elseif Timer < 0 then
            Timer = 600
        end
    end
end)

local valid_songs = {
    ambDEMO = true,
    beingWatched = true,
    failedSubject = true,
}

minetest.register_chatcommand("playsong", {
    params = "<name>",
    description = "Play a music track.",
    func = function(name, param)
        local song = param:trim()
        if not valid_songs[song] then
            return false, "Invalid song. Available: ambDEMO, beingWatched, failedSubject"
        end

        local player = minetest.get_player_by_name(name)
        play_sound_to_player(player, song)
        return true, "Playing " .. song
    end,
})

