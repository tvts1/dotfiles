-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Keep the default web/Lua indentation compact. Java overrides this to four
-- spaces in config/autocmds.lua.
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.shiftround = true

-- A visible IDE-like guide without forcing hard line wrapping.
vim.opt.colorcolumn = "120"
vim.opt.textwidth = 120
