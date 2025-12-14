local Dungeon = {}
Dungeon.__index = Dungeon
local love = love

---------------------------------------------
-- UTILITY FUNCTIONS
---------------------------------------------

-- Generate random integer between a and b (inclusive)
local function randInt(a, b) return math.random(a, b) end

-- Check if coordinates are within grid bounds
local function insideGrid(g, x, y)
    return x >= 1 and x <= g.gridW and y >= 1 and y <= g.gridH
end

---------------------------------------------
-- PRUNE DEAD ENDS
-- Removes corridors that only connect to one other tile
-- This creates more interesting layouts by removing useless branches
---------------------------------------------
function Dungeon:pruneDeadEndsFunc()
    local changed = true
    
    -- Keep iterating until no more dead ends are found
    while changed do
        changed = false
        
        -- Check each interior tile (skip edges)
        for y = 2, self.gridH - 1 do
            for x = 2, self.gridW - 1 do
                -- Only check walkable floor tiles
                if self.tiles[y][x] == 1 then
                    -- Count how many adjacent tiles are also floor
                    local neigh = 0
                    if self.tiles[y+1][x] == 1 then neigh = neigh + 1 end  -- Below
                    if self.tiles[y-1][x] == 1 then neigh = neigh + 1 end  -- Above
                    if self.tiles[y][x+1] == 1 then neigh = neigh + 1 end  -- Right
                    if self.tiles[y][x-1] == 1 then neigh = neigh + 1 end  -- Left
                    
                    -- If only 1 neighbor, this is a dead end - remove it
                    if neigh == 1 then
                        self.tiles[y][x] = 0
                        changed = true
                    end
                end
            end
        end
    end
end

---------------------------------------------
-- CONNECT DISJOINT AREAS
-- Ensures all walkable areas are connected using flood fill
-- This prevents isolated rooms/sections
---------------------------------------------
function Dungeon:connectDisjointAreas()
    local regionId = {}  -- Stores which region each tile belongs to
    local currentId = 0  -- Counter for region IDs
    local dirs = {{1,0},{-1,0},{0,1},{0,-1}}  -- 4 cardinal directions

    -- Flood fill algorithm: marks all connected tiles with same region ID
    local function floodFill(sx, sy, id)
        local q = { {x=sx, y=sy} }  -- Queue for breadth-first search
        regionId[sy] = regionId[sy] or {}
        regionId[sy][sx] = id

        while #q > 0 do
            local cur = table.remove(q, 1)  -- Dequeue
            
            -- Check all 4 directions
            for _, d in ipairs(dirs) do
                local nx, ny = cur.x + d[1], cur.y + d[2]
                
                -- Only process tiles within bounds
                if nx >= 1 and nx <= self.gridW and ny >= 1 and ny <= self.gridH then
                    regionId[ny] = regionId[ny] or {}
                    
                    -- If floor tile and not yet visited, add to this region
                    if self.tiles[ny][nx] == 1 and not regionId[ny][nx] then
                        regionId[ny][nx] = id
                        table.insert(q, {x=nx, y=ny})  -- Enqueue for processing
                    end
                end
            end
        end
    end

    -- Find all separate regions using flood fill
    for y = 1, self.gridH do
        for x = 1, self.gridW do
            regionId[y] = regionId[y] or {}
            
            -- Start new region if this floor tile hasn't been visited
            if self.tiles[y][x] == 1 and not regionId[y][x] then
                currentId = currentId + 1
                floodFill(x, y, currentId)
            end
        end
    end

    -- If only 1 region, everything is already connected!
    if currentId <= 1 then return end

    -- Group all tiles by their region ID
    local regions = {}
    for id = 1, currentId do regions[id] = {} end

    for y = 1, self.gridH do
        for x = 1, self.gridW do
            local rid = regionId[y][x]
            if rid then table.insert(regions[rid], {x=x,y=y}) end
        end
    end

    -- Connect each separate region to the main region
    local mainRegion = regions[1]
    for rid = 2, currentId do
        local bestDist = math.huge
        local bestPair = nil
        
        -- Find closest pair of tiles between main region and this region
        for _, a in ipairs(mainRegion) do
            for _, b in ipairs(regions[rid]) do
                local d = (a.x-b.x)^2 + (a.y-b.y)^2  -- Distance squared
                if d < bestDist then
                    bestDist = d
                    bestPair = {a,b}
                end
            end
        end

        -- Carve corridor between the two closest tiles
        if bestPair then
            local x1, y1 = bestPair[1].x, bestPair[1].y
            local x2, y2 = bestPair[2].x, bestPair[2].y
            local x, y = x1, y1

            -- Carve horizontal corridor first
            while x ~= x2 do
                self.tiles[y][x] = 1
                x = x + (x2 > x and 1 or -1)
            end
            
            -- Then carve vertical corridor
            while y ~= y2 do
                self.tiles[y][x] = 1
                y = y + (y2 > y and 1 or -1)
            end
        end
    end
