local Camera = {}
Camera.__index = Camera

local function clamp(x, min, max)
    return x < min and min or (x > max and max or x)
end

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

function Camera:setBounds(x, y, w, h)
    self.bounds = { x = x, y = y, w = w, h = h }
end

function Camera:update(tx, ty)
    -- Smooth movement logic
    self.x = self.x + (tx - self.x) * self.smooth
    self.y = self.y + (ty - self.y) * self.smooth

    -- Clamping logicera inside the map)
    if self.bounds then
        local halfWidth = (love.graphics.getWidth() / 2) / self.scale
        local halfHeight = (love.graphics.getHeight() / 2) / self.scale

        -- Calculate the min/max x and y the camera center can reach
        local minX = self.bounds.x + halfWidth
        local maxX = (self.bounds.x + self.bounds.w) - halfWidth
        local minY = self.bounds.y + halfHeight
        local maxY = (self.bounds.y + self.bounds.h) - halfHeight

        -- Clamp the vals. If the map is smaller than the screen, we lock to the center
        if minX > maxX then
            self.x = self.bounds.x + self.bounds.w / 2
        else
            self.x = clamp(self.x, minX, maxX)
        end

        if minY > maxY then
            self.y = self.bounds.y + self.bounds.h / 2
        else
            self.y = clamp(self.y, minY, maxY)
        end
    end
end

function Camera:attach()
    love.graphics.push()
    -- Scale first so the math works on the scaled world
    love.graphics.scale(self.scale) 
    -- Center the camera on self.x/self.y
    love.graphics.translate(
        -self.x + (love.graphics.getWidth() / 2) / self.scale, 
        -self.y + (love.graphics.getHeight() / 2) / self.scale
    )
end

function Camera:detach()
    love.graphics.pop()
end

return Camera