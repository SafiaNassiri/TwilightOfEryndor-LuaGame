local Camera = {}
Camera.__index = Camera

-- Function to clamp a value between min and max
local function clamp(x, min, max)
    return x < min and min or (x > max and max or x)
end

-- Camera constructor
-- x, y    = starting camera position (world space)
-- scale   = zoom level (1 = default)
function Camera:new(x, y, scale)
    local cam = {
        x = x or 0,           -- camera center x
        y = y or 0,           -- camera center y
        scale = scale or 1,   -- zoom factor
        smooth = 0.1,         -- smoothing factor (lower = slower camera)
        -- bounds = nil          -- optional world bounds
    }
    setmetatable(cam, Camera)
    return cam
end

-- Set world boundaries for the camera
-- x, y = top-left of the map
-- w, h = width and height of the map
function Camera:setBounds(x, y, w, h)
    self.bounds = { x = x, y = y, w = w, h = h }
end

-- Update camera position
-- tx, ty = target position to follow
function Camera:update(tx, ty)
    -- Smooth movement toward the target
    self.x = self.x + (tx - self.x) * self.smooth
    self.y = self.y + (ty - self.y) * self.smooth

    -- -- Clamp camera inside the map bounds (if bounds exist)
    -- if self.bounds then
    --     -- Half of the screen size in world units (adjusted for zoom)
    --     local halfWidth = (love.graphics.getWidth() / 2) / self.scale
    --     local halfHeight = (love.graphics.getHeight() / 2) / self.scale

    --     -- Calculate min/max positions the camera center can reach
    --     local minX = self.bounds.x + halfWidth
    --     local maxX = (self.bounds.x + self.bounds.w) - halfWidth
    --     local minY = self.bounds.y + halfHeight
    --     local maxY = (self.bounds.y + self.bounds.h) - halfHeight

    --     -- If the map is smaller than the screen, lock camera to center
    --     if minX > maxX then
    --         self.x = self.bounds.x + self.bounds.w / 2
    --     else
    --         self.x = clamp(self.x, minX, maxX)
    --     end

    --     if minY > maxY then
    --         self.y = self.bounds.y + self.bounds.h / 2
    --     else
    --         self.y = clamp(self.y, minY, maxY)
    --     end
    -- end
end

-- Apply camera transform before drawing the world
function Camera:attach()
    love.graphics.push()

    -- Apply zoom first
    love.graphics.scale(self.scale)

    -- Translate world so the camera is centered on (x, y)
    love.graphics.translate(
        -self.x + (love.graphics.getWidth() / 2) / self.scale,
        -self.y + (love.graphics.getHeight() / 2) / self.scale
    )
end

-- Reset transformations after drawing the world
function Camera:detach()
    love.graphics.pop()
end

return Camera
