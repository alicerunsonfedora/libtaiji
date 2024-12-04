local collections = require("labyrinth.collections")
local models = require("libtaiji.models")
local strutils = require("labyrinth.strutils")

local map = collections.map
local joined = strutils.joined

local TS = models.TileState
local Sym = models.Symbol
local Color = models.Color

local strf = string.format

--- @enum EncoderState
local EncoderState = {
    kWaitForInstruction = 1,
    kSpanTileArray = 2,
    kIndividualTile = 3,
    kTileAttributes = 4,
    kError = 99
}

local parserData = {
    dotsPositive = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'},
    dotsNegative = {'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R'},
    diamond = 'S',
    slash = 'U',
    dash = 'T',
    flowers = {'V', 'W', 'X', 'Y', 'Z'},
    specialDigits = {'0', '2', '4', '6', '8'},
    digits = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'},
    fillEmpty = '+',
    fillFixed = '-',
    fillChars = {
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L',
        'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'X', 'Y', 'Z'
    },
    colors = {'r', 'o', 'y', 'g', 'b', 'p', 'w', 'k'},
    extendedAttributes = {'0', '2', '4', '6', '8'}
}

local colorMapping = {
    [Color.red] = "r",
    [Color.orange] = "o",
    [Color.yellow] = "y",
    [Color.green] = "g",
    [Color.blue] = "b",
    [Color.purple] = "p",
    [Color.black] = "w",
    [Color.white] = "k"
}

--- @param tile Tile
--- @return string code
local function makeTileCode(tile)
    local color = colorMapping[tile.symbolColor] or ""
    local bgState = "0"
    if tile.state == TS.kNormal then
        bgState = tile.filled and "2" or "0"
    elseif tile.state == TS.kFixed then
        bgState = tile.filled and "6" or "4"
    else
        bgState = "8"
    end

    local fgState = ""
    if tile.symbol == Sym.kFlower then
        fgState = parserData.flowers[tile.symbolValue + 1]
    elseif tile.symbol == Sym.kDotPositive then
        fgState = parserData.dotsPositive[tile.symbolValue]
    elseif tile.symbol == Sym.kDotNegative then
        fgState = parserData.dotsNegative[tile.symbolValue]
    elseif tile.symbol == Sym.kDiamond then
        fgState = parserData.diamond
    elseif tile.symbol == Sym.kSlash then
        fgState = parserData.slash
    elseif tile.symbol == Sym.kDash then
        fgState = parserData.dash
    end
    return joined({ fgState, color, bgState }, "")
end

--- Encodes a Taiji puzzle board into a standard puzzle code.
--- @param pzl Puzzle The puzzle to encode into a string.
--- @return string code The standard puzzle code that represents the puzzle board.
local function encodePuzzle(pzl)
    local pzlCode = strf("%d:", pzl.width)

    -- Pass one: generate individual tiles
    local tileCodes = map(pzl.tiles, makeTileCode)

    -- Pass two: compress empty and invisible tiles
    local isInvisible = false
    local fillArrayCount = 0

    for i=1, #tileCodes do
        local tileCode = tileCodes[i]
        if tileCode ~= "0" and tileCode ~= "8" then
            if fillArrayCount > 0 then
                local fillChar = parserData.fillChars[fillArrayCount]
                local typeChar = isInvisible and "-" or "+"
                local fillStr = typeChar .. fillChar
                if fillChar == "A" then
                    fillStr = isInvisible and "8" or "0"
                end
                pzlCode = pzlCode .. fillStr
                fillArrayCount = 0
            end
            pzlCode = pzlCode .. tileCode
        else
            if fillArrayCount < 1 then
                fillArrayCount = 1
            else
                fillArrayCount = fillArrayCount + 1
            end
        end
    end

    -- Capture this at the end if this didn't get cleaned up for some reason
    if fillArrayCount > 0 then
        local fillChar = parserData.fillChars[fillArrayCount]
        local typeChar = isInvisible and "-" or "+"
        pzlCode = pzlCode .. typeChar .. fillChar
        fillArrayCount = 0
    end
    return pzlCode
end

return encodePuzzle