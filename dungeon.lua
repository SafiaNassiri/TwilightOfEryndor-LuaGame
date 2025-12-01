local Dungeon = {}
Dungeon.__index = Dungeon
local love = love

-- Utility
local function randInt(a, b) return math.random(a, b) end
local function insideGrid(g, x, y)
    return x >= 1 and x <= g.gridW and y >= 1 and y <= g.gridH
end

-- Prune dead ends (removes tiles with only one neighbor)
function Dungeon:pruneDeadEndsFunc()
    local changed = true
    while changed do
        changed = false
        for y = 2, self.gridH - 1 do
            for x = 2, self.gridW - 1 do
                if self.tiles[y][x] == 1 then
                    local neigh = 0
                    if self.tiles[y+1][x] == 1 then neigh = neigh + 1 end
                    if self.tiles[y-1][x] == 1 then neigh = neigh + 1 end
                    if self.tiles[y][x+1] == 1 then neigh = neigh + 1 end
                    if self.tiles[y][x-1] == 1 then neigh = neigh + 1 end
                    if neigh == 1 then
                        self.tiles[y][x] = 0
                        changed = true
                    end
                end
            end
        end
    end
end

-- Connect all disconnected floor regions
function Dungeon:connectDisjointAreas()
    local regionId = {}
    local currentId = 0
    local dirs = {{1,0},{-1,0},{0,1},{0,-1}}

    local function floodFill(sx, sy, id)
        local q = { {x=sx, y=sy} }
        regionId[sy] = regionId[sy] or {}
        regionId[sy][sx] = id

        while #q > 0 do
            local cur = table.remove(q, 1)
            for _, d in ipairs(dirs) do
                local nx, ny = cur.x + d[1], cur.y + d[2]
                if nx >= 1 and nx <= self.gridW and ny >= 1 and ny <= self.gridH then
                    regionId[ny] = regionId[ny] or {}
                    if self.tiles[ny][nx] == 1 and not regionId[ny][nx] then
                        regionId[ny][nx] = id
                        table.insert(q, {x=nx, y=ny})
                    end
                end
            end
        end
    end

    -- assign region ids
    for y = 1, self.gridH do
        for x = 1, self.gridW do
            regionId[y] = regionId[y] or {}
            if self.tiles[y][x] == 1 and not regionId[y][x] then
                currentId = currentId + 1
                floodFill(x, y, currentId)
            end
        end
    end

    if currentId <= 1 then return end

    -- Build region tile lists
    local regions = {}
    for id = 1, currentId do regions[id] = {} end
    for y = 1, self.gridH do
        for x = 1, self.gridW do
            local rid = regionId[y][x]
            if rid then
                table.insert(regions[rid], {x=x,y=y})
            end
        end
    end

    -- Connect all regions to region 1
    local mainRegion = regions[1]
    for rid = 2, currentId do
        local bestDist = math.huge
        local bestPair = nil
        for _, a in ipairs(mainRegion) do
            for _, b in ipairs(regions[rid]) do
                local d = (a.x-b.x)^2 + (a.y-b.y)^2
                if d < bestDist then
                    bestDist = d
                    bestPair = {a,b}
                end
            end
        end
        if bestPair then
            local x1, y1 = bestPair[1].x, bestPair[1].y
            local x2, y2 = bestPair[2].x, bestPair[2].y
            -- carve straight corridor
            local x, y = x1, y1
            while x ~= x2 do
                self.tiles[y][x] = 1
                x = x + (x2 > x and 1 or -1)
            end
            while y ~= y2 do
                self.tiles[y][x] = 1
                y = y + (y2 > y and 1 or -1)
            end
        end
    end
end

-- Dungeon constructor
function Dungeon:new(opts)
    opts = opts or {}
    local d = {
        gridW = opts.gridW or 50,
        gridH = opts.gridH or 50,
        tileSize = opts.tileSize or 32,
        tiles = {},
        rooms = {},
        floorList = {},
        generated = false,
        maxAttempts = opts.maxAttempts or 8,
        minFloorFraction = opts.minFloorFraction or 0.35,
        pruneDeadEnds = opts.pruneDeadEnds == nil and false or opts.pruneDeadEnds,
    }
    setmetatable(d, Dungeon)

    d.mapWidth = d.gridW * d.tileSize
    d.mapHeight = d.gridH * d.tileSize

    local success = false
    for attempt = 1, d.maxAttempts do
        d:clear()
        d:placeRooms()
        d:generateMaze()
        d:connectRoomsToMaze()
        d:applyRandomWalkOverlay()
        d:connectDisjointAreas() -- <--- ensure full connectivity
        if d.pruneDeadEnds then d:pruneDeadEndsFunc() end
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

    d:buildFloorList()
    return d