end

---------------------------------------------
-- CONSTRUCTOR
-- Creates a new dungeon with procedural generation
---------------------------------------------
function Dungeon:new(opts)
    opts = opts or {}
    local d = {
        gridW = opts.gridW or 50,                      -- Grid width in tiles
        gridH = opts.gridH or 50,                      -- Grid height in tiles
        tileSize = opts.tileSize or 32,                -- Pixel size of each tile
        tiles = {},                                    -- 2D array: 0=wall, 1=floor
        rooms = {},                                    -- List of rectangular rooms
        floorList = {},                                -- All floor tile positions
        generated = false,                             -- Success flag
        maxAttempts = opts.maxAttempts or 8,           -- Retries if generation fails
        minFloorFraction = opts.minFloorFraction or 0.35,  -- Minimum floor % required
        pruneDeadEnds = opts.pruneDeadEnds == nil and false or opts.pruneDeadEnds,
        MAX_ROOMS = opts.MAX_ROOMS or 18               -- Maximum number of rooms
    }
    setmetatable(d, Dungeon)

    d.mapWidth = d.gridW * d.tileSize
    d.mapHeight = d.gridH * d.tileSize

    -- Try generating dungeon multiple times until valid
    local success = false
    for attempt = 1, d.maxAttempts do
        d:clear()                    -- Reset grid
        d:placeRooms()               -- Add rectangular rooms
        d:generateMaze()             -- Add maze-like corridors
        d:connectRoomsToMaze()       -- Ensure rooms connect to corridors
        d:applyRandomWalkOverlay()   -- Add organic winding paths
        d:connectDisjointAreas()     -- Connect isolated sections
        
        if d.pruneDeadEnds then 
            d:pruneDeadEndsFunc()    -- Optional: remove dead-end corridors
        end
        
        -- Check if dungeon meets quality standards
        if d:validate() then
            success = true
            d.generated = true
            break
        end
    end

    if success then 
        print("[Dungeon] generated successfully.")
    else 
        print("[Dungeon] FAILED after " .. d.maxAttempts .. " attempts.") 
    end

    d:buildFloorList()  -- Cache all floor positions for fast access
    return d
end

---------------------------------------------
-- CLEAR GRID
-- Resets entire grid to walls (0)
---------------------------------------------
function Dungeon:clear()
    self.rooms = {}
    self.floorList = {}
    self.tiles = {}
    
    -- Initialize all tiles as walls
    for y = 1, self.gridH do
        self.tiles[y] = {}
        for x = 1, self.gridW do
            self.tiles[y][x] = 0  -- 0 = wall
        end
    end
end

---------------------------------------------
-- CARVE RECTANGLE
-- Turns a rectangular area into floor tiles
---------------------------------------------
function Dungeon:carveRect(cx, cy, w, h)
    -- Clamp to grid bounds
    local x0 = math.max(1, cx)
    local y0 = math.max(1, cy)
    local x1 = math.min(self.gridW, cx + w - 1)
    local y1 = math.min(self.gridH, cy + h - 1)

    -- Fill rectangle with floor tiles
    for y = y0, y1 do
        for x = x0, x1 do
            self.tiles[y][x] = 1  -- 1 = floor
        end
    end
