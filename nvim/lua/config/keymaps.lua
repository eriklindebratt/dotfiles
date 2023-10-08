-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Fix common typos
vim.cmd([[
  cnoreabbrev Wq wq
  cnoreabbrev Wa wa
  cnoreabbrev wQ wq
  cnoreabbrev WQ wq
  cnoreabbrev W w
  cnoreabbrev Q q
  cnoreabbrev Qa qa
  cnoreabbrev W! w!
  cnoreabbrev Q! q!
  cnoreabbrev Qa! qa!
  cnoreabbrev Noh noh
]])

-- Move selected lines up or down by one line:
--   1. Move one line up/down
--   2. Re-select selection
--   3. Indent
--   4. Re-select selection
vim.keymap.set("v", "<C-k>", ":move '<-2<CR>gv=gv")
vim.keymap.set("v", "<C-j>", ":move '>+1<CR>gv=gv")

vim.keymap.set("n", "<leader>/", ":noh<CR>") -- remove search highlights
