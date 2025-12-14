local Enemy = {}
local Items = require("items")
local Audio = require("audio")
Enemy.__index = Enemy

-- Checks whether an enemy is within the camera view
local function isOnScreen(x, y, cam)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    return x > cam.x - w/2 and x < cam.x + w/2 and
           y > cam.y - h/2 and y < cam.y + h/2
end

-- Ensures the ENTIRE enemy square can move to a position
local function canMoveTo(self, x, y)
    local half = self.size / 2
    return self.dungeon:isWalkable(x - half, y - half) and
           self.dungeon:isWalkable(x + half, y - half) and
           self.dungeon:isWalkable(x - half, y + half) and
           self.dungeon:isWalkable(x + half, y + half)
end

function Enemy:new(x, y, hp, speed, color, type, patrolPath)
    -- Different enemy types feel heavier/lighter via size
    local sizeMap = {
        tank = 24,      -- biggest
        melee = 18,     -- slightly bigger than player
        ranged = 14     -- slightly smaller than player
    }
    
    local e = {
        x = x or 0,
        y = y or 0,
        size = sizeMap[type] or 16,
        hp = hp or 30,
        maxHp = hp or 30,
        speed = speed or 80,

        dungeon = nil,  -- reference to map for collision & LOS
        target = nil,   -- the player

        type = type or "melee",
        color = color or {1,0,0},

        patrolPath = patrolPath or {},
        patrolIndex = 1,

        moveDir = {x=0, y=0}, -- direction vector for animation
        chasing = false,

        attackCooldown = 1.5,   -- prevents constant attacks
        attackTelegraph = 0,    -- visual warning before attacking
        telegraphDuration = 0.5,
        telegraphX = 0,
        telegraphY = 0,

        projectiles = {},   -- used by ranged enemies

        -- Stretch animation
        stretchTimer = 0,
        stretchSpeed = 12,
        walkStretchAmount = 0.25,
        breatheStretchAmount = 0.12,
        isMoving = false,
        
        -- Death animation
        isDying = false,
        deathTimer = 0,
        deathDuration = 0.6,
        deathParticles = {}
    }
    setmetatable(e, Enemy)
    return e
end

function Enemy:setDungeon(d) self.dungeon = d end
function Enemy:setTarget(p) self.target = p end

-- Chase player if visible, else patrol
function Enemy:update(dt)
    -- If dying play death animation
    if self.isDying then
        self.deathTimer = self.deathTimer + dt
        
        -- Move and fade death particles outward
        for i = #self.deathParticles, 1, -1 do
            local p = self.deathParticles[i]
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.life = p.life - dt
            p.alpha = p.life / 0.6
            
            if p.life <= 0 then
                table.remove(self.deathParticles, i)
            end
        end
        
        return
    end
    
    -- If HP just hit zero, START death animation
    if self.hp <= 0 then
        self:startDeathAnimation()
        return
    end

    local half = self.size / 2

    -- Enemy can only chase if it has line-of-sight to the player
    local chasing = false
    if self.target then
        chasing = self.dungeon:lineOfSight(self.x, self.y, self.target.x, self.target.y)
    end

    self.isMoving = false

    if chasing then
        self.chasing = true

        -- Vector toward the player
        local dx, dy = self.target.x - self.x, self.target.y - self.y
        local dist = math.sqrt(dx*dx + dy*dy)

        -- Different enemy types stop at different distances
        local stopDist = (self.type=="melee" and self.size + self.target.size + 8)
                       or (self.type=="tank" and self.size + self.target.size + 8)
                       or 50
        
        -- Only move if outside attack range
        if dist > stopDist then
            local nx, ny = dx/dist, dy/dist -- normalized direction

            -- Try X and Y movement separately to allow sliding
            local nextX, nextY = self.x + nx*self.speed*dt, self.y + ny*self.speed*dt

            if canMoveTo(self, nextX, self.y) then 
                self.x = nextX
                self.isMoving = true
            end
            if canMoveTo(self, self.x, nextY) then 
                self.y = nextY
                self.isMoving = true
            end
            self.moveDir = {x=nx, y=ny}
        else
            -- Stop moving when in attack range
            self.moveDir = {x=0, y=0}
        end
    else
        -- If player is not visible, wander randomly
        self.chasing = false

        -- Generate a patrol target if none exists
        if #self.patrolPath == 0 then
            local ts = self.dungeon.tileSize or 32
            local rx = math.random(1, self.dungeon.gridW) * ts
            local ry = math.random(1, self.dungeon.gridH) * ts
            table.insert(self.patrolPath, {x=rx, y=ry})
        end

        local target = self.patrolPath[self.patrolIndex]
        local dx, dy = target.x - self.x, target.y - self.y
        local dist = math.sqrt(dx*dx + dy*dy)

        if dist < 4 then
            -- Pick a new random patrol point once reached
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
                self.isMoving = true
            end
            if canMoveTo(self, self.x, nextY) then
                self.y = nextY
                moved = true
                self.isMoving = true
            end

            -- If blocked by walls, reroll patrol target
            if not moved then
                local ts = self.dungeon.tileSize or 32
                local rx = math.random(1, self.dungeon.gridW) * ts
                local ry = math.random(1, self.dungeon.gridH) * ts
                self.patrolPath[self.patrolIndex] = {x=rx, y=ry}
            end

            self.moveDir = {x=nx, y=ny}
        end
    end

     -- Drives animation
    self.stretchTimer = self.stretchTimer + dt * self.stretchSpeed
