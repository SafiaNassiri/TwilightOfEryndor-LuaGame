local Player = {}
Player.__index = Player

local Audio = require("audio")

function Player:new(x, y, size)
    local p = {
        x = x, y = y,                       -- Player position
        size = size or 16,                  -- Width/height of player
        speed = 150,                        -- Movement speed
        hp = 100, maxHp = 100,              -- Health
        dungeon = nil,                      -- Reference to dungeon for collision
        attackCooldown = 0,                 -- Timer until next attack
        attackDelay = 0.3,                  -- Delay between attacks
        projectiles = {},                   -- Active projectiles fired by player
        hitTimer = 0, hitDuration = 0.1,    -- Flash effect duration after taking damage

        -- Stretch animation for movement/breathing
        stretchTimer = 0,
        stretchSpeed = 12,
        walkStretchAmount = 0.3,
        breatheStretchAmount = 0.1,
        isMoving = false
    }
    setmetatable(p, Player)
    return p
end

-- Set reference to dungeon (for collision detection)
function Player:setDungeon(d)
    self.dungeon = d
end

-- Update player each frame
function Player:update(dt, enemies)
    local dx, dy = 0, 0

    -- Movement input (WASD + arrow keys)
    if love.keyboard.isDown("w", "up") then dy = dy - 1 end
    if love.keyboard.isDown("s", "down") then dy = dy + 1 end
    if love.keyboard.isDown("a", "left") then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end

    -- Normalize diagonal movement
    local len = math.sqrt(dx*dx + dy*dy)
    self.isMoving = len > 0
    if self.isMoving then
        dx = dx / len * self.speed * dt
        dy = dy / len * self.speed * dt
    end

    -- Check all corners before moving X
    if self.dungeon:isWalkable(self.x + dx - self.size/2, self.y - self.size/2) and
       self.dungeon:isWalkable(self.x + dx + self.size/2, self.y - self.size/2) and
       self.dungeon:isWalkable(self.x + dx - self.size/2, self.y + self.size/2) and
       self.dungeon:isWalkable(self.x + dx + self.size/2, self.y + self.size/2) then
        self.x = self.x + dx
    end

    -- Check all corners before moving Y
    if self.dungeon:isWalkable(self.x - self.size/2, self.y + dy - self.size/2) and
       self.dungeon:isWalkable(self.x + self.size/2, self.y + dy - self.size/2) and
       self.dungeon:isWalkable(self.x - self.size/2, self.y + dy + self.size/2) and
       self.dungeon:isWalkable(self.x + self.size/2, self.y + dy + self.size/2) then
        self.y = self.y + dy
    end

    -- Update stretch animation timer
    self.stretchTimer = self.stretchTimer + dt * self.stretchSpeed

    -- Update attack cooldown
    if self.attackCooldown > 0 then
        self.attackCooldown = self.attackCooldown - dt
    end

    -- Update projectiles
    for i = #self.projectiles, 1, -1 do
        local p = self.projectiles[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt

        local remove = false

        -- Remove if hits wall
        if not self.dungeon:isWalkable(p.x, p.y) then remove = true end

        -- Check collision with enemies
        if enemies then
            for _, e in ipairs(enemies) do
                if e.hp > 0 and math.abs(p.x - e.x) < (p.size + e.size)/2 and
                   math.abs(p.y - e.y) < (p.size + e.size)/2 then
                    e.hp = e.hp - 20    -- Deal damage
                    remove = true       -- Remove projectile on hit
                end
            end
        end

        if remove then table.remove(self.projectiles, i) end
    end

    -- Update hit timer (for flash effect)
    if self.hitTimer > 0 then
        self.hitTimer = self.hitTimer - dt
    end
end

-- Fire projectile towards mouse/world coordinates
function Player:attack(mx, my)
    if self.attackCooldown <= 0 then
        local dirX = mx - self.x
        local dirY = my - self.y
        local len = math.sqrt(dirX*dirX + dirY*dirY)
        if len == 0 then return end
        dirX = dirX / len
        dirY = dirY / len

        -- Add projectile to list
        table.insert(self.projectiles, {
            x = self.x,
            y = self.y,
            dx = dirX * 400,  -- speed
            dy = dirY * 400,
            size = 4
        })

        self.attackCooldown = self.attackDelay
        Audio.play("attack_player")
    end
end

-- Draw player, projectiles, and health bar
function Player:draw()
    local scaleX, scaleY = 1, 1

    if self.isMoving then
        -- Stretch animation for movement
        local stretchFactor = math.sin(self.stretchTimer) * self.walkStretchAmount
        scaleY = 1 + stretchFactor
        scaleX = 1 - stretchFactor * 0.5
    else
        -- Breathing animation
        local breatheFactor = math.sin(self.stretchTimer * 0.5) * self.breatheStretchAmount
        scaleX = 1 + breatheFactor
        scaleY = 1 - breatheFactor * 0.3
    end

    local drawWidth = self.size * scaleX
    local drawHeight = self.size * scaleY

    -- Flash red when hit
    if self.hitTimer > 0 then
        love.graphics.setColor(0.706, 0.322, 0.322)  -- red
    else
        love.graphics.setColor(0.898, 0.808, 0.706)  -- tan
    end

    -- Draw player rectangle
    love.graphics.rectangle("fill", self.x - drawWidth/2, self.y - drawHeight/2, drawWidth, drawHeight)

    -- Draw projectiles
    love.graphics.setColor(0.408, 0.761, 0.827) -- cyan
    for _, p in ipairs(self.projectiles) do
        love.graphics.rectangle("fill", p.x - p.size/2, p.y - p.size/2, p.size, p.size)
    end

    -- Draw health bar above player
    local barW, barH = 40, 6
    -- Background
    love.graphics.setColor(0.129, 0.129, 0.137)  -- black
    love.graphics.rectangle("fill", self.x - barW/2, self.y - self.size/2 - 10, barW, barH)
    -- Health fill
    love.graphics.setColor(0.706, 0.322, 0.322)  -- red
    love.graphics.rectangle("fill", self.x - barW/2, self.y - self.size/2 - 10, barW * (self.hp/self.maxHp), barH)
end

-- Take damage and trigger hit effect
function Player:damage(amount)
    if self.hitTimer <= 0 then
        self.hp = self.hp - amount
        self.hitTimer = self.hitDuration
        Audio.play("player_hurt")
    end
end

-- Stub for compatibility (pickups handled in main.lua)
function Player:pickupItems() end

return Player