end

-- Initialize grid
function Dungeon:clear()
    self.rooms = {}
    self.floorList = {}
    self.tiles = {}
    for y = 1, self.gridH do
        self.tiles[y] = {}
        for x = 1, self.gridW do
            self.tiles[y][x] = 0
        end
    end
end

-- Room carving
function Dungeon:carveRect(cx, cy, w, h)
    local x0 = math.max(1, cx)
    local y0 = math.max(1, cy)
    local x1 = math.min(self.gridW, cx + w - 1)
    local y1 = math.min(self.gridH, cy + h - 1)
    for y = y0, y1 do
        for x = x0, x1 do
            self.tiles[y][x] = 1
        end
    end
end

-- Room placement
-- Room placement (more rooms)
function Dungeon:placeRooms()
    local attempts = math.floor((self.gridW * self.gridH) / 80) + 12  -- increased attempts
    for i = 1, attempts do
        local rw = randInt(6, 14)  -- slightly larger width
        local rh = randInt(6, 12)  -- slightly larger height
        local rx = randInt(2, self.gridW - rw - 1)
        local ry = randInt(2, self.gridH - rh - 1)

        local ok = true
        for y = ry - 1, ry + rh + 1 do
            for x = rx - 1, rx + rw + 1 do
                if insideGrid(self, x, y) and self.tiles[y][x] == 1 then
                    ok = false
                    break
                end
            end
            if not ok then break end
        end

        if ok then
            self:carveRect(rx, ry, rw, rh)
            table.insert(self.rooms, { x = rx, y = ry, w = rw, h = rh })
        end
    end
end

-- Sparse maze generation
function Dungeon:generateMaze()
    local walkers = randInt(2, 4)
    local lifespan = math.floor((self.gridW * self.gridH) / 200)
    for i = 1, walkers do
        local x = randInt(2, self.gridW - 1)
        local y = randInt(2, self.gridH - 1)
        for step = 1, lifespan do
            self.tiles[y][x] = 1
            local dir = randInt(1, 4)
            if dir == 1 and x < self.gridW - 1 then x = x + 1
            elseif dir == 2 and x > 2 then x = x - 1
            elseif dir == 3 and y < self.gridH - 1 then y = y + 1
            elseif dir == 4 and y > 2 then y = y - 1
            end
        end
    end
end

-- Connect rooms to open paths
function Dungeon:connectRoomsToMaze()
    for _, room in ipairs(self.rooms) do
        local rcx = math.floor(room.x + room.w / 2)
        local rcy = math.floor(room.y + room.h / 2)

        local visited = {}
        local q = { {x = rcx, y = rcy} }
        visited[rcy] = {[rcx]=true}

        local found = nil
        while #q > 0 and not found do
            local cur = table.remove(q, 1)
            local dirs = {{1,0},{-1,0},{0,1},{0,-1}}
            for _, d in ipairs(dirs) do
                local nx, ny = cur.x + d[1], cur.y + d[2]
                if nx>=1 and nx<=self.gridW and ny>=1 and ny<=self.gridH then
                    visited[ny] = visited[ny] or {}
                    if not visited[ny][nx] then
                        visited[ny][nx] = true
                        if self.tiles[ny][nx] == 1
                            and not (nx>=room.x and nx < room.x+room.w and ny>=room.y and ny<room.y+room.h)
                        then
                            found = {x=nx,y=ny}
                            break
                        end
                        table.insert(q, {x=nx,y=ny})
                    end
                end
            end
        end

        if found then
            local x, y = rcx, rcy
            while x ~= found.x do
                self.tiles[y][x] = 1
                x = x + (found.x > x and 1 or -1)
            end
            while y ~= found.y do
                self.tiles[y][x] = 1
                y = y + (found.y > y and 1 or -1)
            end
            self.tiles[found.y][found.x] = 1
        end
    end
end

