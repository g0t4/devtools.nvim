local M = {}
local SPLIT_ON_WHITESPACE = '%s+'
local STRIP_SEPARATORS = true
local KEEP_SEPARATORS = false


---@param text string
---@param separator_pattern string
---@param skip_separator boolean # don't include the sepator in the results.
---@return table<string>
local function split_internal(text, separator_pattern, skip_separator)
    if separator_pattern == nil or separator_pattern == '' then
        error('separator cannot be nil or empty string')
    end

    local parts = {}
    local start = 1
    local split_start, split_end = text:find(separator_pattern, start)
    while split_start do
        table.insert(parts, text:sub(start, split_start - 1))
        if not skip_separator then
            table.insert(parts, text:sub(split_start, split_end))
        end
        start = split_end + 1
        split_start, split_end = text:find(separator_pattern, start)
    end
    if text:sub(start) ~= '' then
        table.insert(parts, text:sub(start))
    end
    return parts
end

function M.split_on_whitespace_then_skip_the_whitespace(text)
    return split_internal(text, SPLIT_ON_WHITESPACE, STRIP_SEPARATORS)
end

function M.split_on_whitespace(text)
    return split_internal(text, SPLIT_ON_WHITESPACE, KEEP_SEPARATORS)
end

function M.split_code_into_words(text)
    -- goal here is to better split words in code to enhance diff comparisons
    --  i.e. if I have sse.choices[0].delta.content and I rename `sse` to `sse_parsed`
    --   then IMO you should only see `sse` as removed and `sse_parsed` added ...
    --   AND then once underscore is included, you should simply see `_parsed` as added!
    return split_internal(text, "[._%s+]", KEEP_SEPARATORS)
end

return M
