local Spawner = {}
Spawner.__index = Spawner

-- Enemy types (you can adjust or pass from main.lua)
local enemyTypes = {
    {speed = 80, hp = 30, color = {1,0,0}, type = "melee"},
    {speed = 50, hp = 50, color = {1,0.5,0}, type = "tank"},
    {speed = 120, hp = 20, color = {0,1,0}, type = "ranged"}
}

function Spawner:new(dungeon, player)
    local s = {
        dungeon = dungeon,
        player = player,
        enemies = {},        -- active enemies
        wave = 0,            -- current wave
        waveTimer = 3,       -- 3 seconds before wave
        spawnInterval = 1,   -- time between spawning enemies in a wave
        enemiesToSpawn = 0,  -- enemies left to spawn this wave
        spawnTimer = 0       -- timer for next enemy spawn
    }
    setmetatable(s, Spawner)
    return s
end

-- Helper: pick a random walkable tile
local function randomWalkablePosition(dungeon)
    local ts = dungeon.tileSize or 32
    local x, y
    repeat
        local gx = math.random(1, dungeon.gridW)
        local gy = math.random(1, dungeon.gridH)
        x, y = (gx-0.5)*ts, (gy-0.5)*ts
    until dungeon:isWalkable(x, y)
    return x, y
end

-- Update: handle wave timers and spawning
function Spawner:update(dt)
    -- Spawn wave if timer elapsed
    self.waveTimer = self.waveTimer - dt
    if self.waveTimer <= 0 then
        self.wave = self.wave + 1
        self.enemiesToSpawn = 5 + self.wave * 2  -- increase enemies per wave
        self.spawnTimer = 0
        self.waveTimer = 15  -- next wave in 15 sec
    end

    -- Spawn individual enemies
    if self.enemiesToSpawn > 0 then
        self.spawnTimer = self.spawnTimer - dt
        if self.spawnTimer <= 0 then
            local Enemy = require("enemy")
            local typeDef = enemyTypes[math.random(#enemyTypes)]  -- pick random type
            local e = Enemy:new(0, 0, typeDef.hp, typeDef.speed, typeDef.color, typeDef.type)
            e:setDungeon(self.dungeon)
            e:setTarget(self.player)

            -- Spawn on a random walkable tile
            local x, y = randomWalkablePosition(self.dungeon)
            e.x, e.y = x, y

            table.insert(self.enemies, e)
            self.enemiesToSpawn = self.enemiesToSpawn - 1
            self.spawnTimer = self.spawnInterval
        end
    end
end

function Spawner:draw()
    for _, e in ipairs(self.enemies) do
        e:draw()
    end
end

return Spawner
