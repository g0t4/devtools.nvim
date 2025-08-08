local histogram = require('devtools.diff.histogram')
local should = require('devtools.tests.should')
local combined = require('devtools.diff.combined')
local _describe = require('devtools.tests._describe')

-- TODO revisit this idea in devtools.tests and find a clean way to handle this
--  perhaps add your own _it and _only? and override clear registraiton on an _only? and then on the only replace _it() func with nothing after that point...?
-- FYI some logic to limit which tests run w/o changing it on all of them:
function ignore(a, b)
end

only = it
-- it = ignore  -- uncomment to run "only" tests, otherwise, comment out to run all again (regardless if marked only/it)

_describe('simple comparison', function()
    local before_text = [[
local M = {}
function M.add(a, b )
    return a + b
end
return M]]

    -- FYI first new line doesn't result in a line in diff
    --  but trailing new line after return N does add a blank line
    local after_text = [[
local M = {}
function M.add(a, b, c, d)
    return a + b
end
return N
]]
    only('validate histogram alone', function()
        local diffs = histogram.split_then_diff_lines(before_text, after_text)

        -- pretty_print(diffs)

        -- FYI I wanted 2+ alternating groups of same/diff lines
        local expected = {
            { '=', 'local M = {}' },
            { '-', 'function M.add(a, b )' },
            { '+', 'function M.add(a, b, c, d)' },
            { '=', '    return a + b' },
            { '=', 'end' },
            { '-', 'return M' },
            -- two consecutive added lines, should be diff'd with single - above
            { '+', 'return N' },
            { '+', '' },
        }

        should.be_same(expected, diffs)
    end)

    it('follows histogram with a 2nd pass, word-level LCS', function()
        local histogram_line_diff = histogram.split_then_diff_lines(before_text, after_text)
        local diffs = combined.step2_lcs_diffs(histogram_line_diff)

        -- pretty_print(diffs)

        -- Notes:
        -- - I wanted 2+ alternating groups of same vs del/add LCS lines
        -- - part of the reason I kept =/+/- is so I can track the implicit vs explicit new lines
        -- - don't forget for LCS, whitesapce is treated as a word too!
        local expected_groups = {

            -- STEP1/2 Histogram Anchors
            -- FYI implicit new lines
            {
                { '=', 'local M = {}' }
            }, -- implicit \n

            -- STEP2 LCS input:
            -- FYI implicit new lines:
            -- { "-", "function M.add(a, b )" }, -- implicit \n
            -- { "+", "function M.add(a, b, c, d)" }, -- implicit \n
            --
            -- STEP2 LCS output:
            -- FYI explicit new lines
            {
                { 'same', 'function M.add(a, ' },
                { 'del',  'b' },
                { 'add',  'b, c,' },
                { 'same', ' ' },
                { 'del',  ')' },
                { 'add',  'd)' },
                { 'same', '\n' },
            },

            -- STEP1/2 Histogram Anchors
            -- FYI implicit new lines
            {
                { '=', '    return a + b' }, -- implicit \n
                { '=', 'end' },
            }, -- implicit \n

            -- STEP2 LCS input:
            -- FYI implicit new lines:
            -- { "-", "return M" },
            -- { "+", "return N" },
            -- { "+", "" },
            --
            -- STEP2 LCS output:
            -- FYI explicit new lines
            {
                { 'same', 'return ' },
                { 'del',  'M\n' },
                { 'add',  'N\n\n' },
            },
        }

        should.be_same(expected_groups, diffs)
    end)


    it("step 3 is a final aggregate (across '='/'same') and standardize to '+/-/=' for final results", function()
        local combined_diff = combined.combined_diff(before_text, after_text)


        -- Notes:
        -- - I wanted 2+ alternating groups of same vs del/add LCS lines
        -- - part of the reason I kept =/+/- is so I can track the implicit vs explicit new lines
        -- - don't forget for LCS, whitesapce is treated as a word too!
        local expected_groups = {

            -- STEP1/2 Histogram Anchors
            -- FYI made remaining "=" newlines explicit
            -- flatten across groups
            -- combine consecutive "="/"same" into single record
            { '=', 'local M = {}\nfunction M.add(a, ' },
            { '-', 'b' },
            { '+', 'b, c,' },
            { '=', ' ' },
            { '-', ')' },
            { '+', 'd)' },
            { '=', '\n    return a + b\nend\nreturn ' },
            { '-', 'M\n' },
            { '+', 'N\n\n' },
        }

        should.be_same(expected_groups, combined_diff)
    end)
end)

_describe('simple comparison', function()
    local before_text = [[
function M.add(a, b )
    return a + b
end]]

    local after_text = [[
function M.add(a, b, c, d)
    return a + b
end]]

    it('validate histogram alone', function()
        local diffs = histogram.split_then_diff_lines(before_text, after_text)

        -- pretty_print(diffs)

        local expected = {
            { '-', 'function M.add(a, b )' },
            { '+', 'function M.add(a, b, c, d)' },
            { '=', '    return a + b' },
            { '=', 'end' },
        }

        should.be_same(expected, diffs)
    end)
end)


it("combined should allow passing new word level split w/ char by char separators too", function()
    it("test rename with dot notation", function()
        local before_rename_text = [[
local pps = math.floor(sse.timings.predicted_per_second * 10 + 0.5) / 10
print("tokens/sec", pps, "predicted_n", sse.timings.predicted_n)
log:info("Tokens/sec: ", pps, " predicted n: ", sse.timings.predicted_n)]]

        local after_rename_text = [[
local pps = math.floor(sse_parsed.timings.predicted_per_second * 10 + 0.5) / 10
print("tokens/sec", pps, "predicted_n", sse_parsed.timings.predicted_n)
log:info("Tokens/sec: ", pps, " predicted n: ", sse_parsed.timings.predicted_n)]]

        local combined_diff = combined.combined_word_diff(before_rename_text, after_rename_text)

        local expected_groups = {

            -- line one
            { '=', 'local pps = math.floor(sse' },
            { '+', '_parsed' },
            { '=', '.timings.predicted_per_second * 10 + 0.5) / 10\nprint("tokens/sec", pps, "predicted_n", sse' },
            { '+', '_parsed' },
            { '=', '.timings.predicted_n)\nlog:info("Tokens/sec: ", pps, " predicted n: ", sse' },
            { '+', '_parsed' },
            { '=', '.timings.predicted_n)\n' },
        }

        should.be_same(expected_groups, combined_diff)
    end)
end)
