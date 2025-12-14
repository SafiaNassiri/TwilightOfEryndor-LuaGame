local Spawner = {}
Spawner.__index = Spawner

local EnemyModule = require("enemy")  -- enemy constructor / logic

-- Preset enemy stat templates
-- Each wave randomly chooses from these
local enemyTypes = {
    {speed = 90, hp = 50, color = {0.502, 0.286, 0.227}, type = "melee"},  -- #80493a dark brown
    {speed = 60, hp = 70, color = {0.416, 0.325, 0.431}, type = "tank"},   -- #6a536e mauve
    {speed = 120, hp = 35, color = {0.294, 0.502, 0.792}, type = "ranged"} -- #4b80ca bright blue
}

function Spawner:new(dungeon, player)
    local s = {
        dungeon = dungeon,      -- map reference
        player = player,        -- player reference for spawn positioning
        enemies = {},           -- currently active enemies

        wave = 0,               -- currently active enemies
        waveTimer = 3,          -- delay before first wave starts
        spawnInterval = 1,      -- delay between enemy spawns within a wave
        enemiesToSpawn = 0,     -- how many enemies remain to spawn this wave
        spawnTimer = 0          -- countdown until next enemy spawn
    }
    setmetatable(s, Spawner)
    return s
end

-- Determines if a position is outside the player's view
-- Used to prevent enemies from popping in on-screen
local function isOffScreen(x, y, playerX, playerY)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local buffer = 100  -- extra margin so spawns feel fair
    
    local minX = playerX - w/2 - buffer
    local maxX = playerX + w/2 + buffer
    local minY = playerY - h/2 - buffer
    local maxY = playerY + h/2 + buffer
    
    -- True if the position is outside the visible area
    return x < minX or x > maxX or y < minY or y > maxY
end

-- Finds a random walkable tile that is off-screen
-- Falls back to spawning at screen edges if necessary
local function randomOffScreenPosition(dungeon, playerX, playerY)
    local ts = dungeon.tileSize or 32
    local x, y
    local attempts = 0
    local maxAttempts = 100     -- to avoid infinite loops
    
    repeat
        -- Pick a random tile from the dungeon grid
        local gx = math.random(1, dungeon.gridW)
        local gy = math.random(1, dungeon.gridH)
        x, y = (gx-0.5)*ts, (gy-0.5)*ts
        attempts = attempts + 1
        
        -- If we fail too many times, force a spawn at screen edges
        if attempts >= maxAttempts then
            local side = math.random(4)
            local w, h = love.graphics.getWidth(), love.graphics.getHeight()
            local buffer = 150
            
            -- Choose a random edge around the player
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
            
            -- Only accept this position if it’s walkable
            if dungeon:isWalkable(x, y) then
                break
            end
        end
    until dungeon:isWalkable(x, y) and isOffScreen(x, y, playerX, playerY)
    
    return x, y
end

-- Handles wave progression and enemy spawning
function Spawner:update(dt)
    -- Countdown until the next wave starts
    self.waveTimer = self.waveTimer - dt
    if self.waveTimer <= 0 then
        self.wave = self.wave + 1

        -- Increase difficulty by spawning more enemies each wave
        self.enemiesToSpawn = 5 + self.wave * 2

        self.spawnTimer = 0     -- spawn first enemy immediately
        self.waveTimer = 15     -- time until the next wave
    end

    -- Spawn enemies gradually
    if self.enemiesToSpawn > 0 then
        self.spawnTimer = self.spawnTimer - dt
        if self.spawnTimer <= 0 then
            -- Choose a random enemy template
            local typeDef = enemyTypes[math.random(#enemyTypes)]

            -- Create enemy using selected stats
            local e = EnemyModule:new(0, 0, typeDef.hp, typeDef.speed, typeDef.color, typeDef.type)
            
            if e then  -- Give enemy access to dungeon + player
                e:setDungeon(self.dungeon)
                e:setTarget(self.player)

                -- Place enemy off-screen on a valid tile
                local x, y = randomOffScreenPosition(self.dungeon, self.player.x, self.player.y)
                e.x, e.y = x, y

                -- Add enemy to active list
                table.insert(self.enemies, e)
            end
            
            self.enemiesToSpawn = self.enemiesToSpawn - 1
            self.spawnTimer = self.spawnInterval
        end
    end
end

function Spawner:draw()
    -- Draw all active enemies
    for _, e in ipairs(self.enemies) do
        e:draw()
    end
end

return Spawner