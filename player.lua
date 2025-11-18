local Player = {}
Player.__index = Player

function Player:new(x, y)
    local p = {
        x = x,
        y = y,
        speed = 150
    }
    setmetatable(p, Player)
    return p
end

function Player:update(dt)
    if love.keyboard.isDown("w") then self.y = self.y - self.speed * dt end
    if love.keyboard.isDown("s") then self.y = self.y + self.speed * dt end
    if love.keyboard.isDown("a") then self.x = self.x - self.speed * dt end
    if love.keyboard.isDown("d") then self.x = self.x + self.speed * dt end
end

function Player:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x - 8, self.y - 8, 16, 16)
end

return Player
