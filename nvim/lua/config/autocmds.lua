-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- When existing files are opened in another way than from Neotree (e.g. using Telescope), close Neotree
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
  callback = function()
    vim.cmd("Neotree close")
  end,
})
