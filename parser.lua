local models = require("models")
local coll = require("labyrinth.collections")
local strutils = require("labyrinth.strutils")

local tcontains = coll.contains
local tindex = coll.firstIndex
local charAt = strutils.charAtIndex

local TileState = models.TileState
local Symbol = models.Symbol
local PBitmask = models.SymbolBitmask
local Color = models.Color

--- @enum ParseState
local ParseState = {
    kInitial = 0,
    kGetWidth = 1,
    kWaitForInstruction = 2,
    kPrefillEmpty = 3,
    kFillDotsPositive = 4,
    kFillDotsNegative = 5,
    kFillFlowers = 6,
    kFillSlashdash = 7,
    kFillDiamond = 8,
    kReadExtAttributes = 9,
    kPrefillFixed = 10,
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
    ["r"] = Color.red,
    ["o"] = Color.orange,
    ["y"] = Color.yellow,
    ["g"] = Color.green,
    ["b"] = Color.blue,
    ["p"] = Color.purple,
    ["w"] = Color.black,
    ["k"] = Color.white
}

local function luaver()
    local ver = { major = 5, minor = 0 }
    ver.major, ver.minor = string.match(_VERSION, "Lua (%d).(%d)")
    return ver
end

--- @alias RenderDataGenerator fun (filled: boolean, state: TileState, symbol: Symbol?, val: number?, color: Color?): table

