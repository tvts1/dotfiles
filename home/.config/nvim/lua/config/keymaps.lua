-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Familiar IDE shortcuts. Leader-based alternatives from LazyVim continue to
-- work and are shown by WhichKey.
map({ "n", "i", "x" }, "<C-s>", "<cmd>write<cr><esc>", { desc = "Save File" })
map("n", "<M-CR>", vim.lsp.buf.code_action, { desc = "Code Action" })
map("x", "<M-CR>", vim.lsp.buf.code_action, { desc = "Code Action" })
map("n", "<S-F6>", vim.lsp.buf.rename, { desc = "Rename Symbol" })
