local Spawner = {}
Spawner.__index = Spawner

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
            local e = require("enemy"):new(0,0, 30, 80, {1,0,0}, "melee")
            e:setDungeon(self.dungeon)
            e:setTarget(self.player)
            -- Spawn outside of screen
            local mapW, mapH = self.dungeon.gridW * self.dungeon.tileSize, self.dungeon.gridH * self.dungeon.tileSize
            e:spawnAtEdge(self.player.x, self.player.y, mapW, mapH)
            table.insert(self.enemies, e)

            self.enemiesToSpawn = self.enemiesToSpawn - 1
            self.spawnTimer = self.spawnInterval
        end
    end

    -- Update all enemies
    for i=#self.enemies,1,-1 do
        local e = self.enemies[i]
        if e.hp <= 0 then
            table.remove(self.enemies, i)
        else
            e:update(dt)
            e:attack(dt, {x = self.player.x, y = self.player.y})
        end
    end
end

function Spawner:draw()
    for _, e in ipairs(self.enemies) do
        e:draw()
    end
end

return Spawner
