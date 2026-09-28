local syncify = require("devtools.co.syncify")
local ensure_in_coroutine = require("devtools.co.ensure_in_coroutine")
local Counter = require("devtools.async.counter")

describe("syncify", function()
    -- TODO! should syncify just be about callback only? was there another purpose (i.e. did I originally mash up ensure_in_coroutine+syncify into one func? if so then strip syncify to the bear minimum just to support sync looking callback (assume in coroutine/thread when its used, throw if not)

    describe("reproduce double resume", function()
        it("due to sync callback", function()
            -- FYI double ensure_in_coroutine (ensure_in_coroutine in ensure_in_coroutine) doesn't matter for this bug
            -- FYI error is only visible in logs right now given async nature
            --   TODO make test fail on double resume
            ensure_in_coroutine(function()
                local result1, result2, result3 = syncify(function(cb)
                    -- vim.schedule(function()
                    cb(3, 4, 5)
                    -- end)
                end)
                assert.equal(3, result1)
                assert.equal(4, result2)
                assert.equal(5, result3)
            end)
        end)
    end)

    it("syncify returns multiple args unpacked", function()
        ensure_in_coroutine(function()
            local result1, result2, result3 = syncify(function(cb)
                vim.schedule(function()
                    cb(3, 4, 5)
                end)
            end)
            assert.equal(3, result1)
            assert.equal(4, result2)
            assert.equal(5, result3)
        end)
    end)

    -- FYI! syncify scenarios are not fully covered
    it("sync, immediate callbacks work", function()
        -- YES!!! we have the warning here! this is what I wanted to reproduce!
        --   WARNING - callback invoked resume before yielded, allowing resume
        ensure_in_coroutine(function()
            local counter = Counter:new()
            counter:increment()
            syncify(function(cb)
                -- no async, immediately calls cb (synchornously)
                counter:decrement()
                cb()
            end)
            counter:wait() -- wait at end of test! careful if doing it earlier in test b/c event loop runs still (scheduled events fire while your code blocks)
        end)
    end)


    describe("works with vim.defer_fn", function()
        stop_after_this("fails if resume would be called when coroutine is not suspeneded...", function()
            ensure_in_coroutine(function()
                local co, ismain = coroutine.running()
                syncify(function(cb)
                    vim.schedule(function()
                        -- without vim.wait, this scheduled event would fire AFTER coroutine.yield is called... but b/c of wait, this fires before!
                        --  why? b/c wait delays calling yield, meanwhile wait doesn't block event loop ... so, vim.scheduled events continue to fire! including this one
                        assert.equal(coroutine.status(co), "normal") -- if you drop vim.wait below then this will be suspended instead
                        -- FYI this test case is to prove we hit our edge case scenario, it is a bit indirect but nonetheless important to test in advance (not to leave it uncertain b/c the assertion is insufficient)
                        cb()
                    end)
                    vim.wait(10) -- intentional vim.wait inside the syncify's call_this so yield isn't called before attempt to call resume
                end)
            end)
        end)

        it("syncify completes and returns value", function()
            ensure_in_coroutine(function()
                local counter = Counter:new()
                counter:increment()
                local result = syncify(function(cb)
                    vim.schedule(function()
                        counter:decrement()
                        cb(3)
                    end)
                    -- DO NOT vim.wait in here... that will cause havoc b/c the scheduled resume will fire before yield
                end)
                assert.equal(3, result)
                counter:wait(100) -- using vim.wait was a TERRIBLE idea... the event loop continues to run (like a coroutine itself where wait is like yield) and so scheduled callbacks like your resume... fuck it will run before vim.wait completes which means you haven't yielded yet!)
            end)
        end)
        it("syncify twice completes and returns value", function()
            ensure_in_coroutine(function()
                local counter = Counter:new()
                counter:increment()
                counter:increment()
                -- TODO test of hs.doAfter?
                local does_schedule = function(cb, what_result)
                    vim.schedule(function()
                        counter:decrement()
                        cb(what_result)
                    end)
                    -- DO NOT vim.wait in here... that will cause havoc b/c the scheduled resume will fire before yield
                end
                local result = syncify(does_schedule, 3)
                assert.equal(3, result)
                result = syncify(does_schedule, 13)
                assert.equal(13, result)
                counter:wait(100)
            end)
        end)
        it("counter timeout", function()
            -- TODO do I want this test too?
            --  my inclination was to add it to make sure it fails too
            --  but it does overlap with other Counter timeout above so long term maybe nuke if not needed
            --  TODO review syncify/ensure_in_coroutine and make sure you understand if this test is needed, keep it for now
            assert.has_error(function()
                local counter = Counter:new()
                counter:increment()
                ensure_in_coroutine(function()
                    syncify(function(cb)
                        vim.schedule(function()
                            -- counter:decrement() -- this is the difference vs test above
                            cb()
                        end)
                    end)
                end)
                counter:wait(100)
            end, "Counter not done after 100 ms (count=1 should be 0)")
        end)
    end)
end)
