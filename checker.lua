local coll = require("labyrinth.collections")
local vec = require("labyrinth.vector")

local models = require("models")
local nav = require("navigation")
local hashVecTbl = require("hasher")

local tcontains = coll.contains
local allSatisfy = coll.allSatisfy
local map = coll.map

local vecsub = vec.vecsub

local Sym = models.Symbol

local toCoord = nav.indexToCoord
local getNeighbors = nav.getNeighbors
local floodFill = nav.floodFill

--- @enum SymbolLUTKey
local SymbolLUTKey = {
    kSlashdash = "SLASHDASH",
    kDotPlus = "DOTPLUS",
    kDotMinus = "DOTMINUS",
    kFlower = "FLOWER",
    kDiamond = "DIAMOND"
}

--- @param idx number
--- @param pzl Puzzle
--- @return boolean
local function flowerConstraintsSatisfied(idx, pzl)
    local flowerTile = pzl.tiles[idx]
    local flowerFilled = flowerTile.filled
    local flowerSize = flowerTile.symbolValue or 4

    local neighbors = getNeighbors(idx, pzl)
    local nTiles = coll.strippedKeys(neighbors)
    nTiles = map(nTiles, function (t) return pzl.tiles[t] end)

    local totalFilledRel = coll.count(nTiles, function (t)
        return t.filled == flowerFilled
    end)
    return totalFilledRel == flowerSize
end

--- @param regionMap table
--- @param symbolLUT table
--- @return boolean
local function simpleDiamondCheck(regionMap, symbolLUT)
    local diamondCounts = {}
    for _,diamond in pairs(symbolLUT[SymbolLUTKey.kDiamond]) do
        local diamondRegion = regionMap[diamond]
        if not diamondCounts[diamondRegion] then diamondCounts[diamondRegion] = 0 end
        diamondCounts[diamondRegion] = diamondCounts[diamondRegion] + 1
    end
    return allSatisfy(diamondCounts, function (d) return d == 2 end)
end

--- @param lhs table<unknown, Vector>
--- @param rhs table<unknown, Vector>
--- @return boolean matches
local function regionShapesMatch(lhs, rhs)
    local lhsHash = hashVecTbl(lhs)
    local rhsHash = hashVecTbl(rhs)
    return lhsHash == rhsHash
end

--- @param lhs table<unknown, Vector>
--- @param rhs table<unknown, Vector>
--- @param lhsTile Tile
--- @param rhsTile Tile
--- @return boolean matchesRotated
local function regionShapesMatchRotated(lhs, rhs, lhsTile, rhsTile)
    local lhsRots = lhsTile.symbol == Sym.kSlash
    local rhsRots = rhsTile.symbol == Sym.kSlash

    local function checkRotated(toRotate, static)
        local rotated = toRotate
        for _=1, 4 do
            local potentialMatch = regionShapesMatch(static, rotated)
            if potentialMatch then return true end
            rotated = coll.map(rotated, vec.rotate)
        end
        return false
    end

    if lhsRots and not rhsRots then
        return checkRotated(lhs, rhs)
    elseif rhsRots and not lhsRots then
        return checkRotated(rhs, lhs)
    else
        return checkRotated(lhs, rhs) or checkRotated(rhs, lhs)
    end
end

