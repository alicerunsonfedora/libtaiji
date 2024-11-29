local foldLeft = require("labyrinth.collections").foldLeft

local __HASHCONST = 524287

local function vechash(vector)
    return (vector.x * __HASHCONST + vector.y) * __HASHCONST
end

--- @param vectors table<unknown, Vector>
--- @return number
local function hashVectorArray(vectors)
    return foldLeft(vectors, 0, function (hash, vec)
        return hash + vechash(vec)
    end)
end

return hashVectorArray