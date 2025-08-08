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
    local position, text_length = 1, #text

    while position <= text_length do
        local char = text:sub(position, position)
        if not char:match(separator_pattern) then
            local word_start = position
            while position <= text_length and not text:sub(position, position):match(separator_pattern) do
                -- skip over characters (non separators) until we hit a separator (or end of text)
                position = position + 1
            end
            -- print('a: "' .. char .. '"' .. 'position=' .. position .. ' text_len=' .. text_length)
            -- insert the word:
            table.insert(parts, text:sub(word_start, position - 1))
        else
            -- print('b: "' .. char .. '"')
            if not skip_separator then
                -- insert separator
                table.insert(parts, char)
            end
            position = position + 1
        end
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
    --
    -- FYI goal is to use %W or [^%w] (not word char) after examples covered
    return split_internal(text, "%W", KEEP_SEPARATORS)
    -- return split_internal(text, "[._%s+*-/=\"\']", KEEP_SEPARATORS)
end

return M
