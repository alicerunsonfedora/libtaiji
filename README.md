# 🏁 libtaiji

A simple Taiji library written in Lua

**libtaiji** is a small, simple Lua library that lets you parse and check
puzzles from the style/mechanics of [Taiji](https://taiji-game.com) by
Matthew VanDevander. libtaiji is also the basis for the Playdate game
_What the Taiji?!_.

## Getting started

**Requirements**  
- Lua 5.1 or later
- [Labyrinth](htps://github.com/alicerunsonfedora/labyrinth)

You can either clone this repository with `git clone` or download the
latest tarball package. Copy the `libtaiji` directory to your library
folder in your Lua project.

> **Note**  
> For those using this library with a Playdate game, you will need to
> add [pd-require](https://github.com/DimitriBarronmore/pd-require)
> and import it into your `main.lua` file.

## Usage documentation

> **Warning**  
> This documentation is still a work in progress. Most functions should
> provide documentation comments with type hints compatible with LuaLS.

### Parser

To parse a Taiji puzzle code, call the parser function:

```lua
local parse <const> = require("libtaiji.parser")

local puzzle = parse("1:Tw0", function (_, _, _, _, _)
    return {}
end)
```

The parser takes two arguments:

- `code` (string): The Taiji puzzle code to parse into a puzzle board.
- `generateRenderData` (function): The function that will generate render
  data for the puzzle board. It should return a table of data back, and it
  provides the following parameters: `filled` (boolean), `state` (tile
  state), `symbol` (symbol or nil), `value` (number or nil), and `color`
  (color). The table can contain any data and can have any structure
  suitable for your use case, as this will be attached to each tile on the
  board.

### Checker

To check that a puzzle's board meets all its constraints, call the
checker function:

```lua
local checker <const> = require("libtaiji.checker")

local ok = checker(puzzle)
```

If the constraints have been satified, the checker will return true.

> **Note**  
> At this time, the checker does not support checking for color mechanics.
> This will be added in a later revision behind an optional flag.

## License

libtaiji is licensed under the MIT License. You can learn more by reading
