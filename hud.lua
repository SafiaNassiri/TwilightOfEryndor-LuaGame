local HUD = {}
HUD.__index = HUD

function HUD:new()
    local h = {
        kills = 0,
        timer = 0,
        shards = 0  -- Track shards
    }
    setmetatable(h, HUD)
    return h
end

function HUD:update(dt)
    self.timer = self.timer + dt
end

function HUD:addKill()
    self.kills = self.kills + 1
end

function HUD:setShards(count)
    self.shards = count
end

function HUD:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))

    -- Kill count
    love.graphics.print("Kills: " .. self.kills, 10, 10)

    -- Timer
    local minutes = math.floor(self.timer / 60)
    local seconds = math.floor(self.timer % 60)
    love.graphics.print(string.format("Time: %02d:%02d", minutes, seconds), 10, 30)

    -- Shard counter (purple!)
    love.graphics.setColor(0.6, 0.2, 1)
    love.graphics.print("Shards: " .. self.shards, 10, 50)
    
    love.graphics.setColor(1, 1, 1)
end

return HUD