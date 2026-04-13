local messages = require("devtools.messages")
local nvim = require("devtools.nvim")
local lua = require("devtools.lua")

local M = {}

function M.setup(opts)
    messages.setup(opts)
    nvim.setup()
    lua.setup()

    if opts.no_globals then
        return
    end

    -- I wouldn't add these globally except that it helps with completions in Dump/Run commands
    --   TODO long term I should augment just my two commands to have completions for the "globals" within those commands
    --      (see env_overrides in dump_command)
    --      for now, just hack the completions to work by providing these as globals in lua env everywhere
    --      FYI this is only intended for running one-off snippets with Dump/Run (maybe :=/:lua too) not to get rid of requires in modules in my neovim config
    _G.messages = messages
    _G.inspect = require("devtools.inspect")
    _G.append = messages.append
    _G.ansi = require('devtools.ansi')
    _G.bat_dump = messages.bat_dump
    _G.bat_inspect = inspect.bat_inspect
    --
    -- usages:
    --   :Run bat_dump({foo="bar"})
    --   :Dump bat_i<TAB_COMPLETE>
    --
    -- FYI two different ways to color/pretty print:
    --   :Dump inspect({foo="bar"})
    --   :Dump bat_inspect({foo="bar"})
end

return M
