--- @class Tile A representation of a Taiji grid tile.
--- @field filled boolean Whether this tile is filled in.
--- @field state TileState The tile's interactive state.
--- @field symbol Symbol? The symbol type on the
--- @field symbolValue number? The value of the symbol.
--- @field symbolColor Color? The symbol's color, if one has been applied.
--- @field renderData table? A table used to render puzzles to the screen (varies by project).

--- @class Puzzle A representation of a Taiji puzzle.
--- @field width number The width of the board.
--- @field tiles table<unknown, Tile> The tiles on the board.
--- @field mechanics number A bit-masked number representing what mechanics are present.

local models = {
    --- @enum Symbol
    Symbol = {
        kDiamond = 1,
        kFlower = 2,
        kDotPositive = 3,
        kDotNegative = 4,
        kDash = 5,
        kSlash = 6
    },

    SymbolBitmask = {
        Flower = 1,
        Slashdash = 2,
        Diamond = 4,
        Dots = 8
    },

    --- @enum TileState
    TileState = {
        kNormal = 1,
        kFixed = 2,
        kInvisible = 3
    },

    --- @enum Color
    Color = {
        red = "RED",
        orange = "ORANGE",
        yellow = "YELLOW",
        green = "GREEN",
        blue = "BLUE",
        purple = "PURPLE",
        black = "BLACK",
        white = "WHITE"
    }
}
return models