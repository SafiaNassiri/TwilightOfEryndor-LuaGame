local Audio = {}

-- Tables to store sounds
local sfx = {}
local music = {}

-- Internal global volume multipliers (0.0 to 1.0)
local sfxVolume = 1.0
local musicVolume = 1.0

-- Store original SFX volumes (for per-sound volume)
local originalSFXVolume = {}
local originalMusicVolume = {}

function Audio.load()
    -- === SOUND EFFECTS ===
    sfx.button        = love.audio.newSource("audio/613409__josheb_policarpio__button-8.wav", "static")
    sfx.attack_player = love.audio.newSource("audio/720118__baggonotes__player_shoot1.wav", "static")
    sfx.attack_enemy  = love.audio.newSource("audio/363151__jofae__game-style-shot-noise.mp3", "static")
    sfx.player_hurt   = love.audio.newSource("audio/385046__mortisblack__damage.ogg", "static")
    sfx.enemy_death   = love.audio.newSource("audio/455251__lilmati__retro-underwater-shot.wav", "static")

    -- Set custom default individual volumes here (0.0 to 1.0)
    originalSFXVolume.button        = 0.6
    originalSFXVolume.attack_player = 0.5
    originalSFXVolume.attack_enemy  = 0.4
    originalSFXVolume.player_hurt   = 0.7
    originalSFXVolume.enemy_death   = 0.5

    -- Apply the initial volumes
    for name, sound in pairs(sfx) do
        sound:setVolume((originalSFXVolume[name] or 1) * sfxVolume)
    end

    -- === MUSIC ===
    music.bg = love.audio.newSource("audio/834258__cervidstudios__crystal_cave_wrap.ogg", "stream")
    music.bg:setLooping(true)

    -- Set default individual volume for music
    originalMusicVolume.bg = 0.1
    music.bg:setVolume(originalMusicVolume.bg * musicVolume)
end

-- Play SFX once
function Audio.play(name)
    local sound = sfx[name]
    if sound then
        sound:stop()
        sound:setVolume((originalSFXVolume[name] or 1) * sfxVolume)
        sound:play()
    else
        print("SFX not found:", name)
    end
end

-- Play music
function Audio.playMusic(name)
    local sound = music[name]
    if sound then
        if not sound:isPlaying() then
            sound:setVolume((originalMusicVolume[name] or 1) * musicVolume)
            sound:play()
        end
    else
        print("Music not found:", name)
    end
end

-- Stop music
function Audio.stopMusic(name)
    local sound = music[name]
    if sound then
        sound:stop()
    end
end

-- Adjust global SFX volume (0.0 to 1.0)
function Audio.setSFXVolume(v)
    sfxVolume = math.max(0, math.min(1, v))
    for name, sound in pairs(sfx) do
        sound:setVolume((originalSFXVolume[name] or 1) * sfxVolume)
    end
end

-- Adjust global music volume (0.0 to 1.0)
function Audio.setMusicVolume(v)
    musicVolume = math.max(0, math.min(1, v))
    for name, sound in pairs(music) do
        sound:setVolume((originalMusicVolume[name] or 1) * musicVolume)
    end
end

-- Adjust individual SFX volume
function Audio.setSFXIndividualVolume(name, v)
    if sfx[name] then
        originalSFXVolume[name] = math.max(0, math.min(1, v))
        sfx[name]:setVolume(originalSFXVolume[name] * sfxVolume)
    end
end

-- Adjust individual music volume
function Audio.setMusicIndividualVolume(name, v)
    if music[name] then
        originalMusicVolume[name] = math.max(0, math.min(1, v))
        music[name]:setVolume(originalMusicVolume[name] * musicVolume)
    end
end

return Audio
