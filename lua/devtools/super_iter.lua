-- FYI! this is a very early idea, might scrap this... we shall see...
--  basically leaving this as a placeholder to revisit for later

function super_iter(t)
    local iter = vim.iter(t)

    iter.tolist = function(self)
        -- vim.iter:totable() results in a list only if the underlying table is array like..
        --  so use tolist to make one regardless
        if self == nil then
            error("cannot call super_iter.tolist() on nil, not possible currently")
        end
        local result = {}
        for _, v in pairs(self:totable()) do
            table.insert(result, v)
        end
        return result
    end

    return iter
end

return super_iter
