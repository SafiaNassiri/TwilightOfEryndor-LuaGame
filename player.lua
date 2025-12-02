local Player = {}
Player.__index = Player

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
        hitDuration = 0.1
    }
    setmetatable(p, Player)
    return p
end

function Player:setDungeon(d)
    self.dungeon = d
end

function Player:update(dt, enemies)
    local dx, dy = 0, 0
    if love.keyboard.isDown("w") then dy = dy - 1 end
    if love.keyboard.isDown("s") then dy = dy + 1 end
    if love.keyboard.isDown("a") then dx = dx - 1 end
    if love.keyboard.isDown("d") then dx = dx + 1 end

    local len = math.sqrt(dx*dx + dy*dy)
    if len > 0 then
        dx = dx / len * self.speed * dt
        dy = dy / len * self.speed * dt
    end

    -- Move X with collision
    if self.dungeon:isWalkable(self.x + dx - self.size/2, self.y - self.size/2) and
       self.dungeon:isWalkable(self.x + dx + self.size/2, self.y - self.size/2) and
       self.dungeon:isWalkable(self.x + dx - self.size/2, self.y + self.size/2) and
       self.dungeon:isWalkable(self.x + dx + self.size/2, self.y + self.size/2)
    then
        self.x = self.x + dx
    end

    -- Move Y with collision
    if self.dungeon:isWalkable(self.x - self.size/2, self.y + dy - self.size/2) and
       self.dungeon:isWalkable(self.x + self.size/2, self.y + dy - self.size/2) and
       self.dungeon:isWalkable(self.x - self.size/2, self.y + dy + self.size/2) and
       self.dungeon:isWalkable(self.x + self.size/2, self.y + dy + self.size/2)
    then
        self.y = self.y + dy
    end

    -- Update attack cooldown
    if self.attackCooldown > 0 then
        self.attackCooldown = self.attackCooldown - dt
    end

    -- Update projectiles
    if self.projectiles then
        for i = #self.projectiles, 1, -1 do
            local p = self.projectiles[i]
            p.x = p.x + p.dx * dt
            p.y = p.y + p.dy * dt

            local remove = false

            -- Remove projectile if it hits a wall
            if not self.dungeon:isWalkable(p.x, p.y) then
                remove = true
            end

            -- Check collision with enemies
            if enemies then
                for _, e in ipairs(enemies) do
                    if math.abs(p.x - e.x) < (p.size + e.size)/2 and
                       math.abs(p.y - e.y) < (p.size + e.size)/2 then
                        e.hp = e.hp - 20
                        remove = true
                    end
                end
            end

            if remove then
                table.remove(self.projectiles, i)
            end
        end
    end

    -- Update hit timer
    if self.hitTimer > 0 then
        self.hitTimer = self.hitTimer - dt
    end

    -- Pickup any items
    self:pickupItems()

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
    end
end

function Player:draw()
    -- Draw player with flash if hit
    if self.hitTimer > 0 then
        love.graphics.setColor(1,0,0)  -- flash red
    else
        love.graphics.setColor(1,1,1)
    end
    love.graphics.rectangle("fill", self.x - self.size/2, self.y - self.size/2, self.size, self.size)

    -- Draw projectiles
    love.graphics.setColor(1,0.8,0)
    for _, p in ipairs(self.projectiles) do
        love.graphics.rectangle("fill", p.x - p.size/2, p.y - p.size/2, p.size, p.size)
    end

    -- Health bar
    local barW, barH = 40, 6
    love.graphics.setColor(0.4,0.4,0.4)
    love.graphics.rectangle("fill", self.x - barW/2, self.y - self.size/2 - 10, barW, barH)
    love.graphics.setColor(1,0,0)
    love.graphics.rectangle("fill", self.x - barW/2, self.y - self.size/2 - 10, barW * (self.hp/self.maxHp), barH)
    love.graphics.setColor(1,1,1)
end

-- Take damage with hit flash
function Player:damage(amount)
    if self.hitTimer <= 0 then      -- only take damage if not in invincibility
        self.hp = self.hp - amount
        self.hitTimer = self.hitDuration  -- trigger hit flash / i-frames
    end
end

function Player:pickupItems()
    if not self.dungeon or not self.dungeon.items then return end

    for _, item in ipairs(self.dungeon.items) do
        if not item.collected then
            if math.abs(self.x - item.x) < (item.size + self.size) and
               math.abs(self.y - item.y) < (item.size + self.size)
            then
                item.collected = true

                if item.type == "consumable" then
                    self.hp = math.min(self.maxHp, self.hp + item.amount)
                elseif item.type == "key" then
                    self.keys = (self.keys or 0) + 1
                elseif item.type == "rare" then
                    self.rareShards = (self.rareShards or 0) + 1
                end
            end
        end
    end
end

return Player