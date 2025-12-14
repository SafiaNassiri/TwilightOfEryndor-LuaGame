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
local isVictory = false  -- New: victory state for 110 shards
local deathMessage = ""
local survivalTime = 0
local endingTitle = ""
local endingDescription = ""

local upgrades = {}
local pickupMessages = {}
local storyMessages = {}

-- Lore-based endings for every 10 shards
local endings = {
    [0] = {
        title = "The Forgotten Wanderer",
        desc = "You entered the ruins of Eryndor with hope, but left with nothing. The ancient halls consumed you like countless others before. The shards remained untouched, their secrets forever locked away from your grasp."
    },
    [1] = {
        title = "First Glimpse of the Past",
        desc = "Ten shards gleam in your memory. You touched the edge of Eryndor's power and felt its whispers. The ancient kingdom stirs, sensing a worthy seeker. Your journey was short, but you glimpsed what could be."
    },
    [2] = {
        title = "Keeper of Lost Memories",
        desc = "Twenty shards pulse with forgotten magic. The ruins recognize you now—a true explorer of the twilight. You've uncovered fragments of Eryndor's fall, when light and shadow tore the kingdom apart. The deeper mysteries call to you."
    },
    [3] = {
        title = "Heir to Twilight",
        desc = "Thirty shards sing ancient songs in your soul. You've walked the halls where kings once ruled, where mages wielded powers beyond mortal ken. The boundary between light and shadow grows thin around you. Eryndor marks you as one of its own."
    },
    [4] = {
        title = "The Shadow's Chosen",
        desc = "Forty shards burn with ethereal fire. The darkness of Eryndor no longer frightens you—it embraces you. You've seen the cataclysm that shattered this kingdom, the terrible price of ambition. Yet still you reach for more."
    },
    [5] = {
        title = "Twilight's Champion",
        desc = "Fifty shards resonate with your heartbeat. You are legend among the ruins. The spectral guardians bow as you pass, recognizing the bearer of Eryndor's essence. You stand at the threshold of understanding what destroyed this magnificent kingdom."
    },
    [6] = {
        title = "Master of Forgotten Arts",
        desc = "Sixty shards have woven themselves into your being. The ruins bend to your will now, revealing secrets sealed for millennia. You've mastered powers that brought Eryndor to its knees. Even in death, you transcend mortality."
    },
    [7] = {
        title = "The Eternal Seeker",
        desc = "Seventy shards blaze within you like stars. You've pierced the veil between life and death, between light and shadow. The ancient ones who built Eryndor would kneel before what you've become. Your name echoes through eternity."
    },
    [8] = {
        title = "Sovereign of Ruins",
        desc = "Eighty shards crown you ruler of desolation. Eryndor is yours—its power, its knowledge, its curse. You've climbed higher than any mortal dared, touched divinity itself. The ruins await your command, even as darkness claims you."
    },
    [9] = {
        title = "Remaker of Kingdoms",
        desc = "Ninety shards pulse with reality-warping power. You've gathered enough to rebuild what was lost, to resurrect Eryndor from ash. But such power demands sacrifice. You teeter on the edge of godhood and oblivion."
    },
    [10] = {
        title = "Eryndor Reborn",
        desc = "One hundred shards—the complete legacy of a fallen kingdom. You've achieved the impossible, claimed every fragment of Eryndor's shattered soul. Light and shadow merge within you. The twilight kingdom lives again... in you."
    },
    [11] = {
        title = "Beyond Twilight",
        desc = "You've claimed one hundred and ten shards—more than the kingdom ever held. You've transcended Eryndor itself, surpassed its creators. The ruins have nothing left to give. You are no longer bound by mortal flesh or ancient curses. The twilight is yours to command."
    }
}

local function getEnding(shardCount)
    local tier = math.floor(shardCount / 10)
    if tier > 11 then tier = 11 end
    return endings[tier]
end

local function formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

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
    
    survivalTime = 0
    player.rareShards = 0
    isDead = false
    isVictory = false
end

