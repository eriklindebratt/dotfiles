return {
  {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function()
      require("package-info").setup({
        package_manager = "pnpm", -- fallback to use one can't be resolved based on manifest/lockfile
        hide_up_to_date = true,
        icons = {
          style = {
            up_to_date = "  ",
            outdated = " 󰜸 ",
          },
        },
      })
    end,
  },
}