end

---------------------------------------------
-- PLACE ROOMS
-- Randomly places rectangular rooms that don't overlap
---------------------------------------------
function Dungeon:placeRooms()
    local attempts = self.MAX_ROOMS * 3  -- Try 3x as many times as max rooms
    
    for i = 1, attempts do
        if #self.rooms >= self.MAX_ROOMS then break end  -- Stop at room limit

        -- Random room size
        local rw = randInt(6, 14)  -- Width: 6-14 tiles
        local rh = randInt(6, 12)  -- Height: 6-12 tiles
        
        -- Random position (with padding from edges)
        local rx = randInt(2, self.gridW - rw - 1)
        local ry = randInt(2, self.gridH - rh - 1)

        -- Check if room overlaps with existing rooms (includes 1-tile buffer)
        local ok = true
        for y = ry - 1, ry + rh + 1 do
            for x = rx - 1, rx + rw + 1 do
                if insideGrid(self, x, y) and self.tiles[y][x] == 1 then
                    ok = false  -- Overlap detected!
                    break
                end
            end
            if not ok then break end
        end

        -- If no overlap, place the room
        if ok then
            self:carveRect(rx, ry, rw, rh)
            table.insert(self.rooms, { x = rx, y = ry, w = rw, h = rh })
        end
    end
end

---------------------------------------------
-- GENERATE MAZE
-- Creates maze-like corridors using random walkers
---------------------------------------------
function Dungeon:generateMaze()
    local walkers = randInt(2, 4)  -- 2-4 simultaneous walkers
    local lifespan = math.floor((self.gridW * self.gridH) / 200)  -- Steps per walker
    
    for i = 1, walkers do
        -- Start at random position
        local x = randInt(2, self.gridW - 1)
        local y = randInt(2, self.gridH - 1)
        
        -- Walk randomly, carving floor as we go
        for step = 1, lifespan do
            self.tiles[y][x] = 1  -- Carve floor
            
            -- Move in random direction
            local dir = randInt(1, 4)
            if dir == 1 and x < self.gridW - 1 then x = x + 1      -- Right
            elseif dir == 2 and x > 2 then x = x - 1                -- Left
            elseif dir == 3 and y < self.gridH - 1 then y = y + 1  -- Down
            elseif dir == 4 and y > 2 then y = y - 1                -- Up
            end
        end
    end
end

---------------------------------------------
-- CONNECT ROOMS TO MAZE
-- Ensures each room has a corridor leading to the maze
---------------------------------------------
function Dungeon:connectRoomsToMaze()
    for _, room in ipairs(self.rooms) do
        -- Start from room center
        local rcx = math.floor(room.x + room.w / 2)
        local rcy = math.floor(room.y + room.h / 2)

        -- Use breadth-first search to find nearest corridor
        local visited = {}
        local q = { {x = rcx, y = rcy} }
        visited[rcy] = {[rcx]=true}

        local found = nil  -- Will store the corridor tile we connect to
        
        while #q > 0 and not found do
            local cur = table.remove(q, 1)
            local dirs = {{1,0},{-1,0},{0,1},{0,-1}}
            
            for _, d in ipairs(dirs) do
                local nx, ny = cur.x + d[1], cur.y + d[2]
                
                if nx>=1 and nx<=self.gridW and ny>=1 and ny<=self.gridH then
                    visited[ny] = visited[ny] or {}
                    
                    if not visited[ny][nx] then
                        visited[ny][nx] = true
                        
                        -- Found a floor tile outside this room!
                        if self.tiles[ny][nx] == 1
                            and not (nx>=room.x and nx < room.x+room.w
                            and ny>=room.y and ny<room.y+room.h)
                        then
                            found = {x=nx,y=ny}
                            break
                        end
                        
                        table.insert(q, {x=nx,y=ny})
                    end
                end
            end
        end

        -- Carve straight corridor from room center to found tile
        if found then
            local x, y = rcx, rcy
            
            -- Horizontal corridor
            while x ~= found.x do
                self.tiles[y][x] = 1
                x = x + (found.x > x and 1 or -1)
            end
            
            -- Vertical corridor
            while y ~= found.y do
                self.tiles[y][x] = 1
                y = y + (found.y > y and 1 or -1)
            end
            
            self.tiles[found.y][found.x] = 1
        end
    end
