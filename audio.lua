local Audio = {}

local sfx = {}
local music = {}
local sfxVolume = 1.0
local musicVolume = 0.3

-- Individual volume levels - TWEAK THESE!
local volumes = {
    button = 0.8,
    attack_player = 1.0,    -- Player shooting (turn this UP)
    attack_enemy = 0.6,
    player_hurt = 0.9,
    enemy_death = 0.7,
    bg = 0.15               -- Background music
}

function Audio.load()
    local function tryLoad(path, type)
        local success, result = pcall(love.audio.newSource, path, type)
        if success then
            print("✓ Loaded:", path)
            return result
        else
            print("✗ Missing:", path)
            return nil
        end
    end

    -- Load sounds
    sfx.button = tryLoad("audio/button.wav", "static")
    sfx.attack_player = tryLoad("audio/455251__lilmati__retro-underwater-shot.wav", "static")
    sfx.attack_enemy = tryLoad("audio/720118__baggonotes__player_shoot1.wav", "static")
    sfx.player_hurt = tryLoad("audio/720118__baggonotes__player_shoot1.wav", "static")
    sfx.enemy_death = tryLoad("audio/385046__mortisblack__damage.ogg", "static")
    
    -- Apply individual volumes to SFX
    for name, sound in pairs(sfx) do
        if sound then
            sound:setVolume((volumes[name] or 1.0) * sfxVolume)
        end
    end
    
    music.bg = tryLoad("audio/834258__cervidstudios__crystal_cave_wrap.ogg", "stream")
    if music.bg then
        music.bg:setLooping(true)
        music.bg:setVolume((volumes.bg or 1.0) * musicVolume)
    end
end

function Audio.play(name)
    local sound = sfx[name]
    if sound then
        sound:stop()
        sound:setVolume((volumes[name] or 1.0) * sfxVolume)
        sound:play()
        print("Playing:", name, "at volume:", sound:getVolume())
    else
        print("Sound not loaded:", name)
    end
end

function Audio.playMusic(name)
    local sound = music[name]
    if sound and not sound:isPlaying() then
        sound:setVolume((volumes[name] or 1.0) * musicVolume)
        sound:play()
        print("Playing music:", name)
    end
end

function Audio.stopMusic(name)
    if music[name] then music[name]:stop() end
end

function Audio.setSFXVolume(v)
    sfxVolume = math.max(0, math.min(1, v))
    for name, sound in pairs(sfx) do
        if sound then 
            sound:setVolume((volumes[name] or 1.0) * sfxVolume)
        end
    end
end

function Audio.setMusicVolume(v)
    musicVolume = math.max(0, math.min(1, v))
    if music.bg then
        music.bg:setVolume((volumes.bg or 1.0) * musicVolume)
    end
end

return Audio