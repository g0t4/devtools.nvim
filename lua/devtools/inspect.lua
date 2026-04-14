local ansi = require("devtools.ansi")

local M = {}

--- Strip ANSI escape sequences from a string.
---@param text string
---@return string plain_text
---@return integer count
function M.strip_ansi_escape_sequences(text)
    -- \27 == 0x1B == ESC
    return text:gsub("\27%[.-m", "")
end

setmetatable(M, {
    __call = function(_, ...)
        -- since I've been using inspect as a primary global, this means I only have to import this module and the globals issue is fixed for inspect()
        -- when M() is called => inspect() in most consumers
        -- so most consumers can:
        --   local inspect = require("devtools.inspect")
        --   inspect(...)
        --   inspect.inspect(...) -- still works, though I could hide that
        --   inspect.print(...) -- etc, still works
        --
        return M.inspect(...)
    end,
    -- __index = function(_, key)
    --     -- resolve arbitrary key lookups
    --     return "you tried to access: " .. key
    -- end
})

local function tbl_is_list(tbl)
    if type(tbl) ~= "table" then
        return false
    end
    local previous_index = 0
    for index, _ in pairs(tbl) do
        if type(index) ~= "number" then
            return false
        end
        if index ~= previous_index + 1 then
            return false
        end
        previous_index = previous_index + 1
    end
    return true
end

--%%

-- TODO would be nice to get type hints to work on inspect() top level call too!
--   for now can do inspect.inspect() to get the type hints
--
---@param object any
---@param opts? {
---    color?: boolean,
---    pretty?: boolean,
---    pretty_down_to?: number,
---}
---@return string description
function M.inspect(object, opts, current_depth)
    opts = opts or {}
    opts.color = opts.color or true
    opts.pretty = opts.pretty or false -- migrate to opts for this
    opts.pretty_down_to = opts.pretty_down_to or 1 -- default only do pretty 1 level deep
    current_depth = current_depth or 0

    local max_depth = 5
    if current_depth > max_depth then
        print("pretty_print: max depth reached")
        return "..."
    end
    if object == nil then
        return ansi.black("nil", opts)
    elseif type(object) == 'table' then
        -- PRN check if all keys/indicies are integer and consecutive => if so, don't print indicies
        local is_list = tbl_is_list(object)
        local items = {}
        for key, value in pairs(object) do
            if is_list then
                table.insert(items, ansi.green(M.inspect(value, opts, current_depth + 1), opts))
            else
                if type(key) ~= 'number' then key = '"' .. key .. '"' end
                local item = '[' .. ansi.blue(key, opts) .. '] = ' .. ansi.green(M.inspect(value, opts, current_depth + 1), opts)
                table.insert(items, item)
            end
        end
        if #items == 0 then
            -- special case, also don't check this on object itself as it won't work on non-list tables
            return "{}"
        end
        if opts.pretty and current_depth <= opts.pretty_down_to then
            return "{\n" .. table.concat(items, ",\n") .. "\n}"
        end
        return "{ " .. table.concat(items, ", ") .. " }"
    elseif type(object) == "number" then
        return ansi.magenta(tostring(object), opts)
    elseif type(object) == "string" then
        local escaped = object:gsub('"', '\\"')
        return ansi.green('"' .. escaped .. '"', opts)
    else
        -- PRN udf?
        return tostring(object)
    end
end

--- generate a human readable lua representation of `value` and use bat for syntax highlighting
---@param value any - will be vim.inspect'd
function M.bat_inspect(value)
    local input = vim.inspect(value)
    return M.bat(input, "lua")
end

--- generate a human readable JSON representation of `value` and use bat for syntax highlighting
---@param value any - will be json encoded
function M.bat_json(value)
    local input = vim.fn.json_encode(value)
    return M.bat(input, "json")
end

--- syntax highlight text with bat
---@param text string
---@param language string
function M.bat(text, language)
    if type(text) ~= "string" then
        error("bat: input is expected to be a string, did you forget a vim.inspect or json.encode?")
    end
    local command_line = "bat --color always --language " .. language
    return vim.fn.system(command_line, text)
end

--- generate a human readable JSON representation of `value` and use jq for syntax highlighting + pretty print
---@param value any - will be json encoded
---@param compact? boolean # default false
---@return string
function M.jq_json(value, compact)
    local input = vim.fn.json_encode(value)
    return M.jq(input, compact)
end

---@param text string # JSON string to format
---@param compact? boolean # default false
---@return string
function M.jq(text, compact)
    if type(text) ~= "string" then
        error("jq: input is expected to be a string")
    end
    local command_line = "jq --color-output ."
    if compact then
        command_line = "jq -c --color-output ."
    end
    return vim.fn.system(command_line, text)
end

--- use this for a thorough search to find what it is
--- not at all performant for production, volume logging
--- used for debugging mostly
function M.wtf(object)
    return tostring(object)
end

function M.print(object, opts)
    print(M.inspect(object, opts))
end

function M.pretty_print(object)
    M.print(object, { pretty = true })
end

return M
