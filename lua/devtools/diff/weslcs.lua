-- TODO re-implement algo that I devised on paper.. maybe wait until tomorrow to help ideas solidify
--
-- for now I understand how the other one works which is what I initially set out to do
--   even if I don't like how it works, it works and what it produces is all I care about
--   but I would like practice with LCS so I would like to revist it
--     probably will nag at me and make me do it tonight
local inspect = require('devtools.inspect')
local splitter = require('devtools.diff.splitter')

local M = {}

local zeros_until_set_row = {
    __index = function(table, key)
        -- only called if key/index doesn't already exist
        --   or was set to nil
        --
        --  lazy == defaults to zero on first use
        --  don't waste time/resources initializing table of zeros
        --  also useful:
        --    if don't know table size
        --      infinite size
        --    edge cases, when zero is a sufficient/desirable default
        --      instead of extra boundary checks, in code
        --      that said, magic is not free... YMMV
        --      can easily be more confusing, i.e. if you gravitate toward single letter variable names
        --
        -- umm not reason to set zero actually! just return it until someone else sets it to specific value!
        --   b/c setting it was fubaring prints too (added new row with sporadic set values ... yuck)
        -- table[key] = 0
        return 0
    end
}
function zeros_until_set_row:new()
    return setmetatable({}, zeros_until_set_row)
end

local zeros_until_set_matrix = {
    __index = function(table, row_index)
        -- named with only 2D in mind (row per old_token, col per new_token)
        -- __index only called on first use of table[row_index]
        -- or if table[row_index] was set to nil previously
        -- print("new row " .. row_index)

        local new_row = zeros_until_set_row:new()
        -- auto add the row
        table[row_index] = new_row
        return new_row
    end
}
function zeros_until_set_matrix:new()
    return setmetatable({}, zeros_until_set_matrix)
end

function M.get_longest_common_subsequence_matrix(before_tokens, after_tokens)
    local cum_matrix = zeros_until_set_matrix:new()
    for i, old_token in ipairs(before_tokens) do
        -- print(i .. " " .. old_token)
        for j, new_token in ipairs(after_tokens) do
            if old_token == new_token then
                -- increment sequence length (cumulative value) - up 1 row, left 1 column (NW direction)
                cum_matrix[i][j] = cum_matrix[i - 1][j - 1] + 1
            else
                -- max(cell above, cell to left)
                local left_cum = cum_matrix[i][j - 1]
                local up_cum = cum_matrix[i - 1][j]
                -- TODO ok now this feels like the right way to think about the algorithm...
                --  find a better name than left/up cumulative...
                --  what does each represent when taking the max
                --  * something about longest_sequence_so_far_in_[before|after]_tokens
                --     * longest_cum_so_far?
                --     copying that max (thus far) since this isn't a match (and therefore cannot increment it!)
                cum_matrix[i][j] = math.max(left_cum, up_cum)
            end
            -- print("  " .. j .. " - " .. cum_matrix[i][j])
        end
    end
    -- optional:
    cum_matrix[0] = nil -- wipe out first row, it's empty b/c just used to read zeros w/o boundary condition check on i = 1
    return cum_matrix
end

