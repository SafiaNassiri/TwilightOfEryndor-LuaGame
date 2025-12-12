local HUD = {}
HUD.__index = HUD

function HUD:new()
    local h = {
        kills = 0,
        timer = 0,       -- in seconds
    }
    setmetatable(h, HUD)
    return h
end

-- Call this every frame
function HUD:update(dt)
    self.timer = self.timer + dt
end

-- Call this when an enemy dies
function HUD:addKill()
    self.kills = self.kills + 1
end

-- Draw the HUD
-- pickupMessages = top-right notifications
-- storyMessages = bottom lore messages
function HUD:draw(pickupMessages, storyMessages)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))

    -- Kill count
    love.graphics.print("Kills: " .. self.kills, 10, 10)

    -- Timer in MM:SS
    local minutes = math.floor(self.timer / 60)
    local seconds = math.floor(self.timer % 60)
    local timeText = string.format("Time: %02d:%02d", minutes, seconds)
    love.graphics.print(timeText, 10, 30)

    -- Draw top-right pickup messages
    if pickupMessages then
        local startY = 20
        for i, msg in ipairs(pickupMessages) do
            love.graphics.setColor(1, 1, 0)
            love.graphics.printf(msg.text, 0, startY + (i-1)*20, love.graphics.getWidth()-10, "right")
        end
    end

    -- Draw bottom story messages
    if storyMessages then
        local startY = love.graphics.getHeight() - 60
        for i, msg in ipairs(storyMessages) do
            love.graphics.setColor(0.8, 0.8, 1)
            love.graphics.printf(msg.text, 20, startY - (i-1)*20, love.graphics.getWidth()-40, "left")
        end
    end

    love.graphics.setColor(1,1,1)
end

return HUD
