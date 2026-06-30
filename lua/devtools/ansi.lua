local M = {}

-- TODO switch to using 8-bit color (256 colors)
-- https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit

local color_keys = {

    -- foreground colors
    black             = 30,
    red               = 31,
    green             = 32,
    yellow            = 33,
    blue              = 34,
    magenta           = 35,
    cyan              = 36,
    white             = 37,

    -- background colors
    black_bg          = 40,
    red_bg            = 41,
    green_bg          = 42,
    yellow_bg         = 43,
    blue_bg           = 44,
    magenta_bg        = 45,
    cyan_bg           = 46,
    white_bg          = 47,

    -- bright fg colors:
    bright_black      = 90,
    bright_red        = 91,
    bright_green      = 92,
    bright_yellow     = 93,
    bright_blue       = 94,
    bright_magenta    = 95,
    bright_cyan       = 96,
    bright_white      = 97,

    -- bright bg colors:
    bright_black_bg   = 100,
    bright_red_bg     = 101,
    bright_green_bg   = 102,
    bright_yellow_bg  = 103,
    bright_blue_bg    = 104,
    bright_magenta_bg = 105,
    bright_cyan_bg    = 106,
    bright_white_bg   = 107,



    -- misc
    reset     = 0,
    bold      = 1,
    dim       = 2,
    underline = 4,
    blink     = 5,
    reverse   = 7,
    hidden    = 8,


    -- SGR (Select Graphic Rendition) codes
    --   SGR is formatted with CSI, for example:
    --     \27[nm
    --   CSI n m
    --   `m` is the CSI char that indicates SGR
    --   `n` is the SGR parameter (SGR code)
    --       SGR table: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR
    --       sometimes n is followed by futher parameters
    --       i.e. n=38;5;n (for 8-bit color, 256 values)
    --         or n=38;2;r;g;b (for 24-bit color)
    --            use 48 (instead of 38) for background colors
    --
    -- Escape (ASCII 1B) is the "[I]ntroducer" in CSI (Control Sequence Introducer)
    --   \27[ comes before CSI parameters, in lua
    --   \27 in lua strings, where \ is your escape char
    --   AFAICT lua doesn't have a hex code variant so you have to use decimal \ddd (up to 3 digits)
    --

}

function M.clear(n)
    -- CSI n J
    --   ED (Erase in Display)
    n = n or 3
    return "\27[" .. n .. "J"
end

-- TODO rewrite this to cover all colors... and be reusable.
-- Try using your new AI tools to do this (zed predicts too)

function M.color(text, codes, options)
    -- TODO do I really use this options.color anywhere? if not let's nuke it ... can always add some global toggle if I truly need no color... seems like I only use this in inspect.inspect() and I am not sure I've really used that anywhere at this point
    --    rg -g '*.lua' 'require\(.devtools.inspect'
    --    rg -g '*.lua' inspect\.inspect
    --
    --  find ansi methods that include a comma within parens of func call:
    --    rg -g '*.lua' "\bansi.\w+\([^)]+,"
    --
    -- first step is to use M.color and a few other helpers to simplify where I even touch options
    --  then I can nuke them later
    options = options or {}
    options.color = options.color or true
    if not options.color then
        return text
    end

    local code_str = type(codes) == "table" and table.concat(codes, ";") or tostring(codes)

    return "\27[" .. code_str .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
end

function M.black(text, options)
    return M.color(text, color_keys.black, options)
end

function M.cyan(text, options)
    return M.color(text, color_keys.cyan, options)
end

function M.cyan_bold(text, options)
    return M.color(text, {color_keys.bold, color_keys.cyan}, options)
end

function M.underline(text, options)
    return M.color(text, color_keys.underline, options)
end

function M.bold(text, options)
    return M.color(text, color_keys.bold, options)
end

function M.dim(text, options)
    return M.color(text, color_keys.dim, options)
end

function M.red_bold(text, options)
    return M.color(text, {color_keys.bold, color_keys.red}, options)
end

function M.red(text, options)
    return M.color(text, color_keys.red, options)
end

function M.blue(text, options)
    return M.color(text, color_keys.blue, options)
end

function M.blue_bold(text, options)
    return M.color(text, {color_keys.bold, color_keys.blue}, options)
end

function M.magenta(text, options)
    return M.color(text, color_keys.magenta, options)
end

function M.magenta_bold(text, options)
    return M.color(text, {color_keys.bold, color_keys.magenta}, options)
end

function M.green(text, options)
    return M.color(text, color_keys.green, options)
end

function M.yellow_bold(text, options)
    return M.color(text, {color_keys.bold, color_keys.yellow}, options)
end

function M.yellow(text, options)
    return M.color(text, color_keys.yellow, options)
end

function M.black_bold(text, options)
    return M.color(text, {color_keys.bold, color_keys.black}, options)
end

function M.white_bold(text, options)
    return M.color(text, {color_keys.bold, color_keys.white}, options)
end

function M.white(text, options)
    return M.color(text, color_keys.white, options)
end

function M.black_bg(text, options)
    return M.color(text, color_keys.black_bg, options)
end

function M.red_bg(text, options)
    return M.color(text, color_keys.red_bg, options)
end

function M.blue_bg(text, options)
    return M.color(text, color_keys.blue_bg, options)
end

function M.magenta_bg(text, options)
    return M.color(text, color_keys.magenta_bg, options)
end

function M.green_bg(text, options)
    return M.color(text, color_keys.green_bg, options)
end

function M.green_bold(text, options)
    return M.color(text, {color_keys.bold, color_keys.green}, options)
end

function M.yellow_bg(text, options)
    return M.color(text, color_keys.yellow_bg, options)
end

function M.cyan_bg(text, options)
    return M.color(text, color_keys.cyan_bg, options)
end

function M.white_bg(text, options)
    return M.color(text, color_keys.white_bg, options)
end

function M.show_colors()
    local text = ''
    local i = 0
    for k, v in pairs(color_keys) do
        if type(v) == "number" then
            i = i + 1
            if i % 8 == 0 then
                text = text .. "\27[" .. v .. "m" .. k .. "\27[0m\n"
            else
                text = text .. "\27[" .. v .. "m" .. k .. "\27[0m "
            end
        end
    end
    return text
end

-- * apple colors (https://developer.apple.com/design/human-interface-guidelines/color#macOS-system-colors)
--  like what I did with my log_ fish function
-- FYI apple has some color schemes that I like and recall so I can use these for some variation instead of just M.my_yellow
function M.apple_yellow(text, options)
    local apple_yellow = "ffd60a"
    return M.rgb_hex(text, apple_yellow, options)
end
function M.apple_pink(text, options)
    local apple_pink = "ff375f"
    return M.rgb_hex(text, apple_pink, options)
end

function M.rgb_hex(text, hex, options)
    options = options or {}
    options.color = options.color ~= false
    if not options.color then
        return text
    end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not (r and g and b) then
        return text
    end
    return "\27[38;2;" .. r .. ";" .. g .. ";" .. b .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
end

function M.rgb(text, r, g, b, options)
    options = options or {}
    options.color = options.color ~= false
    if not options.color then
        return text
    end
    if not (r and g and b) then
        return text
    end
    return "\27[38;2;" .. r .. ";" .. g .. ";" .. b .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
end

return M
