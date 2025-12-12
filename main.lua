local Camera = require("camera")
local Player = require("player")
local Dungeon = require("dungeon")
local Enemy = require("enemy")
local Spawner = require("spawner")
local HUD = require("hud")
local hud = HUD:new()

local Audio = require("audio")
local Items = require("items")

-- Game state
local dungeon, player, spawner, camera
local isDead = false
local deathMessage = ""
local deathLore = {
    "You fell in the darkness... another soul lost.",
    "The dungeon claims the weak.",
    "Your blood stains the cold stone."
}

local upgrades = {}
local pickupMessages = {}    -- Health/Mana notifications
local storyMessages = {}     -- Rare shard story

-- Spawn upgrades
local function spawnUpgrade(type, x, y)
    local itemData = Items.database[type]
    if itemData then
        table.insert(upgrades, {
            x = x, y = y,
            type = type,
            size = itemData.size,
            color = itemData.color,
            amount = itemData.amount,
            speedIncrease = itemData.speedIncrease,
            story = itemData.story,
            pickupMessage = itemData.pickupMessage
        })
    end
end

-- Message helpers
local function addPickupMessage(text)
    table.insert(pickupMessages, {text=text, timer=2})
end

local function addStoryMessage(text)
    table.insert(storyMessages, {text=text, timer=5})
end

function love.load()
    math.randomseed(os.time())
    Audio.load()
    Audio.playMusic("bg")

    dungeon = Dungeon:new({gridW=50, gridH=50, tileSize=32, maxAttempts=8, minFloorFraction=0.28, pruneDeadEnds=true})
    local px, py = dungeon:getPlayerStart()
    player = Player:new(px, py, 16)
    player:setDungeon(dungeon)

    spawner = Spawner:new(dungeon, player)
    camera = Camera:new(px, py)
    if dungeon.mapWidth and dungeon.mapHeight then
        camera:setBounds(0, 0, dungeon.mapWidth, dungeon.mapHeight)
    end
end

function love.update(dt)
    if not isDead then
        player:update(dt, spawner.enemies)
        spawner:update(dt)
        hud:update(dt)

        -- Update pickup message timers
        for i=#pickupMessages,1,-1 do
            pickupMessages[i].timer = pickupMessages[i].timer - dt
            if pickupMessages[i].timer <= 0 then table.remove(pickupMessages,i) end
        end
        -- Update story messages
        for i=#storyMessages,1,-1 do
            storyMessages[i].timer = storyMessages[i].timer - dt
            if storyMessages[i].timer <= 0 then table.remove(storyMessages,i) end
        end

        -- Handle enemies
        for i=#spawner.enemies,1,-1 do
            local e = spawner.enemies[i]
            if e.isDying and e.deathTimer >= e.deathDuration then
                Audio.play("enemy_death")
                hud:addKill()

                -- Loot drop
                local baseChance = 0.5
                local perWaveBonus = 0.05
                local dropChance = math.min(0.95, baseChance + spawner.wave * perWaveBonus)
                if math.random() < dropChance then
                    local roll = math.random()
                    local lootType
                    if roll < 0.45 then lootType = "health_potion"
                    elseif roll < 0.75 then lootType = "mana_potion"
                    else lootType = "rare_shard"
                    end
                    spawnUpgrade(lootType, e.x, e.y)
                end

                table.remove(spawner.enemies,i)
            else
                e:update(dt)
                e:attack(dt,camera)
            end
        end

        -- Handle upgrades
        for i=#upgrades,1,-1 do
            local u = upgrades[i]
            if math.abs(player.x-u.x) < (player.size+u.size)/2 and
               math.abs(player.y-u.y) < (player.size+u.size)/2 then
                -- Apply effects
                if u.type=="health_potion" then
                    player.hp = math.min(player.maxHp, player.hp + (u.amount or 25))
                    addPickupMessage(u.pickupMessage or "+HP restored")
                elseif u.type=="mana_potion" then
                    player.speed = player.speed + (u.speedIncrease or 50)
                    addPickupMessage(u.pickupMessage or "Mana pool increased")
                elseif u.type=="rare_shard" then
                    player.rareShards = (player.rareShards or 0) + 1
                    player.maxHp = player.maxHp + 10
                    player.hp = player.hp + 10
                    addPickupMessage(u.pickupMessage or "Shard collected!")
                    if u.story then addStoryMessage(u.story) end
                end
                table.remove(upgrades,i)
            end
        end

        -- Death check
        if player.hp <= 0 and not isDead then
            Audio.play("player_hurt")
            isDead = true
            deathMessage = deathLore[math.random(#deathLore)]
        end

        camera:update(player.x,player.y)
    else
        if love.keyboard.isDown("r") then
            Audio.play("button")
            love.event.quit("restart")
        end
    end
end

function love.draw()
    if not isDead then
        camera:attach()
        dungeon:draw()
        spawner:draw()

        -- Draw upgrades
        for _, u in ipairs(upgrades) do
            if u.color then love.graphics.setColor(u.color[1],u.color[2],u.color[3]) end
            love.graphics.circle("fill", u.x, u.y, u.size/2)
        end

        for _, e in ipairs(spawner.enemies) do e:draw() end
        player:draw()
        camera:detach()

        hud:draw()

        -- Pickup messages (top-right)
        local startY = 20
        for i,msg in ipairs(pickupMessages) do
            love.graphics.setColor(1,1,0)
            love.graphics.printf(msg.text,0,startY+(i-1)*20,love.graphics.getWidth()-10,"right")
        end

        -- Story messages (bottom)
        local startY = love.graphics.getHeight()-60
        for i,msg in ipairs(storyMessages) do
            love.graphics.setColor(0.8,0.8,1)
            love.graphics.printf(msg.text,20,startY-(i-1)*20,love.graphics.getWidth()-40,"left")
        end
        love.graphics.setColor(1,1,1)
    else
        love.graphics.setColor(1,1,1)
        love.graphics.printf(deathMessage,0,love.graphics.getHeight()/2-20,love.graphics.getWidth(),"center")
        love.graphics.printf("Press R to restart",0,love.graphics.getHeight()/2+20,love.graphics.getWidth(),"center")
    end
end

function love.mousepressed(x,y,button)
    if button==1 and not isDead then
        local wx = x + camera.x - love.graphics.getWidth()/2
        local wy = y + camera.y - love.graphics.getHeight()/2
        player:attack(wx,wy)
    end
end
