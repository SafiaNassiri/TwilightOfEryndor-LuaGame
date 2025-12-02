local Enemy = {}
local Items = require("items")
Enemy.__index = Enemy

-- On-screen check
local function isOnScreen(x, y, cam)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    return x > cam.x - w/2 and x < cam.x + w/2 and
           y > cam.y - h/2 and y < cam.y + h/2
end

-- Check if the entire enemy square can move to (x, y)
local function canMoveTo(self, x, y)
    local half = self.size / 2
    return self.dungeon:isWalkable(x - half, y - half) and
           self.dungeon:isWalkable(x + half, y - half) and
           self.dungeon:isWalkable(x - half, y + half) and
           self.dungeon:isWalkable(x + half, y + half)
end

-- Constructor
function Enemy:new(x, y, hp, speed, color, type, patrolPath)
    local e = {
        x = x or 0,
        y = y or 0,
        size = 16,
        hp = hp or 30,
        speed = speed or 80,
        dungeon = nil,
        target = nil,
        type = type or "melee",
        color = color or {1,0,0},
        patrolPath = patrolPath or {},
        patrolIndex = 1,
        moveDir = {x=0, y=0},
        chasing = false,
        attackCooldown = 1.5,
        attackTelegraph = 0,
        telegraphDuration = 0.5,
        telegraphX = 0,
        telegraphY = 0,
        projectiles = {}
    }
    setmetatable(e, Enemy)
    return e
end

function Enemy:setDungeon(d) self.dungeon = d end
function Enemy:setTarget(p) self.target = p end

-------------------------------------------------------------------
-- MOVEMENT: chase player if visible, else patrol
-------------------------------------------------------------------
function Enemy:update(dt)
    if self.hp <= 0 then
        -- drop loot once
        if not self._lootDropped then
            self:dropLoot()
            self._lootDropped = true
        end
        return
    end

    local half = self.size / 2

    -- Check if chasing player
    local chasing = false
    if self.target then
        chasing = self.dungeon:lineOfSight(self.x, self.y, self.target.x, self.target.y)
    end

    if chasing then
        self.chasing = true
        local dx, dy = self.target.x - self.x, self.target.y - self.y
        local dist = math.sqrt(dx*dx + dy*dy)
        local stopDist = (self.type=="melee" and self.size + self.target.size + 8)
                       or (self.type=="tank" and self.size + self.target.size + 8)
                       or 50
        if dist > stopDist then
            local nx, ny = dx/dist, dy/dist
            local nextX, nextY = self.x + nx*self.speed*dt, self.y + ny*self.speed*dt
            if canMoveTo(self, nextX, self.y) then self.x = nextX end
            if canMoveTo(self, self.x, nextY) then self.y = nextY end
            self.moveDir = {x=nx, y=ny}
        else
            self.moveDir = {x=0, y=0}
        end
    else
        -- Patrol / wander
        self.chasing = false

        -- Ensure patrol path exists
        if #self.patrolPath == 0 then
            local ts = self.dungeon.tileSize or 32
            local rx = math.random(1, self.dungeon.gridW) * ts
            local ry = math.random(1, self.dungeon.gridH) * ts
            table.insert(self.patrolPath, {x=rx, y=ry})
        end

        -- Move toward current patrol target
        local target = self.patrolPath[self.patrolIndex]
        local dx, dy = target.x - self.x, target.y - self.y
        local dist = math.sqrt(dx*dx + dy*dy)

        if dist < 4 then
            -- Arrived at patrol point, pick a new random one
            local ts = self.dungeon.tileSize or 32
            local rx = math.random(1, self.dungeon.gridW) * ts
            local ry = math.random(1, self.dungeon.gridH) * ts
            self.patrolPath[self.patrolIndex] = {x=rx, y=ry}
        else
            local nx, ny = dx/dist, dy/dist
            local nextX, nextY = self.x + nx*self.speed*dt, self.y + ny*self.speed*dt
            local moved = false

            if canMoveTo(self, nextX, self.y) then
                self.x = nextX
                moved = true
            end
            if canMoveTo(self, self.x, nextY) then
                self.y = nextY
                moved = true
            end

            -- If hit wall, pick a new patrol target
            if not moved then
                local ts = self.dungeon.tileSize or 32
                local rx = math.random(1, self.dungeon.gridW) * ts
                local ry = math.random(1, self.dungeon.gridH) * ts
                self.patrolPath[self.patrolIndex] = {x=rx, y=ry}
            end

            self.moveDir = {x=nx, y=ny}
        end
    end
end

