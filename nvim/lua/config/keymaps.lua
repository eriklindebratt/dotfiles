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

vim.keymap.del("n", "<c-_>") -- remove binding to open floating terminal
vim.keymap.del("n", "<c-/>") -- remove binding to open floating terminal

vim.keymap.set("n", "<leader>/", ":noh<CR>") -- remove search highlights

-- reveal current file in Finder
vim.api.nvim_create_user_command("Rfinder", function()
  local path = vim.api.nvim_buf_get_name(0)
  os.execute("open -R " .. path)
end, {})

vim.keymap.set("n", "<leader>gb", function()
  local current_git_branch = vim.fn.system("git branch | grep -E '^\\* ' | cut -d '*' -f 2 | xargs echo")
  vim.notify(current_git_branch, "info", { title = "Current Git branch", timeout = 6000 })
end, { desc = "Show current Git branch" })