end

---------------------------------------------
-- RANDOM WALK OVERLAY
-- Adds organic, winding corridors for variety
---------------------------------------------
function Dungeon:applyRandomWalkOverlay()
    local walkers = randInt(3, 6)  -- 3-6 walkers
    local lifespan = math.floor((self.gridW * self.gridH) / 50)
    
    for i = 1, walkers do
        local x = randInt(2, self.gridW - 1)
        local y = randInt(2, self.gridH - 1)
        
        for step = 1, lifespan do
            self.tiles[y][x] = 1  -- Carve floor
            
            -- Random walk
            local dir = randInt(1, 4)
            if dir == 1 and x < self.gridW - 1 then x = x + 1
            elseif dir == 2 and x > 2 then x = x - 1
            elseif dir == 3 and y < self.gridH - 1 then y = y + 1
            elseif dir == 4 and y > 2 then y = y - 1
            end
        end
    end
end

---------------------------------------------
-- BUILD FLOOR LIST
-- Creates cached list of all floor tile positions
-- Used for fast random spawning
---------------------------------------------
function Dungeon:buildFloorList()
    self.floorList = {}
    for y = 1, self.gridH do
        for x = 1, self.gridW do
            if self.tiles[y][x] == 1 then
                table.insert(self.floorList,
                    { x = (x-1)*self.tileSize, y = (y-1)*self.tileSize }
                )
            end
        end
    end
end

---------------------------------------------
-- VALIDATE DUNGEON
-- Checks if dungeon meets minimum quality standards:
-- 1. Has enough floor tiles (min 35%)
-- 2. All floor is connected (at least 80% reachable)
---------------------------------------------
function Dungeon:validate()
    local startx, starty = nil, nil
    local floorCount = 0

    -- Count total floor tiles
    for y=1,self.gridH do
        for x=1,self.gridW do
            if self.tiles[y][x] == 1 then
                floorCount = floorCount + 1
                if not startx then startx, starty = x, y end  -- Remember first floor tile
            end
        end
    end

    -- Must have at least some floor
    if floorCount == 0 then return false end
    
    -- Must meet minimum floor percentage
    if floorCount < math.floor(self.gridW*self.gridH*self.minFloorFraction) then 
        return false 
    end

    -- Flood fill from first floor tile to see how much is reachable
    local visited = {}
    local q = { {x=startx,y=starty} }
    visited[starty] = {[startx] = true}
    local seen = 0

    while #q > 0 do
        local cur = table.remove(q, 1)
        seen = seen + 1

        for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
            local nx,ny = cur.x+d[1], cur.y+d[2]
            if nx>=1 and nx<=self.gridW and ny>=1 and ny<=self.gridH then
                visited[ny] = visited[ny] or {}
                if not visited[ny][nx] and self.tiles[ny][nx] == 1 then
                    visited[ny][nx] = true
                    table.insert(q, {x=nx,y=ny})
                end
            end
        end
    end

    -- At least 80% of floor must be reachable (allows some small isolated areas)
    return (seen / floorCount) >= 0.80
end

