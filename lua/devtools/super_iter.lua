-- FYI! this is a very early idea, might scrap this... we shall see...
--  basically leaving this as a placeholder to revisit for later

function super_iter(original_table)
    local iter = vim.iter(original_table)

    iter.tolist = function(self)
        -- vim.iter:totable() results in a list only if the underlying table is array like..
        --  so use tolist to make one regardless
        if self == nil then
            error("nil passed to super_iter's tolist(), are you using .tolist() when you need to use :tolist()?")
        end
        local result = {}
        for _, v in pairs(self:totable()) do
            table.insert(result, v)
        end
        return result
    end

    iter.sort = function(self, cmp_fn)
        local sorted = self:tolist()
        table.sort(sorted, cmp_fn)
        -- retain super_iter interface:
        return super_iter(sorted)
    end

    return iter
end

return super_iter
