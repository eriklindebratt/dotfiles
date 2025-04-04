-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd({ "BufEnter" }, {
  callback = function(ev)
    if vim.api.nvim_buf_is_valid(ev.buf) and vim.bo[ev.buf].buftype == "" then
      pcall(function()
        vim.cmd("TroubleRefresh")
      end)
    end
  end,
})
