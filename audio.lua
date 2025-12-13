local Audio = {}

local sfx = {}
local music = {}
local sfxVolume = 1.0
local musicVolume = 1.0
local originalSFXVolume = {}
local originalMusicVolume = {}

function Audio.load()
    -- Try to load audio, but don't crash if files are missing
    local function tryLoad(path, type)
        local success, result = pcall(love.audio.newSource, path, type)
        if success then
            return result
        else
            print("Warning: Could not load audio file:", path)
            return nil
        end
    end

    sfx.button = tryLoad("audio/613409__josheb_policarpio__button-8.wav", "static")
    sfx.attack_player = tryLoad("audio/720118__baggonotes__player_shoot1.wav", "static")
    sfx.attack_enemy = tryLoad("audio/363151__jofae__game-style-shot-noise.mp3", "static")
    sfx.player_hurt = tryLoad("audio/385046__mortisblack__damage.ogg", "static")
    sfx.enemy_death = tryLoad("audio/455251__lilmati__retro-underwater-shot.wav", "static")

    originalSFXVolume.button = 0.6
    originalSFXVolume.attack_player = 0.5
    originalSFXVolume.attack_enemy = 0.4
    originalSFXVolume.player_hurt = 0.7
    originalSFXVolume.enemy_death = 0.5

    for name, sound in pairs(sfx) do
        if sound then
            sound:setVolume((originalSFXVolume[name] or 1) * sfxVolume)
        end
    end

    music.bg = tryLoad("audio/834258__cervidstudios__crystal_cave_wrap.ogg", "stream")
    if music.bg then
        music.bg:setLooping(true)
        originalMusicVolume.bg = 0.1
        music.bg:setVolume(originalMusicVolume.bg * musicVolume)
    end
end

function Audio.play(name)
    local sound = sfx[name]
    if sound then
        sound:stop()
        sound:setVolume((originalSFXVolume[name] or 1) * sfxVolume)
        sound:play()
    end
end

function Audio.playMusic(name)
    local sound = music[name]
    if sound and not sound:isPlaying() then
        sound:setVolume((originalMusicVolume[name] or 1) * musicVolume)
        sound:play()
    end
end

function Audio.stopMusic(name)
    if music[name] then music[name]:stop() end
end

function Audio.setSFXVolume(v)
    sfxVolume = math.max(0, math.min(1, v))
    for name, sound in pairs(sfx) do
        if sound then sound:setVolume((originalSFXVolume[name] or 1) * sfxVolume) end
    end
end

function Audio.setMusicVolume(v)
    musicVolume = math.max(0, math.min(1, v))
    for name, sound in pairs(music) do
        if sound then sound:setVolume((originalMusicVolume[name] or 1) * musicVolume) end
    end
end

return Audio