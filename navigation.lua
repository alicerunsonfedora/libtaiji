local tcontains = require("labyrinth.collections").contains
local models = require("models")

local TS = models.TileState

local navigation = {}

--- @param coord Vector
--- @param width number
--- @param tileCount number
--- @return number index
function navigation.coordToIndex(coord, width, tileCount)
    local height = tileCount / width
    if coord.x < 1 or coord.x > width or coord.y < 1 or coord.y > height then
        return -1
    end
    return width * (coord.y - 1) + coord.x
end

--- @param index number
--- @param width number
--- @return Vector
function navigation.indexToCoord(index, width)
    local coord = { x = 1, y = 1 }
    local stepsRemaining = index - 1
    while stepsRemaining > 0 do
        coord.x = coord.x + 1
        if coord.x > width then
            coord.x = 1
            coord.y = coord.y + 1
        end
        stepsRemaining = stepsRemaining - 1
    end
    return coord
end

--- @param index number
--- @param pzl Puzzle
--- @return table neighbors
function navigation.getNeighbors(index, pzl)
    local width = pzl.width
    local tileCount = #pzl.tiles
    local coord = navigation.indexToCoord(index, pzl.width)
    local up = { x = coord.x, y = coord.y - 1 }
    local left = { x = coord.x - 1, y = coord.y }
    local right = { x = coord.x + 1, y = coord.y }
    local down = { x = coord.x, y = coord.y + 1 }

    local tUp = navigation.coordToIndex(up, width, tileCount)
    local tLeft = navigation.coordToIndex(left, width, tileCount)
    local tRight = navigation.coordToIndex(right, width, tileCount)
    local tDown = navigation.coordToIndex(down, width, tileCount)

    local allNeighbors = {}
    if tUp and pzl.tiles[tUp].state ~= TS.kInvisible then allNeighbors["up"] = tUp end
    if tLeft and pzl.tiles[tLeft].state ~= TS.kInvisible then allNeighbors["left"] = tLeft end
    if tRight and pzl.tiles[tRight].state ~= TS.kInvisible then allNeighbors["right"] = tRight end
    if tDown and pzl.tiles[tDown].state ~= TS.kInvisible then allNeighbors["down"] = tDown end
    return allNeighbors
end

--- @param index number
--- @param pzl Puzzle
--- @return table<unknown, number>
function navigation.floodFill(index, pzl)
    local stack = {}
    local visited = {}
    local color = nil

    stack[#stack + 1] = index
    while #stack > 0 do
        local stackTop = stack[#stack]
        stack[#stack] = nil

        local top = pzl.tiles[stackTop]
        if top == nil then break end

        if color == nil then color = top.filled end
        if not tcontains(visited, stackTop) then visited[#visited + 1] = stackTop end

        local neighbors = navigation.getNeighbors(stackTop, pzl)
        for _,n in pairs(neighbors) do
            local nTile = pzl.tiles[n]
            if not tcontains(visited, n) and nTile ~= nil and nTile.filled == color then
                stack[#stack + 1] = n
            end
        end
    end

    return visited
end

return navigation