end

-- DEATH ANIMATION
function Enemy:startDeathAnimation()
    self.isDying = true
    self.deathTimer = 0
    
    local numParticles = 8
    for i = 1, numParticles do
        local angle = (i / numParticles) * math.pi * 2
        local speed = 60 + math.random() * 40
        table.insert(self.deathParticles, {
            x = self.x,
            y = self.y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = self.size / 3 + math.random() * 3,
            life = 0.6,
            alpha = 1
        })
    end
end

-- ATTACK
function Enemy:attack(dt, cam)
    if self.hp <= 0 or not self.target or self.isDying then return end
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
                    Audio.play("attack_enemy")  -- PLAY ATTACK SOUND
                end
            elseif self.type=="ranged" and hasLOS then
                local dx, dy = self.telegraphX - self.x, self.telegraphY - self.y
                local len = math.sqrt(dx*dx + dy*dy)
                if len > 0 then dx, dy = dx/len*220, dy/len*220 end
                table.insert(self.projectiles, {x=self.x, y=self.y, dx=dx, dy=dy, size=5})
                Audio.play("attack_enemy")  -- PLAY ATTACK SOUND
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

-- DRAW
function Enemy:draw()
    if self.isDying then
        for _, p in ipairs(self.deathParticles) do
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], p.alpha)
            love.graphics.rectangle("fill", p.x - p.size/2, p.y - p.size/2, p.size, p.size)
        end
        return
    end
    
    if self.hp <= 0 then return end

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

    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4] or 1)
    love.graphics.rectangle("fill", 
        self.x - drawWidth/2, 
        self.y - drawHeight/2, 
        drawWidth, 
        drawHeight)

    if self.attackTelegraph > 0 then
        -- Make color lighter by multiplying RGB by 1.5 and capping at 1.0
        local lightR = math.min(self.color[1] * 1.5, 1.0)
        local lightG = math.min(self.color[2] * 1.5, 1.0)
        local lightB = math.min(self.color[3] * 1.5, 1.0)
        
        if self.type=="melee" then
            love.graphics.setColor(lightR, lightG, lightB, 0.6)
            local angle = math.atan2(self.target.y - self.y, self.target.x - self.x)
            local radius = self.size + (self.target and self.target.size or 0) + 6
            love.graphics.arc("fill", self.x, self.y, radius, angle - 0.6, angle + 0.6)
        elseif self.type=="tank" then
            love.graphics.setColor(lightR, lightG, lightB, 0.5)
            love.graphics.circle("fill", self.x, self.y, self.size*3)
        elseif self.type=="ranged" then
            love.graphics.setColor(lightR, lightG, lightB, 0.6)
            love.graphics.circle("fill", self.telegraphX, self.telegraphY, 14)
        end
    end

    if self.type=="ranged" then
        local lightR = math.min(self.color[1] * 1.3, 1.0)
        local lightG = math.min(self.color[2] * 1.3, 1.0)
        local lightB = math.min(self.color[3] * 1.3, 1.0)
        love.graphics.setColor(lightR, lightG, lightB)
        for _, p in ipairs(self.projectiles) do
            love.graphics.rectangle("fill", p.x-p.size/2, p.y-p.size/2, p.size, p.size)
        end
    end
end

-- SPAWN OFF-SCREEN
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

return Enemy