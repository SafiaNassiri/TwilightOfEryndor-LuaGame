local Dungeon = {}
Dungeon.__index = Dungeon

function Dungeon:new()
    local d = {
        rooms = {}
    }
    setmetatable(d, Dungeon)

    -- Make a simple background floor for testing
    for x = 1, 50 do
        for y = 1, 50 do
            table.insert(d.rooms, {x = x * 32, y = y * 32})
        end
    end

    return d
end

function Dungeon:draw()
    love.graphics.setColor(0.2, 0.2, 0.2)

    for _, tile in ipairs(self.rooms) do
        love.graphics.rectangle("fill", tile.x, tile.y, 30, 30)
    end

    love.graphics.setColor(1, 1, 1)
end

return Dungeon