---------------------------------------------
-- GET PLAYER START POSITION
-- Returns coordinates for player spawn
-- Prefers center of first room, falls back to first floor tile
---------------------------------------------
function Dungeon:getPlayerStart()
    -- Spawn in center of first room if rooms exist
    if #self.rooms > 0 then
        local r = self.rooms[1]
        local sx = math.floor((r.x + math.floor(r.w/2)) * self.tileSize - (self.tileSize/2))
        local sy = math.floor((r.y + math.floor(r.h/2)) * self.tileSize - (self.tileSize/2))
        return sx + self.tileSize/2, sy + self.tileSize/2
    end
    
    -- Otherwise use first floor tile
    if #self.floorList > 0 then
        local f = self.floorList[1]
        return f.x + self.tileSize/2, f.y + self.tileSize/2
    end
    
    -- Last resort: center of map (shouldn't happen with valid dungeon)
    return math.floor(self.mapWidth/2), math.floor(self.mapHeight/2)
end

---------------------------------------------
-- IS WALKABLE
-- Checks if pixel coordinates are on a floor tile
---------------------------------------------
function Dungeon:isWalkable(px, py)
    -- Convert pixel coordinates to grid coordinates
    local tx = math.floor(px / self.tileSize) + 1
    local ty = math.floor(py / self.tileSize) + 1
    
    -- Out of bounds = wall
    if tx<1 or tx>self.gridW or ty<1 or ty>self.gridH then return false end
    
    -- Return true if floor (1), false if wall (0)
    return self.tiles[ty][tx] == 1
end

---------------------------------------------
-- LINE OF SIGHT
-- Checks if there's a clear path between two points
-- Used for enemy vision and projectile collision
---------------------------------------------
function Dungeon:lineOfSight(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dist = math.sqrt(dx*dx + dy*dy)
    
    if dist == 0 then return true end  -- Same position

    -- Sample points along the line
    local steps = math.ceil(dist / self.tileSize)
    for i = 0, steps do
        local t = i / steps  -- Interpolation factor (0 to 1)
        local xt = x1 + dx * t
        local yt = y1 + dy * t
        
        -- Convert to grid coordinates
        local tx = math.floor(xt / self.tileSize) + 1
        local ty = math.floor(yt / self.tileSize) + 1

        -- Hit wall or out of bounds?
        if tx < 1 or tx > self.gridW or ty < 1 or ty > self.gridH then 
            return false 
        end
        if self.tiles[ty][tx] ~= 1 then 
            return false 
        end
    end
    
    return true  -- Clear line of sight!
end

---------------------------------------------
-- DEBUG DRAWING
-- Shows room outlines and info (for development)
---------------------------------------------
function Dungeon:drawDebug()
    -- Draw red outlines around rooms
    love.graphics.setColor(1,0,0,0.5)
    for _, r in ipairs(self.rooms) do
        love.graphics.rectangle("line",
            (r.x - 1) * self.tileSize,
            (r.y - 1) * self.tileSize,
            r.w * self.tileSize,
            r.h * self.tileSize
        )
    end

    -- Show debug text
    love.graphics.setColor(0,1,1,0.5)
    love.graphics.print("DEBUG MODE\nRooms: "..#self.rooms, 10, 10)
end

---------------------------------------------
-- DRAW DUNGEON
-- Renders the entire dungeon
---------------------------------------------
function Dungeon:draw(showDebug)
    -- Draw floor tiles (dark blue)
    love.graphics.setColor(0.227, 0.220, 0.345)  -- #3a3858
    for _, t in ipairs(self.floorList) do
        love.graphics.rectangle("fill", t.x, t.y, self.tileSize, self.tileSize)
    end

    -- Draw wall outlines (darker gray)
    love.graphics.setColor(0.271, 0.267, 0.310)  -- #45444f
    for y=1,self.gridH do
        for x=1,self.gridW do
            -- Only draw walls adjacent to floor (for visual effect)
            if self.tiles[y][x]==0 then
                if (self.tiles[y-1] and self.tiles[y-1][x]==1) or
                   (self.tiles[y+1] and self.tiles[y+1][x]==1) or
                   (self.tiles[y] and self.tiles[y][x-1]==1) or
                   (self.tiles[y] and self.tiles[y][x+1]==1)
                then
                    love.graphics.rectangle("line",
                        (x-1)*self.tileSize,
                        (y-1)*self.tileSize,
                        self.tileSize,
                        self.tileSize
                    )
                end
            end
        end
    end

    if showDebug then self:drawDebug() end
    love.graphics.setColor(1,1,1)  -- Reset color
end

return Dungeon