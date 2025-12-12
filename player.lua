local Player = {}
Player.__index = Player

-- Constructor
function Player:new(x, y, size)
    local p = {
        x = x,
        y = y,
        size = size or 16,
        speed = 150,
        hp = 100,
        maxHp = 100,
        dungeon = nil,
        attackCooldown = 0,
        attackDelay = 0.3,
        projectiles = {},
        hitTimer = 0,
        hitDuration = 0.1,
        -- Stretch animation
        stretchTimer = 0,
        stretchSpeed = 12,
        walkStretchAmount = 0.3,
        breatheStretchAmount = 0.1,
        isMoving = false
    }
    setmetatable(p, Player)
    return p
end

-- Set dungeon reference
function Player:setDungeon(d)
    self.dungeon = d
end

-- Update player state each frame
function Player:update(dt, enemies)
    local dx, dy = 0, 0

    -- Movement: WASD + Arrow Keys
    if love.keyboard.isDown("w", "up") then dy = dy - 1 end
    if love.keyboard.isDown("s", "down") then dy = dy + 1 end
    if love.keyboard.isDown("a", "left") then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end

    local len = math.sqrt(dx*dx + dy*dy)
    self.isMoving = len > 0

    if self.isMoving then
        dx = dx / len * self.speed * dt
        dy = dy / len * self.speed * dt
    end

    -- Collision movement
    if self.dungeon:isWalkable(self.x + dx - self.size/2, self.y - self.size/2) and
       self.dungeon:isWalkable(self.x + dx + self.size/2, self.y - self.size/2) and
       self.dungeon:isWalkable(self.x + dx - self.size/2, self.y + self.size/2) and
       self.dungeon:isWalkable(self.x + dx + self.size/2, self.y + self.size/2) then
        self.x = self.x + dx
    end

    if self.dungeon:isWalkable(self.x - self.size/2, self.y + dy - self.size/2) and
       self.dungeon:isWalkable(self.x + self.size/2, self.y + dy - self.size/2) and
       self.dungeon:isWalkable(self.x - self.size/2, self.y + dy + self.size/2) and
       self.dungeon:isWalkable(self.x + self.size/2, self.y + dy + self.size/2) then
        self.y = self.y + dy
    end

    -- Update stretch animation
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
        if not self.dungeon:isWalkable(p.x, p.y) then remove = true end

        if enemies then
            for _, e in ipairs(enemies) do
                if e.hp > 0 and math.abs(p.x - e.x) < (p.size + e.size)/2 and
                   math.abs(p.y - e.y) < (p.size + e.size)/2 then
                    e.hp = e.hp - 20
                    remove = true
                end
            end
        end

        if remove then table.remove(self.projectiles, i) end
    end

    -- Update hit timer
    if self.hitTimer > 0 then
        self.hitTimer = self.hitTimer - dt
    end
end

-- Fire projectile
function Player:attack(mx, my)
    if self.attackCooldown <= 0 then
        local dirX = mx - self.x
        local dirY = my - self.y
        local len = math.sqrt(dirX*dirX + dirY*dirY)
        if len == 0 then return end
        dirX = dirX / len
        dirY = dirY / len

        table.insert(self.projectiles, {
            x = self.x,
            y = self.y,
            dx = dirX * 400,
            dy = dirY * 400,
            size = 4
        })

        self.attackCooldown = self.attackDelay

        if Audio then Audio.play("attack_player") end
    end
end

-- Draw player and projectiles
function Player:draw()
    local scaleX, scaleY = 1, 1
    if self.isMoving then
        local stretchFactor = math.sin(self.stretchTimer) * self.walkStretchAmount
        scaleY = 1 + stretchFactor
        scaleX = 1 - stretchFactor * 0.5
    else
        local breatheFactor = math.sin(self.stretchTimer * 0.5) * self.breatheStretchAmount
        scaleX = 1 + breatheFactor
        scaleY = 1 - breatheFactor * 0.3
    end

    local drawWidth = self.size * scaleX
    local drawHeight = self.size * scaleY

    if self.hitTimer > 0 then
        love.graphics.setColor(1,0,0)
    else
        love.graphics.setColor(1,1,1)
    end

    love.graphics.rectangle("fill", self.x - drawWidth/2, self.y - drawHeight/2, drawWidth, drawHeight)

    -- Draw projectiles
    love.graphics.setColor(1,0.8,0)
    for _, p in ipairs(self.projectiles) do
        love.graphics.rectangle("fill", p.x - p.size/2, p.y - p.size/2, p.size, p.size)
    end

    -- Draw health bar
    local barW, barH = 40, 6
    love.graphics.setColor(0.4,0.4,0.4)
    love.graphics.rectangle("fill", self.x - barW/2, self.y - self.size/2 - 10, barW, barH)
    love.graphics.setColor(1,0,0)
    love.graphics.rectangle("fill", self.x - barW/2, self.y - self.size/2 - 10, barW * (self.hp/self.maxHp), barH)
    love.graphics.setColor(1,1,1)
end

-- Take damage
function Player:damage(amount)
    if self.hitTimer <= 0 then
        self.hp = self.hp - amount
        self.hitTimer = self.hitDuration
        if Audio then Audio.play("player_hurt") end
    end
end

-- Stub method for compatibility
function Player:pickupItems()
    -- No-op: pickup handled in main.lua upgrades system
end

return Player
