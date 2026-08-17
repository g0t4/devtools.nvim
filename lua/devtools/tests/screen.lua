--- devtools.tests.screen
---
--- Reconstruct the current (possibly headless) editor "screen" as text.
---
--- Headless nvim never renders to a terminal, so we can't take a real
--- screenshot. Instead we rebuild what the user WOULD see by reading each
--- window's position, border, buffer contents, plus the tabline, statuslines,
--- and cmdline, into a character grid.
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
    solid = { tl = "█", tr = "█", bl = "█", br = "█", h = "█", v = "█" },
    none = nil,
}

---@return string[][] grid rows of cells (each cell is a single char or " ")
local function make_grid(cols, rows)
    local grid = {}
    for _ = 1, rows do
        local row = {}
        for _ = 1, cols do
            -- cells must be spaces, not "", so empty areas contribute padding
            -- when the row is concatenated (screenshot must show real layout)
            table.insert(row, " ")
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

---Draw a run of text into a grid row, starting at a column. Cells past the end
---of the text keep their space padding (this is a screenshot, not a buffer).
---@param grid string[][]
---@param row integer
---@param col integer
---@param text string
---@param width integer
local function draw_row_text(grid, row, col, text, width)
    for i = 1, width do
        local ch = string.sub(text, i, i)
        if ch ~= "" then
            set_cell(grid, row, col + i - 1, ch)
        end
    end
end

---Map a border spec (a style string, an 8-char array, or "none") to the
---{h,v,tl,tr,br,bl} chars used for drawing.
---@param border string|string[]
---@return table|nil
local function border_chars_for(border)
    if type(border) == "table" then
        -- nvim border array order: {top-left, top, top-right, right,
        -- bottom-right, bottom, bottom-left, left}
        return {
            h  = border[2],
            v  = border[4],
            tl = border[1],
            tr = border[3],
            br = border[5],
            bl = border[7],
        }
    end
    return BORDER_CHARS[border]
end

---Draw a bordered rectangle into the grid.
---@param grid string[][]
---@param row integer top row (1-indexed)
---@param col integer left col (1-indexed)
---@param width integer
---@param height integer
---@param chars table
local function draw_border(grid, row, col, width, height, chars)
    -- top/bottom edges
    for i = 0, width - 1 do
        set_cell(grid, row, col + i, chars.h)
        set_cell(grid, row + height - 1, col + i, chars.h)
    end
    -- corners
    set_cell(grid, row, col, chars.tl)
    set_cell(grid, row, col + width - 1, chars.tr)
    set_cell(grid, row + height - 1, col, chars.bl)
    set_cell(grid, row + height - 1, col + width - 1, chars.br)
    -- left/right edges
    for j = 1, height - 2 do
        set_cell(grid, row + j, col, chars.v)
        set_cell(grid, row + j, col + width - 1, chars.v)
    end
end

