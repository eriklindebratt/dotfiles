return {
  {
    "LazyVim/LazyVim",
    opts = {
      -- Set colorscheme
      colorscheme = "tokyonight",
    },
  },

  -- Auto-switch background based on OS light/dark mode setting
  {
    "f-person/auto-dark-mode.nvim",
    config = {
      update_interval = 1000,
      set_dark_mode = function()
        vim.api.nvim_set_option("background", "dark")
      end,
      set_light_mode = function()
        vim.api.nvim_set_option("background", "light")
      end,
    },
  },
}
