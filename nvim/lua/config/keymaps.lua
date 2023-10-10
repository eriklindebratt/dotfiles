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

vim.keymap.set("n", "<leader>/", ":noh<CR>") -- remove search highlights