function love.update(dt)
    if not isDead and not isVictory then
        survivalTime = survivalTime + dt
        
        player:update(dt, spawner.enemies)
        spawner:update(dt)
        hud:update(dt)

        -- Check for ultimate victory (110+ shards)
        if player.rareShards >= 110 then
            isVictory = true
            local ending = getEnding(player.rareShards)
            endingTitle = ending.title
            endingDescription = ending.desc
            Audio.play("button")
        end

        for i=#pickupMessages,1,-1 do
            pickupMessages[i].timer = pickupMessages[i].timer - dt
            if pickupMessages[i].timer <= 0 then table.remove(pickupMessages,i) end
        end
        
        for i=#storyMessages,1,-1 do
            storyMessages[i].timer = storyMessages[i].timer - dt
            if storyMessages[i].timer <= 0 then table.remove(storyMessages,i) end
        end

        for i=#spawner.enemies,1,-1 do
            local e = spawner.enemies[i]
            if e.isDying and e.deathTimer >= e.deathDuration then
                Audio.play("enemy_death")
                hud:addKill()

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

        for i=#upgrades,1,-1 do
            local u = upgrades[i]
            if math.abs(player.x-u.x) < (player.size+u.size)/2 and
               math.abs(player.y-u.y) < (player.size+u.size)/2 then
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

        if player.hp <= 0 and not isDead then
            Audio.play("player_hurt")
            isDead = true
            local ending = getEnding(player.rareShards or 0)
            endingTitle = ending.title
            endingDescription = ending.desc
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
    if not isDead and not isVictory then
        camera:attach()
        dungeon:draw()
        spawner:draw()

        for _, u in ipairs(upgrades) do
            if u.color then love.graphics.setColor(u.color[1],u.color[2],u.color[3]) end
            love.graphics.circle("fill", u.x, u.y, u.size/2)
        end

        for _, e in ipairs(spawner.enemies) do e:draw() end
        player:draw()
        camera:detach()

        hud:draw()

        local startY = 20
        for i,msg in ipairs(pickupMessages) do
            love.graphics.setColor(1,1,0)
            love.graphics.printf(msg.text,0,startY+(i-1)*20,love.graphics.getWidth()-10,"right")
        end

        local startY = love.graphics.getHeight()-60
        for i,msg in ipairs(storyMessages) do
            love.graphics.setColor(0.8,0.8,1)
            love.graphics.printf(msg.text,20,startY-(i-1)*20,love.graphics.getWidth()-40,"left")
        end
        love.graphics.setColor(1,1,1)
    else
        -- Game over screen (death or victory)
        local centerY = love.graphics.getHeight() / 2
        
        -- Title color: gold for victory, white for death
        if isVictory then
            love.graphics.setColor(1, 0.9, 0.2)
        else
            love.graphics.setColor(1, 0.8, 0.3)
        end
        love.graphics.printf(endingTitle, 0, centerY - 100, love.graphics.getWidth(), "center")
        
        -- Description
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.printf(endingDescription, 50, centerY - 60, love.graphics.getWidth() - 100, "center")
        
        -- Stats
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Time Survived: " .. formatTime(survivalTime), 0, centerY + 40, love.graphics.getWidth(), "center")
        
        love.graphics.setColor(0.6, 0.2, 1)
        love.graphics.printf("Rare Shards Collected: " .. (player.rareShards or 0), 0, centerY + 65, love.graphics.getWidth(), "center")
        
        -- Special message for ultimate completion
        if isVictory then
            love.graphics.setColor(1, 1, 0.3)
            love.graphics.printf("★ ULTIMATE COMPLETION ★", 0, centerY + 95, love.graphics.getWidth(), "center")
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.printf("The ruins of Eryndor have nothing left to give.", 0, centerY + 120, love.graphics.getWidth(), "center")
        end
        
        -- Restart instruction
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("Press R to restart", 0, centerY + 150, love.graphics.getWidth(), "center")
    end
end

function love.mousepressed(x,y,button)
    if button==1 and not isDead and not isVictory then
        local wx = x + camera.x - love.graphics.getWidth()/2
        local wy = y + camera.y - love.graphics.getHeight()/2
        player:attack(wx,wy)
    end
end