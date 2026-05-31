local modpath = bacterial_mod and bacterial_mod.music and bacterial_mod.music.modpath or minetest.get_modpath("bacterial_mod")
local music_dir = modpath .. "/music"

local player_music_state = {}
local music_tracks = {}
local track_tokens = {}

local function is_music_file(filename)
    local ext = filename:match("(%.[^%.]+)$")
    if not ext then
        return false
    end
    ext = string.lower(ext)
    return ext == ".ogg" or ext == ".wav" or ext == ".mp3"
end

local function safe_track_token(filename)
    local name = filename:gsub("%.[^%.]+$", "")
    name = name:lower():gsub("[^%w]+", "_")
    name = name:gsub("_+", "_")
    name = name:gsub("^_+", "")
    name = name:gsub("_+$", "")
    return name
end

local function normalize_filename(entry)
    if not entry then
        return nil
    end
    local filename = entry:gsub("\\", "/")
    return filename:match("([^/]+)$")
end

local function load_music_tracks()
    local files = minetest.get_dir_list(music_dir, false)
    if not files then
        return
    end
    for _, entry in ipairs(files) do
        local filename = normalize_filename(entry)
        if filename and is_music_file(filename) then
            table.insert(music_tracks, filename)
        end
    end
end

load_music_tracks()

for _, filename in ipairs(music_tracks) do
    local token = safe_track_token(filename)
    if token ~= "" and not track_tokens[token] then
        track_tokens[token] = filename
    end
end

local function choose_track(exclude)
    if #music_tracks == 0 then
        return nil
    end
    if #music_tracks == 1 then
        return music_tracks[1]
    end
    local track
    local tries = 0
    repeat
        track = music_tracks[math.random(#music_tracks)]
        tries = tries + 1
    until track ~= exclude or tries >= 10
    return track
end

local function find_track_by_name(search)
    if not search or search == "" then
        return nil
    end
    local trimmed = search:gsub("^%s*(.-)%s*$", "%1")
    for _, filename in ipairs(music_tracks) do
        if filename:lower() == trimmed:lower() then
            return filename
        end
    end
    local token = safe_track_token(trimmed)
    return track_tokens[token]
end

local function stop_player_music(player_name)
    local state = player_music_state[player_name]
    if not state then
        return
    end
    state.active = false
    if state.sound_handle then
        minetest.sound_stop(state.sound_handle)
        state.sound_handle = nil
    end
    player_music_state[player_name] = nil
end

local function play_selected_track(player_name, track)
    if not player_name or not track then
        return false
    end
    if not find_track_by_name(track) and not track_tokens[safe_track_token(track)] then
        return false
    end
    local actual_track = find_track_by_name(track) or track_tokens[safe_track_token(track)]
    if not actual_track then
        return false
    end
    stop_player_music(player_name)
    local sound_name = "music/" .. actual_track
    local handle = minetest.sound_play(sound_name, {
        to_player = player_name,
        gain = 0.8,
        loop = false,
    })
    player_music_state[player_name] = {
        active = true,
        current_song = actual_track,
        sound_handle = handle,
        countdown = math.random(480, 720),
    }
    schedule_next_song(player_name, actual_track)
    return true
end

local function schedule_next_song(player_name, previous_song)
    local state = player_music_state[player_name]
    if not state or not state.active then
        return
    end
    local interval = math.random(480, 720)
    state.countdown = interval
    minetest.after(interval, function(name, song)
        local current_state = player_music_state[name]
        if not current_state or not current_state.active then
            return
        end
        if current_state.current_song ~= song then
            return
        end
        local next_track = choose_track(song)
        if not next_track then
            return
        end
        if current_state.sound_handle then
            minetest.sound_stop(current_state.sound_handle)
            current_state.sound_handle = nil
        end
        local sound_name = "music/" .. next_track
        current_state.sound_handle = minetest.sound_play(sound_name, {
            to_player = name,
            gain = 0.8,
            loop = false,
        })
        current_state.current_song = next_track
        schedule_next_song(name, next_track)
    end, player_name, previous_song)
end

local function start_music_for_player(player_name)
    if not minetest.get_player_by_name(player_name) then
        return
    end
    if #music_tracks == 0 then
        minetest.log("warning", "[bacterial_mod] No music files found in " .. music_dir)
        return
    end
    stop_player_music(player_name)
    local track = choose_track()
    if not track then
        return
    end
    local sound_name = "music/" .. track
    local handle = minetest.sound_play(sound_name, {
        to_player = player_name,
        gain = 0.8,
        loop = false,
    })
    player_music_state[player_name] = {
        active = true,
        current_song = track,
        sound_handle = handle,
        countdown = math.random(480, 720),
    }
    schedule_next_song(player_name, track)
end

minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    stop_player_music(player_name)
    minetest.after(15, function(name)
        if minetest.get_player_by_name(name) then
            start_music_for_player(name)
        end
    end, player_name)
end)

minetest.register_on_leaveplayer(function(player)
    stop_player_music(player:get_player_name())
end)

minetest.register_chatcommand("musicplay", {
    params = "<song>",
    description = "Play a specific music track from the music folder.",
    privs = {shout = true},
    func = function(name, param)
        if not param or param == "" then
            return false, "Usage: /musicplay <song name>"
        end
        local track = find_track_by_name(param)
        if not track then
            return false, "Song not found. Available songs: " .. table.concat(music_tracks, ", ")
        end
        play_selected_track(name, track)
        return true, "Playing music: " .. track
    end,
})

for token, filename in pairs(track_tokens) do
    local command_name = "musicplay_" .. token
    minetest.register_chatcommand(command_name, {
        params = "",
        description = "Play the song: " .. filename,
        privs = {shout = true},
        func = function(name, param)
            play_selected_track(name, filename)
            return true, "Playing music: " .. filename
        end,
    })
end