--- @param code string
--- @param generateRenderData RenderDataGenerator 
--- @return Puzzle? puzzle
local function parse(code, generateRenderData)
    local s <const> = ParseState
    local d <const> = parserData
    local supportBitmask <const> = luaver().major >= 5 and luaver().minor >= 3

    local state = s.kInitial
    local rowWidth = { val = 0, str = "" }
    local filledSymbolicTile = false

    --- @type table<_, Tile>
    local tiles = {}
    local mechanics = 0

    --- @param i number
    local function lookahead(i)
        local nextChar = charAt(code, i + 1)
        state = tcontains(d.extendedAttributes, nextChar) and s.kReadExtAttributes or s.kWaitForInstruction
    end

    for i=1, #code do
        local char = charAt(code, i)
        if tcontains(d.digits, char) and (state == s.kInitial or state == s.kGetWidth) then
            rowWidth.str = rowWidth.str .. char
        elseif char == ":" and state == s.kGetWidth then
            local converted = tonumber(rowWidth.str)
            if converted == nil then
                return nil
            end
            rowWidth.val = converted
            state = s.kWaitForInstruction
        elseif char == d.fillEmpty and state == s.kWaitForInstruction then
            state = s.kPrefillEmpty
        elseif char == d.fillFixed and state == s.kWaitForInstruction then
            state = s.kPrefillFixed
        elseif state == s.kPrefillEmpty or state == s.kPrefillFixed then
            local fillIndex = tindex(d.fillChars, char)
            if fillIndex < 1 then
                return nil
            end
            if filledSymbolicTile then
                fillIndex = fillIndex - 1
            end
            local tState = state == s.kPrefillFixed and TileState.kFixed or TileState.kNormal
            for _=1, fillIndex do
                local rData = generateRenderData(false, tState, nil, 0)
                local tile = {
                    filled = false,
                    state = tState,
                    renderData = rData
                }
                tiles[#tiles + 1] = tile
            end
            state = s.kWaitForInstruction
            filledSymbolicTile = false
        elseif tcontains(d.dotsPositive, char) and state == s.kWaitForInstruction then
            state = s.kFillDotsPositive
            local index = tindex(d.dotsPositive, char)
            local rData = generateRenderData(false, TileState.kNormal, Symbol.kDotPositive, index)
            local tile = {
                filled = false,
                state = TileState.kNormal,
                symbol = Symbol.kDotPositive,
                symbolValue = index,
                renderData = rData
            }
            tiles[#tiles + 1] = tile
            lookahead(i)
            if supportBitmask then mechanics = mechanics | PBitmask.Dots end
            filledSymbolicTile = true
        elseif tcontains(d.dotsNegative, char) and state == s.kWaitForInstruction then
            state = s.kFillDotsNegative
            local index = tindex(d.dotsNegative, char)
            local rData = generateRenderData(false, TileState.kNormal, Symbol.kDotNegative, index)
            local tile = {
                filled = false,
                state = TileState.kNormal,
                symbol = Symbol.kDotNegative,
                symbolValue = index,
                renderData = rData
            }
            tiles[#tiles + 1] = tile
            lookahead(i)
            if supportBitmask then mechanics = mechanics | PBitmask.Dots end
            filledSymbolicTile = true
        elseif tcontains(d.flowers, char) and state == s.kWaitForInstruction then
            state = s.kFillFlowers
            local index = tindex(d.flowers, char) - 1
            local rData = generateRenderData(false, TileState.kNormal, Symbol.kFlower, index)
            local tile = {
                filled = false,
                state = TileState.kNormal,
                symbol = Symbol.kFlower,
                symbolValue = index,
                renderData = rData
            }
            tiles[#tiles + 1] = tile
            lookahead(i)
            if supportBitmask then mechanics = mechanics | PBitmask.Flowers end
            filledSymbolicTile = true
        elseif (char == d.dash or char == d.slash) and state == s.kWaitForInstruction then
            state = s.kFillSlashdash
            local symb = char == d.slash and Symbol.kSlash or Symbol.kDash
            local rData = generateRenderData(false, TileState.kNormal, symb)
            local tile = {
                filled = false,
                state = TileState.kNormal,
                symbol = symb,
                renderData = rData
            }
            tiles[#tiles + 1] = tile
            lookahead(i)
            if supportBitmask then mechanics = mechanics | PBitmask.Slashdash end
            filledSymbolicTile = true
        elseif char == d.diamond and state == s.kWaitForInstruction then
            state = s.kFillDiamond
            local rData = generateRenderData(false, TileState.kNormal, Symbol.kDiamond)
            local tile = {
                filled = false,
                state = TileState.kNormal,
                symbol = Symbol.kDiamond,
                renderData = rData
            }
            tiles[#tiles + 1] = tile
            lookahead(i)
            if supportBitmask then mechanics = mechanics | PBitmask.Diamond end
            filledSymbolicTile = true
        elseif tcontains(d.specialDigits, char) and state == s.kWaitForInstruction then
            local filled = false
            local tState = TileState.kNormal
            if char == '0' then
                filled = false
                tState = TileState.kNormal
            elseif char == '2' then
                filled = true
                tState = TileState.kNormal
            elseif char == '4' then
                filled = false
                tState = TileState.kFixed
            elseif char == '6' then
                filled = true
                tState = TileState.kFixed
            else
                filled = false
                tState = TileState.kInvisible
            end
            local rData = generateRenderData(filled, tState)
            local tile = {
                filled = filled,
                state = tState,
                renderData = rData
            }
            tiles[#tiles + 1] = tile
            filledSymbolicTile = false
        elseif tcontains(d.colors, char) and state == s.kWaitForInstruction then
            local lastTile = tiles[#tiles]
            local color = colorMapping[char]
            lastTile.symbolColor = color
            lastTile.renderData = generateRenderData(
                lastTile.filled,
                lastTile.state,
                lastTile.symbol,
                lastTile.symbolValue,
                color)
            tiles[#tiles] = lastTile
            lookahead(i)
        elseif state == s.kReadExtAttributes then
            local lastTile = tiles[#tiles]
            local filled = lastTile.filled
            local tState = lastTile.state
            if char == '0' then
                filled = false
                tState = TileState.kNormal
            elseif char == '2' then
                filled = true
                tState = TileState.kNormal
            elseif char == '4' then
                filled = false
                tState = TileState.kFixed
            elseif char == '6' then
                filled = true
                tState = TileState.kFixed
            else
                filled = false
                tState = TileState.kInvisible
            end
            local rData = generateRenderData(filled, tState, lastTile.symbol, lastTile.symbolValue)
            lastTile.filled = filled
            lastTile.state = tState
            lastTile.renderData = rData
            tiles[#tiles] = lastTile
            filledSymbolicTile = false
            state = s.kWaitForInstruction
        elseif state == s.kError then
            return nil
        end
    end
    return { width = rowWidth.val, tiles = tiles, mechanics = mechanics }
end

return parse