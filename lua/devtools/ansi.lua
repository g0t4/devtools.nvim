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
    bright    = 1,
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

-- TODO rewrite this to cover all colors... and be reusable.
-- Try using your new AI tools to do this (zed predicts too)

function M.color(text, color, options)
    options = options or {}
    options.color = options.color or true
    if not options.color then
        return text
    end
    return "\27[" .. color_keys[color] .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
end

function M.black(text, options)
    return M.color(text, 'black', options)
end

function M.cyan(text, options)
    return M.color(text, 'cyan', options)
end

-- TODO come back to this when I finish my AskRewrite code (accept is not fully finished)

function M.red_bold(text, options)
    options = options or {}
    options.color = options.color or true -- default is true
    if not options.color then
        return text
    end
    local bold_text =
        "\27[" .. color_keys.bright .. ";" .. color_keys.red .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
    return bold_text
end

function M.red(text, options)
    options = options or {}
    options.color = options.color or true -- default is true
    if not options.color then
        return text
    end
    return "\27[" .. color_keys.red .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
end

function M.blue(text, options)
    options = options or {}
    options.color = options.color or true -- default is true
    if not options.color then
        return text
    end
    return "\27[" .. color_keys.blue .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
end

function M.magenta(text, options)
    options = options or {}
    options.color = options.color or true -- default is true
    if not options.color then
        return text
    end
    return "\27[" .. color_keys.magenta .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
end

function M.green(text, options)
    options = options or {}
    options.color = options.color or true -- default is true
    if not options.color then
        return text
    end
    return "\27[" .. color_keys.green .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
end

function M.yellow_bold(text, options)
    options = options or {}
    options.color = options.color or true -- default is true
    if not options.color then
        return text
    end
    local bold_text =
        "\27[" .. color_keys.bright .. ";" .. color_keys.yellow .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
    return bold_text
end

function M.yellow(text, options)
    options = options or {}
    options.color = options.color or true -- default is true
    if not options.color then
        return text
    end
    return "\27[" .. color_keys.yellow .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
end

-- TODO later you can cleanup duplication

function M.black_bold(text, options)
    options = options or {}
    options.color = options.color or true -- default is true
    if not options.color then
        return text
    end
    local bold_text =
        "\27[" .. color_keys.bright .. ";" .. color_keys.black .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
    return bold_text
end

function M.white_bold(text, options)
    options = options or {}
    options.color = options.color or true -- default is true
    if not options.color then
        return text
    end
    local bold_text =
        "\27[" .. color_keys.bright .. ";" .. color_keys.white .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
    return bold_text
end

function M.white(text, options)
    return M.color(text, 'white', options)
end

function M.black_bg(text, options)
    options = options or {}
    options.color = options.color or true -- default is true
    if not options.color then
        return text
    end
    return "\27[" .. color_keys.black_bg .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
end

function M.red_bg(text, options)
    options = options or {}
    options.color = options.color or true -- default is true
    if not options.color then
        return text
    end
    return "\27[" .. color_keys.red_bg .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
end

function M.blue_bg(text, options)
    options = options or {}
    options.color = options.color or true -- default is true
    if not options.color then
        return text
    end
    return "\27[" .. color_keys.blue_bg .. "m" .. text .. "\27[" .. color_keys.reset .. "m"
end

function M.magenta_bg(text, options)
    return M.color(text, 'magenta_bg', options)
end

function M.green_bg(text, options)
    return M.color(text, 'green_bg', options)
end

function M.yellow_bg(text, options)
    return M.color(text, 'yellow_bg', options)
end

function M.cyan_bg(text, options)
    return M.color(text, 'cyan_bg', options)
end

function M.white_bg(text, options)
    return M.color(text, 'white_bg', options)
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

return M