--- @param symbolLUT table<SymbolLUTKey, table<unknown, number>>
--- @param tile Tile
--- @param index number
local function updateSymbolLUT(symbolLUT, tile, index)
    if tile.symbol == nil then return end
    if tile.symbol == Sym.kDash or tile.symbol == Sym.kSlash then
        if not symbolLUT[SymbolLUTKey.kSlashdash] then symbolLUT[SymbolLUTKey.kSlashdash] = {} end
        symbolLUT[SymbolLUTKey.kSlashdash][#symbolLUT[SymbolLUTKey.kSlashdash] + 1] = index
    elseif tile.symbol == Sym.kFlower then
        if not symbolLUT[SymbolLUTKey.kFlower] then symbolLUT[SymbolLUTKey.kFlower] = {} end
        symbolLUT[SymbolLUTKey.kFlower][#symbolLUT[SymbolLUTKey.kFlower] + 1] = index
    elseif tile.symbol == Sym.kDiamond then
        if not symbolLUT[SymbolLUTKey.kDiamond] then symbolLUT[SymbolLUTKey.kDiamond] = {} end
        symbolLUT[SymbolLUTKey.kDiamond][#symbolLUT[SymbolLUTKey.kDiamond] + 1] = index
    elseif tile.symbol == Sym.kDotPositive then
        if not symbolLUT[SymbolLUTKey.kDotPlus] then symbolLUT[SymbolLUTKey.kDotPlus] = {} end
        symbolLUT[SymbolLUTKey.kDotPlus][#symbolLUT[SymbolLUTKey.kDotPlus] + 1] = index
    elseif tile.symbol == Sym.kDotNegative then
        if not symbolLUT[SymbolLUTKey.kDotMinus] then symbolLUT[SymbolLUTKey.kDotMinus] = {} end
        symbolLUT[SymbolLUTKey.kDotMinus][#symbolLUT[SymbolLUTKey.kDotMinus] + 1] = index
    end
end

-- MARK: Checker

--- @param pzl Puzzle
--- @return boolean solved
local function checkPuzzleBoard(pzl)
    local currentRegion = 1
    local totalRegions = 0
    local regionMap = {}
    local symbolLUT = {}

    -- First pass: create the symbol table and region maps to save us some trouble later.
    for i=1, #pzl.tiles do
        if not tcontains(regionMap, i) then
            local region = floodFill(i, pzl)
            for _,t in pairs(region) do regionMap[t] = currentRegion end
            currentRegion = currentRegion + 1
            totalRegions = totalRegions + 1
        end

        local tile = pzl.tiles[i]
        updateSymbolLUT(symbolLUT, tile, i)
    end

    -- Second pass: check that all constraints have been satisfied.
    local flowersSatisfied = allSatisfy(symbolLUT[SymbolLUTKey.kFlower], function (t)
        return flowerConstraintsSatisfied(t, pzl)
    end)
    if not flowersSatisfied then return false end

    -- TODO: Check color rules in the future (gate behind an option flag).
    if not simpleDiamondCheck(regionMap, symbolLUT) then return false end

    local regionSizes = {}
    for _,dot in pairs(symbolLUT[SymbolLUTKey.kDotPlus]) do
        local tile = pzl.tiles[dot]
        local region = regionMap[dot]
        if regionSizes[region] == nil then regionSizes[region] = 0 end
        regionSizes[region] = regionSizes[region] + (tile.symbolValue or 0)
    end
    for _,dot in pairs(symbolLUT[SymbolLUTKey.kDotMinus]) do
        local tile = pzl.tiles[dot]
        local region = regionMap[dot]
        if regionSizes[region] == nil then regionSizes[region] = 0 end
        regionSizes[region] = regionSizes[region] - (tile.symbolValue or 0)
    end

    local trueRegionSizes = {}
    for _,region in pairs(regionMap) do
        if trueRegionSizes[region] == nil then trueRegionSizes[region] = 0 end
        trueRegionSizes[region] = trueRegionSizes[region] + 1
    end

    for i=1,totalRegions do
        local expectedSize = regionSizes[i] or 0
        local actualSize = trueRegionSizes[i] or 0
        if expectedSize ~= 0 and actualSize ~= expectedSize then
            return false
        end
    end

    local slashdashes = symbolLUT[SymbolLUTKey.kSlashdash]
    if #slashdashes > 0 then
        local slashdashRegions = map(slashdashes, function (s) return regionMap[s] end)
        local regionShapes = {}
        local currentShapeRegion = {}

        -- TODO: Maybe we can use a filter here instead of this conditional insertion?
        for regionKey, region in pairs(slashdashRegions) do
            local regionCoord = toCoord(slashdashes[regionKey], pzl.width)
            for key,val in pairs(regionMap) do
                if val == region then
                    local keyCoord = toCoord(key, pzl.width)
                    currentShapeRegion[#currentShapeRegion + 1] = vecsub(keyCoord, regionCoord)
                end
            end
            regionShapes[#regionShapes + 1] = currentShapeRegion
            currentShapeRegion = {}
        end

        local expectedShape = regionShapes[1]
        local baseTile = pzl.tiles[slashdashes[1]]
        local expectedShapeRotates = baseTile.symbol == Sym.kSlash

        for i=2,#regionShapes do
            local testShape = regionShapes[i]
            local origin = pzl.tiles[slashdashes[i]]

            if origin.symbol == Sym.kSlash or expectedShapeRotates then
                if not regionShapesMatchRotated(expectedShape, testShape, baseTile, origin) then
                    return false
                end
            else
                if not regionShapesMatch(expectedShape, testShape) then return false end
            end
        end
    end

    return true
end

return checkPuzzleBoard