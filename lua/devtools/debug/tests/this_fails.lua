local M = {}

function M.failsauce()
    error("failsauce")
end

function M.xpcall_nil()
    xpcall(nil, nil)
end

return M
