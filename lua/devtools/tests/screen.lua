--- devtools.tests.screen
---
--- Reconstruct the current (possibly headless) editor "screen" as text.
---
--- Headless nvim never renders to a terminal, so we can't take a real
--- screenshot. Instead we rebuild what the user WOULD see by reading each
--- window's position, border, and buffer contents into a character grid.
---
--- This is the closest thing to a Selenium screenshot that works in
--- `nvim --headless` test runs. Handy for eyeballing UI state while
--- writing/verifying tests.

local M = {}

--- Single-line box drawing characters for each border style.
local BORDER_CHARS = {
    single = { tl = "+", tr = "+", bl = "+", br = "+", h = "-", v = "|" },
    rounded = { tl = "╭", tr = "╮", bl = "╰", br = "╯", h = "─", v = "│" },
    double = { tl = "╔", tr = "╗", bl = "╚", br = "╝", h = "═", v = "║" },
    none = nil,
}

---@return string[][] grid rows of cells (each cell is a single char or "")
local function make_grid(cols, rows)
    local grid = {}
    for _ = 1, rows do
        local row = {}
        for _ = 1, cols do
            table.insert(row, "")
        end
        table.insert(grid, row)
    end
    return grid
end

local function set_cell(grid, row, col, ch)
    local r = grid[row]
    if r and col >= 1 and col <= #r then
        r[col] = ch
    end
end

---Draw a window (border + content) into the grid.
---@param grid string[][]
---@param win_id number
local function draw_window(grid, win_id)
    local cfg = vim.api.nvim_win_get_config(win_id)
    local bufnr = vim.api.nvim_win_get_buf(win_id)

    local is_float = cfg.relative and cfg.relative ~= ""
    local row, col, width, height
    if is_float then
        -- float windows expose row/col/width/height directly in config
        row = (cfg.row or 0) + 1   -- 1-indexed
        col = (cfg.col or 0) + 1
        width = cfg.width or 0
        height = cfg.height or 0
    else
        -- regular windows compute their geometry from the layout, so query it
        -- nvim_win_get_position returns {row, col} (a single table)
        local pos = vim.api.nvim_win_get_position(win_id)
        row = pos[1] + 1
        col = pos[2] + 1
        width = vim.api.nvim_win_get_width(win_id)
        height = vim.api.nvim_win_get_height(win_id)
    end

    -- nvim returns border as a table of 8 chars (top, right, bottom, left,
    -- top-left, top-right, bottom-left, bottom-right) OR "none". Accept both.
    local border_chars
    if type(cfg.border) == "table" then
        -- nvim border table order: {top-left, top, top-right, right,
        -- bottom-right, bottom, bottom-left, left}
        border_chars = {
            h  = cfg.border[2], -- top / bottom horizontal edge
            v  = cfg.border[4], -- right / left vertical edge
            tl = cfg.border[1],
            tr = cfg.border[3],
            br = cfg.border[5],
            bl = cfg.border[7],
        }
    else
        border_chars = BORDER_CHARS[cfg.border]
    end
    if border_chars then
        -- top/bottom border
        for i = 0, width - 1 do
            set_cell(grid, row, col + i, border_chars.h)
            set_cell(grid, row + height - 1, col + i, border_chars.h)
        end
        set_cell(grid, row, col, border_chars.tl)
        set_cell(grid, row, col + width - 1, border_chars.tr)
        set_cell(grid, row + height - 1, col, border_chars.bl)
        set_cell(grid, row + height - 1, col + width - 1, border_chars.br)
        -- left/right borders
        for j = 1, height - 2 do
            set_cell(grid, row + j, col, border_chars.v)
            set_cell(grid, row + j, col + width - 1, border_chars.v)
        end
        -- content starts inside the border
        row = row + 1
        col = col + 1
        height = height - 2
        width = width - 2
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
    for j = 1, math.min(height, #lines) do
        local line = lines[j]
        for i = 1, math.min(width, #line) do
            set_cell(grid, row + j - 1, col + i - 1, string.sub(line, i, i))
        end
    end
end

--- Helper to dump screen w/ boundaries
---@param title? string
function M.dump_bounded(title)
    -- hrm... can't we just get borders around windows with buffers too?
    print("\n========== SCREEN DUMP @ " .. title .. " ==========")
    print(M.dump())
    print("==============================================")
end

---Render the current screen as a single string (newline separated rows).
---@return string
function M.dump()
    local cols = vim.o.columns
    local rows = vim.o.lines
    local grid = make_grid(cols, rows)

    -- draw non-floating windows first, then floats on top
    local floats = {}
    for _, win_id in ipairs(vim.api.nvim_list_wins()) do
        local cfg = vim.api.nvim_win_get_config(win_id)
        if cfg.relative and cfg.relative ~= "" then
            table.insert(floats, win_id)
        else
            draw_window(grid, win_id)
        end
    end
    -- floats draw last so they appear on top (matches z-order)
    for _, win_id in ipairs(floats) do
        draw_window(grid, win_id)
    end

    local out = {}
    for _, row in ipairs(grid) do
        -- trim trailing spaces so the dump is readable
        -- note: parens around gsub so only the 1st return (string) is used,
        -- otherwise gsub's 2nd return (count) leaks into table.insert
        table.insert(out, (table.concat(row):gsub("%s+$", "")))
    end
    return table.concat(out, "\n")
end

---Render the screen and print it to the message area.
function M.show()
    print(M.dump())
end

return M
