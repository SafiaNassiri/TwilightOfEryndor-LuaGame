local Camera = require("camera")
local Player = require("player")
local Dungeon = require("dungeon")
local Enemy = require("enemy")
local Spawner = require("spawner")

-- Define enemy types with their specific behavior types
local enemyTypes = {
    {speed = 80, hp = 30, color = {1,0,0}, type = "melee"},   -- normal melee
    {speed = 50, hp = 50, color = {1,0.5,0}, type = "tank"},  -- tank
    {speed = 120, hp = 20, color = {0,1,0}, type = "ranged"} -- fast ranged
}

-- Game state
local dungeon, player, enemies, camera
local isDead = false
local deathMessage = ""
local deathLore = {
    "You fell in the darkness... another soul lost.",
    "The dungeon claims the weak.",
    "Your blood stains the cold stone."
}

local upgrades = {}
local enemySpawnTimer = 0
local enemySpawnInterval = 5

function love.load()
    math.randomseed(os.time())

    dungeon = Dungeon:new({
        gridW = 50,
        gridH = 50,
        tileSize = 32,
        maxAttempts = 8,
        minFloorFraction = 0.28,
        pruneDeadEnds = true
    })

    local px, py = dungeon:getPlayerStart()
    player = Player:new(px, py, 16)
    player:setDungeon(dungeon)

    spawner = Spawner:new(dungeon, player)

    enemies = {}
    for i = 1, 3 do
        spawnEnemy()
    end

    camera = Camera:new(px, py)
    if dungeon.mapWidth and dungeon.mapHeight then
        camera:setBounds(0, 0, dungeon.mapWidth, dungeon.mapHeight)
    end

    upgrades = {}
end

function spawnEnemy()
    local f, ex, ey
    local camW, camH = love.graphics.getWidth(), love.graphics.getHeight()

    repeat
        local side = math.random(4)

        if side == 1 then
            ex = player.x + math.random(-camW/2, camW/2)
            ey = player.y - camH/2 - dungeon.tileSize
        elseif side == 2 then
            ex = player.x + math.random(-camW/2, camW/2)
            ey = player.y + camH/2 + dungeon.tileSize
        elseif side == 3 then
            ex = player.x - camW/2 - dungeon.tileSize
            ey = player.y + math.random(-camH/2, camH/2)
        else
            ex = player.x + camW/2 + dungeon.tileSize
            ey = player.y + math.random(-camH/2, camH/2)
        end

        f = nil
        for _, floor in ipairs(dungeon.floorList) do
            if math.abs(floor.x + dungeon.tileSize/2 - ex) < dungeon.tileSize/2 and
               math.abs(floor.y + dungeon.tileSize/2 - ey) < dungeon.tileSize/2 then
                f = floor
                break
            end
        end
    until f

    ex = f.x + dungeon.tileSize/2
    ey = f.y + dungeon.tileSize/2

    local typeDef = enemyTypes[math.random(#enemyTypes)]
    local e = Enemy:new(ex, ey, typeDef.hp, typeDef.speed, typeDef.color, typeDef.type)
    e:setDungeon(dungeon)
    e:setTarget(player)
    table.insert(enemies, e)
end

function spawnUpgrade(type)
    local f = dungeon.floorList[math.random(#dungeon.floorList)]
    table.insert(upgrades, {
        x = f.x + dungeon.tileSize/2,
        y = f.y + dungeon.tileSize/2,
        type = type,
        size = 12
    })
end

function love.update(dt)
    if not isDead then
        player:update(dt, enemies)

        -- Update enemies
        for i = #enemies, 1, -1 do
            local e = enemies[i]
            if e.hp <= 0 then
                table.remove(enemies, i)
            else
                e:update(dt)
                e:attack(dt, camera)
            end
        end

        -- Update upgrades
        for i = #upgrades, 1, -1 do
            local u = upgrades[i]
            if math.abs(player.x - u.x) < (player.size + u.size)/2 and
               math.abs(player.y - u.y) < (player.size + u.size)/2 then
                if u.type == "speed" then
                    player.speed = player.speed + 50
                elseif u.type == "heal" then
                    player.hp = math.min(player.maxHp, player.hp + 30)
                end
                table.remove(upgrades, i)
            end
        end

        -- Update spawner
        spawner:update(dt)

        -- Check death
        if player.hp <= 0 and not isDead then
            isDead = true
            deathMessage = deathLore[math.random(#deathLore)]
        end

        camera:update(player.x, player.y)
    else
        if love.keyboard.isDown("r") then
            love.event.quit("restart")
        end
    end
end

function love.draw()
    if not isDead then
        camera:attach()

        dungeon:draw()
        spawner:draw()

        for _, u in ipairs(upgrades) do
            if u.type == "speed" then
                love.graphics.setColor(0,1,0)
            elseif u.type == "heal" then
                love.graphics.setColor(0,0,1)
            end
            love.graphics.rectangle("fill", u.x - u.size/2, u.y - u.size/2, u.size, u.size)
        end

        for _, e in ipairs(enemies) do
            e:draw()
        end

        player:draw()

        camera:detach()
    else
        love.graphics.setColor(1,1,1)
        love.graphics.printf(deathMessage, 0, love.graphics.getHeight()/2 - 20, love.graphics.getWidth(), "center")
        love.graphics.printf("Press R to restart", 0, love.graphics.getHeight()/2 + 20, love.graphics.getWidth(), "center")
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and not isDead then
        local wx = x + camera.x - love.graphics.getWidth()/2
        local wy = y + camera.y - love.graphics.getHeight()/2
        player:attack(wx, wy)
    end
end