function walk_the_diff(before_tokens, after_tokens, visitor)
    local lcs_matrix = M.get_longest_common_subsequence_matrix(before_tokens, after_tokens)

    local num_remaining_before_tokens = #before_tokens
    local num_remaining_after_tokens = #after_tokens

    while num_remaining_before_tokens > 0 or num_remaining_after_tokens > 0 do
        local old_token = before_tokens[num_remaining_before_tokens]
        local new_token = after_tokens[num_remaining_after_tokens]
        -- print("old_token: '" .. tostring(old_token) .. "' - " .. num_remaining_before_tokens)
        -- print("new_token: '" .. tostring(new_token) .. "' - " .. num_remaining_after_tokens)

        -- * match?
        if old_token == new_token then
            visitor:on_match(old_token)
            -- move up and left, to previous token in both before/after token arrays
            num_remaining_before_tokens = num_remaining_before_tokens - 1 -- move up
            num_remaining_after_tokens = num_remaining_after_tokens - 1 -- move left
            goto continue_while
        end

        -- btw up/left first doesn't matter, best to be deterministic
        -- if you land on a non-matching (token) cell with longest_length == longest_above == longest_to_left,
        --    then you've got at least two longest sequences with a shared suffix
        --    pick either is fine, unless you have additional constraints beyond longest

        local current_longest_sequence_position = lcs_matrix[num_remaining_before_tokens][num_remaining_after_tokens]
        local longest_sequence_above = lcs_matrix[num_remaining_before_tokens - 1][num_remaining_after_tokens]
        local longest_sequence_left = lcs_matrix[num_remaining_before_tokens][num_remaining_after_tokens - 1]
        -- print("  longests:  " .. longest_sequence_above)
        -- print("           " .. longest_sequence_left .. "<" .. current_longest_sequence_position)

        -- ?? drop comparing current_longest_sequence_position to longest_above/below?? or not?
        -- - pick whichever is bigger (assuming it matches current/outstanding sequence length)
        -- - AND that has tokens left for that direction (i.e. toward upper left you can run into 0 for above/below and current when just have all adds or deletes remaining at start of sequence
        -- - and if they match, then pick up

        -- * move up?
        local any_before_tokens_remain = num_remaining_before_tokens > 0
        if any_before_tokens_remain and longest_sequence_above == current_longest_sequence_position then
            -- this means there's a match token somewhere above that is part of a longest sequence

            local deleted_token = before_tokens[num_remaining_before_tokens]
            visitor:on_delete(deleted_token)

            num_remaining_before_tokens = num_remaining_before_tokens - 1
            goto continue_while
        end

        -- * else, move left
        -- this means there's a match token somewhere to the left that is part of a longest sequence
        -- optional assertions (mirror the check for move up case)
        if longest_sequence_left ~= current_longest_sequence_position then
            error('UNEXPECTED... this suggests a bug in building/traversing LCS matrix... longest_to_left (' .. longest_sequence_left .. ')'
                .. ' should match logest_length (' .. current_longest_sequence_position .. ')'
                .. ', when longest_above (' .. longest_sequence_above .. ') does not!')
        end
        local any_after_tokens_remain = num_remaining_after_tokens > 0
        if not any_after_tokens_remain then
            -- this is only possible due to a bug, b/c base case happens when both longest_sequence_(above and left) are < 1
            error("UNEXPECTED... both before and after tokens appear fully traveresed and yet the base condition wasn't hit")
        end

        local added_token = after_tokens[num_remaining_after_tokens]
        visitor:on_add(added_token)

        num_remaining_after_tokens = num_remaining_after_tokens - 1

        ::continue_while::
    end
end

function M.get_longest_sequence(before_tokens, after_tokens)
    local builder = {
        longest_common_subsequence = {},
    }
    function builder:on_match(token)
        -- traverses in reverse, so insert token at start of list to ensure we get left to right sequence
        table.insert(self.longest_common_subsequence, 1, token)
        -- print("  same", token) -- PRN could be helpful to move this into a base builder class and include a toggle on/off
    end

    function builder:on_add(_token)
        -- print("  move left / add", _token)
    end

    function builder:on_delete(_token)
        -- print("  move up / del", _token)
    end

    walk_the_diff(before_tokens, after_tokens, builder)
    return builder.longest_common_subsequence
end

function M.get_token_diff(before_tokens, after_tokens)
    local builder = {
        token_diff = {},
    }
    function builder:push(change, token)
        local what = { change, token }
        -- traverses in reverse, so insert token at start of list to ensure we get left to right sequence
        table.insert(self.token_diff, 1, what)
        -- print("  ", inspect(what)) -- toggle to enable "tracing"?
    end

    function builder:on_match(token)
        self:push('same', token)
    end

    function builder:on_add(token)
        self:push('add', token)
    end

    function builder:on_delete(token)
        self:push('del', token)
    end

    walk_the_diff(before_tokens, after_tokens, builder)
    return builder.token_diff
end

function M.lcs_diff_from_text(before_text, after_text)
    local before_tokens = splitter.split_on_whitespace(before_text)
    local after_tokens  = splitter.split_on_whitespace(after_text)
    -- dump.append("before_tokens", inspect(before_tokens))
    -- dump.append("after_tokens", inspect(after_tokens))

    local diff          = M.lcs_diff_from_tokens(before_tokens, after_tokens)
    return diff
end

function M.lcs_diff_with_sign_types_from_text(before_text, after_text)
    local diff = M.lcs_diff_from_text(before_text, after_text)
    for _, change in pairs(diff) do
        change[1] = change[1] == 'add' and '+' or change[1] == 'del' and '-' or '=' or change[1]
    end
    return diff
end

function M.lcs_diff_from_tokens(before_tokens, after_tokens)
    -- WIP prefix/suffix strip
    local same_prefix, middle, same_suffix = M.split_common_prefix_and_suffix(before_tokens, after_tokens)
    -- FYI don't need middle b/c actually, I modify before_tokens and after_tokens in place!
    --   TODO make that obvious in testing and here

    -- * aggregate across token diff
    local token_diff = M.get_token_diff(before_tokens, after_tokens)

    local current_group = {}
    local merged = {}
    if same_prefix[2] ~= '' then
        table.insert(merged, same_prefix)
    end

    function merge_current_group()
        local function merge(type)
            if current_group[type .. 's'] then
                table.insert(merged, { type, vim.iter(current_group[type .. 's']):join('') })
            end
        end
        merge('same')
        merge('del')
        merge('add')

        current_group = {}
    end

    for _, current in pairs(token_diff) do
        -- print("current", inspect(current))
        local current_type = current[1] .. 's'
        local current_token = current[2]
        -- edge triggered on change to/from "same"
        if (current_group.sames and current_type ~= 'sames')
            or ((not current_group.sames) and current_type == 'sames') then
            merge_current_group()
        end

        current_group[current_type] = current_group[current_type] or {}
        table.insert(current_group[current_type], current_token)
        -- last_group looks one of:
        --   { adds={"foo", "bar"}, dels={"doo"} }, -- adds and/or dels
        --   { sames={"cow" " " "cobweb"} }, -- sames only (not combined w/ adds/dels)
    end
    merge_current_group()

    if same_suffix[2] ~= '' then
        table.insert(merged, same_suffix)
    end

    return merged
end

---@return table same_prefix, table middle, table same_suffix
function M.split_common_prefix_and_suffix(before_tokens, after_tokens)
    -- * shared suffix first, just removing from end of table
    local same_suffix = {}
    while #before_tokens > 0 and #after_tokens > 0
        and before_tokens[#before_tokens] == after_tokens[#after_tokens] do
        table.remove(after_tokens)
        table.insert(same_suffix, 1, table.remove(before_tokens))
    end

    local same_prefix = {}
    while #before_tokens > 0 and #after_tokens > 0
        and before_tokens[1] == after_tokens[1] do
        -- TODO is remove at start expensive b/c it has to renumber entire list every time? is this inevitable and is it inconsequential vs LCS diffing the shared prefix? (FYI could trim only shared suffix if need be)
        table.remove(after_tokens, 1)
        table.insert(same_prefix, table.remove(before_tokens, 1))
    end

    local middle = { before_tokens = before_tokens, after_tokens = after_tokens }

    -- TODO revisit what shape I want for output
    --  TODO what if no shared prefix/suffix... do I want { "same", "" } or nil?
    return
        { 'same', vim.iter(same_prefix):join('') },
        middle,
        { 'same', vim.iter(same_suffix):join('') }
end

function M.get_match_matrix(before_tokens, after_tokens)
    local match_matrix = zeros_until_set_matrix:new() -- just for fun, to illustrate naming differences
    for i, old_token in ipairs(before_tokens) do
        for j, new_token in ipairs(after_tokens) do
            if old_token == new_token then
                match_matrix[i][j] = old_token
            else
                match_matrix[i][j] = ' '
            end
        end
    end
    return match_matrix
end

return M
