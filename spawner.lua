local Spawner = {}
Spawner.__index = Spawner

local EnemyModule = require("enemy")  -- Load enemy module at the top

-- Enemy types (you can adjust or pass from main.lua)
local enemyTypes = {
    {speed = 90, hp = 50, color = {1,0,0}, type = "melee"},
    {speed = 60, hp = 70, color = {1,0.5,0}, type = "tank"},
    {speed = 120, hp = 35, color = {0,1,0}, type = "ranged"}
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

-- Check if position is off-screen
local function isOffScreen(x, y, playerX, playerY)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local buffer = 100  -- spawn at least 100 pixels off screen
    
    local minX = playerX - w/2 - buffer
    local maxX = playerX + w/2 + buffer
    local minY = playerY - h/2 - buffer
    local maxY = playerY + h/2 + buffer
    
    -- Return true if position is outside the viewport
    return x < minX or x > maxX or y < minY or y > maxY
end

-- Pick a random walkable tile that's off-screen
local function randomOffScreenPosition(dungeon, playerX, playerY)
    local ts = dungeon.tileSize or 32
    local x, y
    local attempts = 0
    local maxAttempts = 100
    
    repeat
        local gx = math.random(1, dungeon.gridW)
        local gy = math.random(1, dungeon.gridH)
        x, y = (gx-0.5)*ts, (gy-0.5)*ts
        attempts = attempts + 1
        
        -- If we can't find an off-screen position after many attempts,
        -- just spawn at the edge of the screen
        if attempts >= maxAttempts then
            local side = math.random(4)
            local w, h = love.graphics.getWidth(), love.graphics.getHeight()
            local buffer = 150
            
            if side == 1 then -- top
                x = playerX + math.random(-w/2, w/2)
                y = playerY - h/2 - buffer
            elseif side == 2 then -- bottom
                x = playerX + math.random(-w/2, w/2)
                y = playerY + h/2 + buffer
            elseif side == 3 then -- left
                x = playerX - w/2 - buffer
                y = playerY + math.random(-h/2, h/2)
            else -- right
                x = playerX + w/2 + buffer
                y = playerY + math.random(-h/2, h/2)
            end
            
            -- Make sure it's walkable
            if dungeon:isWalkable(x, y) then
                break
            end
        end
    until dungeon:isWalkable(x, y) and isOffScreen(x, y, playerX, playerY)
    
    return x, y
end

-- Handle wave timers and spawning
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
            local typeDef = enemyTypes[math.random(#enemyTypes)]  -- pick random type
            local e = EnemyModule:new(0, 0, typeDef.hp, typeDef.speed, typeDef.color, typeDef.type)
            
            if e then  -- Safety check
                e:setDungeon(self.dungeon)
                e:setTarget(self.player)

                -- Spawn on a random walkable tile OFF-SCREEN
                local x, y = randomOffScreenPosition(self.dungeon, self.player.x, self.player.y)
                e.x, e.y = x, y

                table.insert(self.enemies, e)
            end
            
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