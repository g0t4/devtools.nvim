--- devtools.notify
---
--- A deliberately simple notification module.
---
--- Notifications are shown as a plain box in the top-right corner of the
--- editor and disappear on their own after a timeout. No animations, no
--- window management tricks, no "features". Just a message you can read and
--- a box that goes away.
---
--- Usage:
---   local notify = require("devtools.notify")
---   notify.info("Model is loaded", { title = "AskAgentCheckModel", timeout = 5000 })
---   notify.notify("boom", vim.log.levels.ERROR, { title = "Oops" })

local M = {}

local config = {
    timeout_ms = 5000,   -- default time a notification stays up
    border = "single",   -- border style: "single" | "rounded" | "none"
    margin_top = 1,      -- rows from the top of the editor
    margin_right = 1,    -- cols from the right edge of the editor
    gap = 1,             -- rows between stacked notifications
    max_width = 100,     -- hard cap on notification width
}

--- Default border color per log level. These are just readable defaults,
--- override per-call with opts.fg.
local LEVEL_COLORS = {
    [vim.log.levels.ERROR] = "#FF5555",
    [vim.log.levels.WARN]  = "#FFCC66",
    [vim.log.levels.INFO]  = "#66CCFF",
    [vim.log.levels.DEBUG] = "#888888",
}

-- Active notifications, in display order (top-first). Used for stacking.
local active = {}

---@class NotifyOptions
---@field title? string          @bold title shown on the first line
---@field timeout? number        @ms before the notification auto-dismisses (0 = sticky)
---@field fg? string             @hex color for the border and title
---@field border? string         @override the default border style

local Notification = {}
Notification.__index = Notification

---@param msg string
---@param level vim.log.levels
---@param opts? NotifyOptions
---@return Notification
function Notification:new(msg, level, opts)
    local self = setmetatable({}, Notification)
    self.msg = tostring(msg)
    self.level = level
    self.opts = opts or {}
    self.timeout = self.opts.timeout ~= nil and self.opts.timeout or config.timeout_ms
    self._dismissed = false
    self._timer_id = nil

    self.bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[self.bufnr].modifiable = true

    local lines = {}
    if self.opts.title and self.opts.title ~= "" then
        table.insert(lines, self.opts.title)
    end
    for _, line in ipairs(vim.split(self.msg, "\n")) do
        table.insert(lines, line)
    end
    vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines)
    vim.bo[self.bufnr].modifiable = false
    vim.bo[self.bufnr].bufhidden = "wipe"

    -- width = widest line + 2 for the border sides
    self.width = self:_compute_width(lines)
    self.height = #lines + 2 -- + top/bottom border

    self.border = self.opts.border or config.border
    local border_hl = self:_make_highlight()
    local title_hl = self:_make_title_highlight()

    -- title extmark (bold + colored), if we have a title
    if self.opts.title and self.opts.title ~= "" then
        vim.api.nvim_buf_set_extmark(self.bufnr, title_hl.ns, 0, 0, {
            hl_group = title_hl.group,
            hl_eol = true,
            end_row = 0,
            end_col = -1,
        })
    end

    self.win_id = vim.api.nvim_open_win(self.bufnr, false, {
        relative = "editor",
        style = "minimal",
        border = self.border,
        width = self.width,
        height = self.height,
        row = config.margin_top,
        col = 0,
        focusable = false,
        noautocmd = true,
    })
    vim.api.nvim_win_set_option(self.win_id, "winhighlight", "Normal:Normal,FloatBorder:" .. border_hl)

    -- stack newest on top
    table.insert(active, 1, self)
    self:_layout()

    self:_start_timer()
    return self
end

function Notification:_compute_width(lines)
    local widest = 0
    for _, line in ipairs(lines) do
        local w = vim.fn.strdisplaywidth(line)
        if w > widest then widest = w end
    end
    return math.min(widest + 2, config.max_width)
end

function Notification:_make_highlight()
    local color = self.opts.fg or LEVEL_COLORS[self.level] or LEVEL_COLORS[vim.log.levels.INFO]
    -- unique group per notification so they don't clobber each other
    local group = "DevtoolsNotifyBorder" .. self.bufnr
    vim.api.nvim_set_hl(0, group, { fg = color, default = true })
    return group
end

function Notification:_make_title_highlight()
    local color = self.opts.fg or LEVEL_COLORS[self.level] or LEVEL_COLORS[vim.log.levels.INFO]
    local group = "DevtoolsNotifyTitle" .. self.bufnr
    vim.api.nvim_set_hl(0, group, { fg = color, bold = true, default = true })
    return { ns = vim.api.nvim_create_namespace("devtools.notify.title"), group = group }
end

-- Recompute row/col for every active notification so they stack from the
-- top-right corner downward, newest first.
function Notification:_layout()
    local row = config.margin_top
    for _, n in ipairs(active) do
        if vim.api.nvim_win_is_valid(n.win_id) then
            vim.api.nvim_win_set_config(n.win_id, {
                relative = "editor",
                row = row,
                col = math.max(vim.o.columns - n.width - config.margin_right, 0),
            })
        end
        row = row + n.height + config.gap
    end
end

function Notification:_start_timer()
    if self.timeout and self.timeout > 0 then
        self._timer_id = vim.fn.timer_start(self.timeout, function()
            self:dismiss()
        end)
    end
end

---Close the notification and remove it from the stack.
function Notification:dismiss()
    if self._dismissed then return end
    self._dismissed = true

    if self._timer_id then
        vim.fn.timer_stop(self._timer_id)
        self._timer_id = nil
    end
    if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
        vim.api.nvim_win_close(self.win_id, true)
    end
    self.win_id = nil

    for i, n in ipairs(active) do
        if n == self then
            table.remove(active, i)
            break
        end
    end
    self:_layout()
end

---@param opts? {timeout_ms?: number, border?: string, margin_top?: number, margin_right?: number, gap?: number, max_width?: number}
function M.setup(opts)
    opts = opts or {}
    config.timeout_ms = opts.timeout_ms or config.timeout_ms
    config.border = opts.border or config.border
    config.margin_top = opts.margin_top or config.margin_top
    config.margin_right = opts.margin_right or config.margin_right
    config.gap = opts.gap or config.gap
    config.max_width = opts.max_width or config.max_width
end

---Dismiss all currently visible notifications.
function M.dismiss_all()
    -- iterate a snapshot so dismiss() removing from `active` doesn't skip items
    local pending = {}
    for _, n in ipairs(active) do
        table.insert(pending, n)
    end
    for _, n in ipairs(pending) do
        n:dismiss()
    end
end

---@param msg string
---@param level vim.log.levels
---@param opts? NotifyOptions
---@return Notification
function M.notify(msg, level, opts)
    level = level or vim.log.levels.INFO
    return Notification:new(msg, level, opts)
end

---@param msg string
---@param opts? NotifyOptions
---@return Notification
function M.info(msg, opts)
    return M.notify(msg, vim.log.levels.INFO, opts)
end

---@param msg string
---@param opts? NotifyOptions
---@return Notification
function M.warn(msg, opts)
    return M.notify(msg, vim.log.levels.WARN, opts)
end

---@param msg string
---@param opts? NotifyOptions
---@return Notification
function M.error(msg, opts)
    return M.notify(msg, vim.log.levels.ERROR, opts)
end

return M