-------------------------------------------------------------------
-- ATTACK
-------------------------------------------------------------------
function Enemy:attack(dt, cam)
    if self.hp <= 0 or not self.target then return end
    if not isOnScreen(self.x, self.y, cam) or not self.chasing then return end

    local dx, dy = self.target.x - self.x, self.target.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    local hasLOS = self.dungeon:lineOfSight(self.x, self.y, self.target.x, self.target.y)
    local aggro = {melee=250, tank=280, ranged=350}
    local myAggro = aggro[self.type] or 120

    if self.type == "melee" then
        local baseTelegraph = 0.5
        self.telegraphDuration = baseTelegraph * (myAggro / 140)
    end

    self.attackCooldown = self.attackCooldown - dt
    if self.attackCooldown <= 0 and hasLOS and dist < myAggro then
        if self.type=="ranged" then
            self.telegraphX, self.telegraphY = self.target.x, self.target.y
        end
        self.attackTelegraph = self.telegraphDuration
        self.attackCooldown = 2
    end

    if self.attackTelegraph > 0 then
        self.attackTelegraph = self.attackTelegraph - dt
        if self.attackTelegraph <= 0 then
            if (self.type=="melee" or self.type=="tank") and hasLOS then
                local hitRadius = self.size*2 + (self.target.size or 0)
                local dx, dy = self.target.x - self.x, self.target.y - self.y
                local distToPlayer = math.sqrt(dx*dx + dy*dy)
                if distToPlayer < hitRadius then
                    self.target:damage(self.type=="melee" and 5 or 15)
                end
            elseif self.type=="ranged" and hasLOS then
                local dx, dy = self.telegraphX - self.x, self.telegraphY - self.y
                local len = math.sqrt(dx*dx + dy*dy)
                if len > 0 then dx, dy = dx/len*220, dy/len*220 end
                table.insert(self.projectiles, {x=self.x, y=self.y, dx=dx, dy=dy, size=5})
            end
        end
    end

    if self.type=="ranged" then
        for i=#self.projectiles,1,-1 do
            local p = self.projectiles[i]
            p.x, p.y = p.x + p.dx*dt, p.y + p.dy*dt
            if not self.dungeon:isWalkable(p.x, p.y) then
                table.remove(self.projectiles, i)
            elseif math.abs(p.x-self.target.x)<(p.size+self.target.size)/2 and
                   math.abs(p.y-self.target.y)<(p.size+self.target.size)/2 and
                   self.dungeon:lineOfSight(p.x,p.y,self.target.x,self.target.y) then
                self.target:damage(10)
                table.remove(self.projectiles, i)
            end
        end
    end
end

-------------------------------------------------------------------
-- DRAW
-------------------------------------------------------------------
function Enemy:draw()
    if self.hp <= 0 then return end

    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4] or 1)
    love.graphics.rectangle("fill", self.x-self.size/2, self.y-self.size/2, self.size, self.size)

    if self.attackTelegraph > 0 then
        if self.type=="melee" then
            love.graphics.setColor(1,0,0,0.5)
            local angle = math.atan2(self.target.y - self.y, self.target.x - self.x)
            local radius = self.size + (self.target and self.target.size or 0) + 6
            love.graphics.arc("fill", self.x, self.y, radius, angle - 0.6, angle + 0.6)
        elseif self.type=="tank" then
            love.graphics.setColor(1,0.5,0,0.5)
            love.graphics.circle("fill", self.x, self.y, self.size*3)
        elseif self.type=="ranged" then
            love.graphics.setColor(1,1,0,0.5)
            love.graphics.circle("fill", self.telegraphX, self.telegraphY, 14)
        end
    end

    if self.type=="ranged" then
        love.graphics.setColor(1,1,0)
        for _, p in ipairs(self.projectiles) do
            love.graphics.rectangle("fill", p.x-p.size/2, p.y-p.size/2, p.size, p.size)
        end
    end
end

-------------------------------------------------------------------
-- SPAWN OFF-SCREEN
-------------------------------------------------------------------
function Enemy:spawnAtEdge(playerX, playerY, mapWidth, mapHeight)
    local side = math.random(4)
    if side == 1 then
        self.x = math.random(0, mapWidth)
        self.y = 0
    elseif side == 2 then
        self.x = math.random(0, mapWidth)
        self.y = mapHeight
    elseif side == 3 then
        self.x = 0
        self.y = math.random(0, mapHeight)
    else
        self.x = mapWidth
        self.y = math.random(0, mapHeight)
    end
end

function Enemy:dropLoot()
    if not self.dungeon then return end
    if math.random() < 0.30 then  -- 30% drop rate
        local lootType = (math.random() < 0.8) and "health_potion" or "rare_shard"
        local item = Items:new(lootType, self.x, self.y)
        table.insert(self.dungeon.items, item)
    end
end

return Enemy;