local Camera = {}
Camera.__index = Camera

function Camera:new(x, y, scale)
    local cam = {
        x = x or 0,
        y = y or 0,
        scale = scale or 1,
        smooth = 0.1,
        bounds = nil
    }
    setmetatable(cam, Camera)
    return cam
end

function Camera:update(tx, ty)
    self.x = self.x + (tx - self.x) * self.smooth
    self.y = self.y + (ty - self.y) * self.smooth
end

function Camera:attach()
    love.graphics.push()
    love.graphics.translate(-self.x + love.graphics.getWidth()/2,
                            -self.y + love.graphics.getHeight()/2)
end

function Camera:detach()
    love.graphics.pop()
end

return Camera
