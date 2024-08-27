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

-- package-info.nvim
-- Toggle version status info
local wk = require("which-key")
wk.add({
  buffer = true,
  { "<leader>cp", group = "package info" },
})
vim.keymap.set(
  { "n" },
  "<leader>cpp",
  require("package-info").toggle,
  { silent = true, noremap = true, desc = "Toggle version status" }
)
-- Update dependency on current line
vim.keymap.set(
  { "n" },
  "<leader>cpu",
  require("package-info").update,
  { silent = true, noremap = true, desc = "Update dependency" }
)
-- Delete/uninstall dependency on current line
vim.keymap.set(
  { "n" },
  "<leader>cpd",
  require("package-info").delete,
  { silent = true, noremap = true, desc = "Delete/uninstall dependency" }
)
-- Add new dependency
vim.keymap.set(
  { "n" },
  "<leader>cpa",
  require("package-info").install,
  { silent = true, noremap = true, desc = "Add new dependency" }
)
-- Install different version of dependency on current line
vim.keymap.set(
  { "n" },
  "<leader>cpc",
  require("package-info").change_version,
  { silent = true, noremap = true, desc = "Change dependency version" }
)