---Draw a buffer's lines into a grid rectangle (clipped to the rect).
---@param grid string[][]
---@param bufnr integer
---@param top_row integer
---@param left_col integer
---@param height integer
---@param width integer
local function draw_buffer_lines(grid, bufnr, top_row, left_col, height, width)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
    for j = 1, math.min(height, #lines) do
        local line = lines[j]
        for i = 1, math.min(width, #line) do
            set_cell(grid, top_row + j - 1, left_col + i - 1, string.sub(line, i, i))
        end
    end
end

---Draw a window (border, winbar, content, statusline) into the grid.
---@param grid string[][]
---@param win_id number
---@param show_statusline boolean whether to draw a per-window statusline
local function draw_window(grid, win_id, show_statusline)
    local cfg = vim.api.nvim_win_get_config(win_id)
    local bufnr = vim.api.nvim_win_get_buf(win_id)

    local is_float = cfg.relative and cfg.relative ~= ""

    if is_float then
        -- float windows expose row/col/width/height directly in config, and
        -- those dimensions INCLUDE the border, so content lives inside it.
        local row = (cfg.row or 0) + 1   -- 1-indexed
        local col = (cfg.col or 0) + 1
        local width = cfg.width or 0
        local height = cfg.height or 0

        local chars = border_chars_for(cfg.border)
        if chars then
            draw_border(grid, row, col, width, height, chars)
            row = row + 1
            col = col + 1
            height = height - 2
            width = width - 2
        end
        draw_buffer_lines(grid, bufnr, row, col, height, width)
        return
    end

    -- regular windows compute their geometry from the layout, so query it.
    -- nvim reports the CONTENT area (the border, if any, wraps OUTSIDE it).
    local pos = vim.api.nvim_win_get_position(win_id)
    local pos_row = pos[1] + 1
    local pos_col = pos[2] + 1
    local height = vim.api.nvim_win_get_height(win_id)
    local width = vim.api.nvim_win_get_width(win_id)

    -- a winbar occupies the window's top row and nvim_win_get_height includes
    -- it, so the content is one row shorter and starts one row lower.
    local has_winbar = vim.o.winbar ~= ""
    local content_top = pos_row + (has_winbar and 1 or 0)
    local content_height = height - (has_winbar and 1 or 0)

    -- the (global) winborder wraps the content area
    local chars = border_chars_for(vim.o.winborder)
    if chars then
        draw_border(grid, content_top, pos_col, width, content_height, chars)
    end

    -- winbar text at the window's top row
    if has_winbar then
        local wb = vim.api.nvim_eval_statusline(vim.o.winbar, { winid = win_id, maxwidth = width }).str
        draw_row_text(grid, pos_row, pos_col, wb, width)
    end

    -- buffer content
    draw_buffer_lines(grid, bufnr, content_top, pos_col, content_height, width)

    -- a per-window statusline sits on the row right below the window
    if show_statusline then
        local sl = vim.api.nvim_eval_statusline(vim.o.statusline, { winid = win_id, maxwidth = width }).str
        draw_row_text(grid, pos_row + height, pos_col, sl, width)
    end
end

---Whether the tabline is currently shown (showtabline=2 always, 1 only with
---more than one tabpage, 0 never).
---@return boolean
local function tabline_visible()
    local showtabline = vim.o.showtabline
    if showtabline == 0 then
        return false
    end
    if showtabline == 2 then
        return true
    end
    return vim.fn.tabpagenr("$") > 1
end

---Whether per-window statuslines should be drawn.
---@param win_count integer
---@return boolean
local function should_show_per_window_statusline(win_count)
    local laststatus = vim.o.laststatus
    if laststatus == 3 then
        return false -- a single global statusline is drawn instead
    end
    if laststatus == 0 then
        return false
    end
    if laststatus == 2 then
        return true
    end
    return win_count > 1 -- laststatus == 1
end

--- Helper to dump screen w/ boundaries
---@param title? string
function M.dump_bounded(title)
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

    -- tabline at the very top (row 1)
    if tabline_visible() then
        local tab = vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true, maxwidth = cols }).str
        draw_row_text(grid, 1, 1, tab, cols)
    end

    -- separate regular windows from floats; floats draw last (z-order)
    local floats = {}
    local regular = {}
    for _, win_id in ipairs(vim.api.nvim_list_wins()) do
        local cfg = vim.api.nvim_win_get_config(win_id)
        if cfg.relative and cfg.relative ~= "" then
            table.insert(floats, win_id)
        else
            table.insert(regular, win_id)
        end
    end

    local show_statusline = should_show_per_window_statusline(#regular + #floats)
    for _, win_id in ipairs(regular) do
        draw_window(grid, win_id, show_statusline)
    end

    -- a single global statusline (laststatus=3) spans the bottom of the
    -- window area, just above the cmdline
    if vim.o.laststatus == 3 then
        local sl = vim.api.nvim_eval_statusline(vim.o.statusline, { maxwidth = cols }).str
        draw_row_text(grid, rows - vim.o.cmdheight, 1, sl, cols)
    end

    -- cmdline at the bottom; when a command is being typed show its prompt+text
    local cmdtype = vim.fn.getcmdtype()
    if cmdtype ~= "" then
        draw_row_text(grid, rows, 1, cmdtype .. vim.fn.getcmdline(), cols)
    end

    -- floats draw last so they appear on top (matches z-order)
    for _, win_id in ipairs(floats) do
        draw_window(grid, win_id, false)
    end

    local out = {}
    for _, row in ipairs(grid) do
        -- keep trailing spaces: this is a screenshot, so the blank padding
        -- between windows must be preserved to show real layout
        table.insert(out, table.concat(row))
    end
    return table.concat(out, "\n")
end

---Render the screen and print it to the message area.
function M.show()
    print(M.dump())
end

return M
