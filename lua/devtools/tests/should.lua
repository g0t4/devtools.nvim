local assert = require('luassert')
local combined = require('devtools.diff.combined')
local ansi = require('devtools.ansi')

local M = {}

function M.be_greater_than(expected, actual)
    error("move to expect, or just assert(x>y)... this was a terrible idea")
    local is_greater_than = actual > expected
    assert.is_true(is_greater_than)
end

function M.be_equal(expected, actual)
    assert.are.equal(expected, actual)
end

function M.be_same(expected, actual)
    assert.are.same(expected, actual)
end

--- show a diff if they're not the same by vim.inspecting each input and then diff that (great for table values)
function M.be_same_diff(expected, actual)
    xpcall(function()
        assert.are.same(expected, actual)
    end, function(err)
        print(vim.inspect(err))

        expected_text = vim.inspect(expected)
        actual_text = vim.inspect(actual)

        local diff = combined.combined_word_diff(expected_text, actual_text)
        -- inspect_diff looks GREAT in plenary's float window test results!
        print("diff:\n" .. inspect_diff(diff))
    end)
end

-- show test diffs in a console/log with ansi color sequnces!
function inspect_diff(diff)
    -- TODO can I update this for the new code based word splitter? what was that
    local lines = {}
    for _, v in ipairs(diff) do
        local type = v[1]
        local text = v[2]
        if type == "+" then
            text = ansi.green(text)
        elseif type == '-' then
            text = ansi.red(text)
        else
            text = ansi.white(text)
        end
        type = ansi.black(ansi.white_bg(type))
        local line = type .. " " .. text
        table.insert(lines, line)
    end
    return table.concat(lines, "\n")
end

function M.be_nil(actual)
    -- FYI you can join with _ instead of dot (.)
    --   must use this for keywords like nil, function, etc
    assert.is_nil(actual)
end

function expect(truthy)
    -- TODO should this be a module? leave it global for now?
    -- SPIKE an idea for a new expect that can make it easier to understand what went wrong... think of reverse engineering the test code that triggered this
    --   first off I can just print the expect call's source line
    --    later I could analyze it as an expression and replace vars w/ values  (if useful)
    if truthy then
        return
    end

    -- PRN also print other lines? maybe detect what called what... can help if I have assertion helpers for reuse
    local calling_frame = debug.getinfo(2, "Sln")
    -- vim.print(tb)

    local is_a_file = calling_frame.source:match("^@")
    if not is_a_file then
        print("Not Implemented... source is not a file, for the code that called expect, cannot find its source line")
        return
    end

    local source = calling_frame.source:gsub("^@", "")
    local lines = vim.fn.readfile(source)
    local line = lines[calling_frame.currentline]
    -- vim.print("expect failed:", line)

    -- use \n so explanation stands out (much like builtin string comparison passedin/actual)
    -- error("\nassertion failed:\n" .. line)

    -- Collect local variables from the calling frame
    local locals = {}
    local num_locals = 1
    while true do
        -- print("locals[" .. num_locals .. "]=" .. tostring(debug.getlocal(2, num_locals)))
        local name, value = debug.getlocal(2, num_locals)
        if not name then break end
        locals[name] = tostring(value)
        num_locals = num_locals + 1
    end

    if num_locals == 1 then
        error("\nassertion failed:\n  Source: " .. line)
        return
    end

    -- Substitute local variable names with their values in the line
    local substituted_line = line
    for name, value in pairs(locals) do
        -- Simple pattern: replace whole word matches of the variable name
        substituted_line = substituted_line:gsub("%f[%w]" .. name .. "%f[%W]", value)
    end

    error("\nassertion failed:\n  Source: " .. line .. "\n  Values: " .. substituted_line)
end

return M
