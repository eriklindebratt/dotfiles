-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.clipboard = "" -- Don't merge default yank register with OS clipboard
vim.opt.listchars = "tab:▸ ,trail:·,nbsp:␣,extends:❯,precedes:❮"

-- LazyVim root dir detection
-- Each entry can be:
-- * the name of a detector function like `lsp` or `cwd`
-- * a pattern or array of patterns like `.git` or `lua`.
-- * a function with signature `function(buf) -> string|string[]`
-- vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
--
-- To disable root detection set to just "cwd".
-- This will prevent Neovim from auto-switching current working directory.
vim.g.root_spec = { "cwd" }

-- Disable Netrw by tricking Vim into thinking it's already loaded
vim.g.loaded_netrwPlugin = 1

-- Show deprecation warnings
vim.g.deprecation_warnings = true

-- Disable all animations
vim.g.snacks_animate = false

-- Require a Prettier config file for the Prettier formatter to be used
vim.g.lazyvim_prettier_needs_config = false
