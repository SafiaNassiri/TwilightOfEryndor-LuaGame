local Camera = require("camera")
local Player = require("player")
local Dungeon = require("dungeon")

function love.load()
    player = Player:new(400, 300)
    dungeon = Dungeon:new()

    camera = Camera:new(400, 300)
end

function love.update(dt)
    player:update(dt)
    camera:update(player.x, player.y)
end

function love.draw()
    camera:attach()
    
    dungeon:draw()
    player:draw()

    camera:detach()

    -- UI (not affected by camera)
    love.graphics.print("Twilight of Eryndor", 10, 10)
end
