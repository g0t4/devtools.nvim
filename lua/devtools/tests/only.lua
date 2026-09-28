local function NOOP() end

local original_it = it
-- define multiple one or more tests to ONLY run a subset
--   ignore tests defined with `it`
--   FYI by definition, you must call only() at least once to skip other tests
local function only(desc, func)
    original_it(desc, func)

    -- if we mark a single test as only run this => then we want to disable (skip) all other tests not defined with only...
    --   IOTW it => NOOP
    it = NOOP
end

return only