-- Random walk overlay
function Dungeon:applyRandomWalkOverlay()
    local walkers = randInt(3, 6)
    local lifespan = math.floor((self.gridW * self.gridH) / 50)
    for i = 1, walkers do
        local x = randInt(2, self.gridW - 1)
        local y = randInt(2, self.gridH - 1)
        for step = 1, lifespan do
            self.tiles[y][x] = 1
            local dir = randInt(1, 4)
            if dir == 1 and x < self.gridW - 1 then x = x + 1
            elseif dir == 2 and x > 2 then x = x - 1
            elseif dir == 3 and y < self.gridH - 1 then y = y + 1
            elseif dir == 4 and y > 2 then y = y - 1
            end
        end
    end
end

-- Floor list
function Dungeon:buildFloorList()
    self.floorList = {}
    for y = 1, self.gridH do
        for x = 1, self.gridW do
            if self.tiles[y][x] == 1 then
                table.insert(self.floorList, { x = (x-1)*self.tileSize, y = (y-1)*self.tileSize })
            end
        end
    end
end

-- Map validator
function Dungeon:validate()
    local startx, starty = nil, nil
    local floorCount = 0
    for y=1,self.gridH do
        for x=1,self.gridW do
            if self.tiles[y][x] == 1 then
                floorCount = floorCount + 1
                if not startx then startx, starty = x, y end
            end
        end
    end
    if floorCount == 0 then return false end
    if floorCount < math.floor(self.gridW*self.gridH*self.minFloorFraction) then return false end

    local visited = {}
    local q = { {x=startx,y=starty} }
    visited[starty] = {[startx] = true}
    local seen = 0
    while #q > 0 do
        local cur = table.remove(q, 1)
        seen = seen + 1
        local dirs = {{1,0},{-1,0},{0,1},{0,-1}}
        for _,d in ipairs(dirs) do
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

    return (seen / floorCount) >= 0.80
end

-- Player spawn
function Dungeon:getPlayerStart()
    if #self.rooms > 0 then
        local r = self.rooms[1]
        local sx = math.floor((r.x + math.floor(r.w/2)) * self.tileSize - (self.tileSize/2))
        local sy = math.floor((r.y + math.floor(r.h/2)) * self.tileSize - (self.tileSize/2))
        return sx + self.tileSize/2, sy + self.tileSize/2
    end
    if #self.floorList > 0 then
        local f = self.floorList[1]
        return f.x + self.tileSize/2, f.y + self.tileSize/2
    end
    return math.floor(self.mapWidth/2), math.floor(self.mapHeight/2)
end

-- Walkability
function Dungeon:isWalkable(px, py)
    local tx = math.floor(px / self.tileSize) + 1
    local ty = math.floor(py / self.tileSize) + 1
    if tx<1 or tx>self.gridW or ty<1 or ty>self.gridH then return false end
    return self.tiles[ty][tx] == 1
end

-- Line-of-sight
function Dungeon:lineOfSight(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist == 0 then return true end
    local steps = math.ceil(dist / self.tileSize)
    for i = 0, steps do
        local t = i / steps
        local xt = x1 + dx * t
        local yt = y1 + dy * t
        local tx = math.floor(xt / self.tileSize) + 1
        local ty = math.floor(yt / self.tileSize) + 1
        if tx < 1 or tx > self.gridW or ty < 1 or ty > self.gridH then return false end
        if self.tiles[ty][tx] ~= 1 then return false end
    end
    return true
end

-- Debug drawing
function Dungeon:drawDebug()
    love.graphics.setColor(1,0,0,0.5)
    for _, r in ipairs(self.rooms) do
        love.graphics.rectangle("line",
            (r.x - 1) * self.tileSize,
            (r.y - 1) * self.tileSize,
            r.w * self.tileSize,
            r.h * self.tileSize
        )
    end
    love.graphics.setColor(0,1,1,0.5)
    love.graphics.print("DEBUG MODE\nRooms: "..#self.rooms, 10, 10)
end

function Dungeon:draw(showDebug)
    love.graphics.setColor(0.3,0.3,0.3)
    for _, t in ipairs(self.floorList) do
        love.graphics.rectangle("fill", t.x, t.y, self.tileSize, self.tileSize)
    end

    love.graphics.setColor(0.5,0.4,0.4)
    for y=1,self.gridH do
        for x=1,self.gridW do
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
    love.graphics.setColor(1,1,1)
end

return Dungeon
