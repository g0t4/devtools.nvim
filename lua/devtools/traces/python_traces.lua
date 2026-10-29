local log = require("devtools.logs.logger"):universal()

local M = {}

--- Detect whether text looks like a python traceback.
--- Matches the standard python frame format:
---     File "/path/to/file.py", line 94, in _run
--- as well as the xonsh/rich-pretty "Unhandled exception in event loop:" header that prefixes
--- frames of the same shape. The marker is deliberately the per-frame `File ... line N, in ...`
--- line rather than the header, so we don't need to know which header/format produced it.
---@param text string
---@return boolean
function M.is_python_trace(text)
    return text:find('File ".*", line %d+, in ') ~= nil
end

---Parse a python traceback (incl. xonsh's "Unhandled exception in event loop:" header) into
---quickfix list items.
---Only per-frame `File ...` lines are turned into items; the source-code lines and
---python 3.14 expression-location indicators (`~~~~~~^^^^`) that follow them are skipped.
---@param trace string
---@return table[] -- quickfix items: { filename, lnum, col, text }
function M.parse_trace_for_quickfix(trace)
    local items = {}
    for line in vim.gsplit(trace, "\n", { plain = true }) do
        --   File "/path/to/file.py", line 94, in _run
        local filename, lnum, func = line:match('^%s*File "([^"]+)", line (%d+), in (%S+)')
        if filename then
            table.insert(items, {
                filename = filename,
                lnum = tonumber(lnum),
                col = 0,
                text = func,
            })
        end
    end
    log:debug("Parsed python quickfix items:", items)
    return items
end

---Python tracebacks do not truncate paths like lua's error() does (no `...` prefix), so there is
---nothing to resolve. Keep the API consistent with the lua module.
---@param path string
---@return string
function M.resolve_truncated_path(path)
    return path
end

---Parse a python traceback and return items ready to load into the quickfix list.
---@param trace string
---@return table[]
function M.to_quickfix_items(trace)
    return M.parse_trace_for_quickfix(trace)
end

return M
