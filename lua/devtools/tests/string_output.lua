-- *** STRINGS
--   FYI (monkey patch for a readable API)
--   alternative:
--     expect(prompt):starts_with(START) ... basically wrap the string with a new type that has the new "methods"
--   why? because ORDER MATTERS for both:
--     READABILITY
--     and *COMPARISON*
--
--   consider:
--     assert.starts_with(prompt, token) ...
--     assert.starts_with(token, prompt) ... which comes first MATTERS for both READABILITY and the COMPARISON!
--     ... which order is right? have to look at docs to figure it out! Or, try to follow an _arbitrary_ convention

---@class StringOutput
---@field private _str string
local StringOutput = {}
StringOutput.str = function(value) return StringOutput.new(value) end

---@param value any
function StringOutput.new(value)
    return setmetatable({
        _str = value
    }, { __index = StringOutput })
end

---@param self StringOutput
---@param expected_prefix string
function StringOutput:should_start_with(expected_prefix)
    local actual_prefix = self._str:sub(1, #expected_prefix)
    if actual_prefix == expected_prefix then return end

    error(string.format("expected string %q… to start with %q", actual_prefix, expected_prefix))
end

---@param self StringOutput
---@param expected_suffix string
function StringOutput:should_end_with(expected_suffix)
    if expected_suffix == "" then return end

    local actual_suffix = self._str:sub(- #expected_suffix)
    if actual_suffix == expected_suffix then return end

    error(string.format("expected string %q… to end with %q", actual_suffix, expected_suffix))
end

---@param self StringOutput
---@param expected_substring string
function StringOutput:should_contain(expected_substring)
    if self._str:find(expected_substring, 1, true) then return end

    local diff_message = combined.combined_word_diff(self._str, expected_substring)
    print("diff:\n" .. inspect_diff(diff_message))

    error(string.format("expected string %q to contain %q", self._str, expected_substring))
end

return StringOutput
