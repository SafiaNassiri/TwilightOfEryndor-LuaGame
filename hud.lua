local HUD = {}
HUD.__index = HUD

function HUD:new()
    local h = {
        kills = 0,      -- total number of enemies defeated
        timer = 0,      -- total number of enemies defeated
        shards = 0      -- total number of collected shards 
    }
    setmetatable(h, HUD)
    return h
end

function HUD:update(dt)
    -- Increase the timer every frame using delta time
    -- This keeps the timer frame-rate independent
    self.timer = self.timer + dt
end

function HUD:addKill()
    self.kills = self.kills + 1
end

function HUD:setShards(count)
    self.shards = count
end

function HUD:draw()
    love.graphics.setColor(0.949, 0.941, 0.898)  -- #f2f0e5 cream text
    love.graphics.setFont(love.graphics.newFont(16))

    love.graphics.print("Kills: " .. self.kills, 10, 10)

    -- Convert elapsed seconds into minutes and seconds
    local minutes = math.floor(self.timer / 60)
    local seconds = math.floor(self.timer % 60)

    -- Display formatted time (MM:SS)
    love.graphics.print(string.format("Time: %02d:%02d", minutes, seconds), 10, 30)

    -- Change color for shard counter so it visually stands out
    love.graphics.setColor(0.812, 0.541, 0.796)  -- #cf8acb pink
    love.graphics.print("Shards: " .. self.shards, 10, 50)
    
    -- Reset draw color so it doesn’t affect other rendering
    love.graphics.setColor(1, 1, 1)
end

return HUD