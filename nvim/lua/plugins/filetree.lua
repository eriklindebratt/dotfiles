return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        replace_netrw = false,
      },
      picker = {
        sources = {
          files = {
            hidden = true,
          },
          explorer = {
            hidden = true, -- show hidden files
            win = {
              list = {
                keys = {
                  ["<c-t>"] = { "edit_tab", mode = { "i", "n" } }, -- default keybinding is to open terminal, remap to open in new tab
                },
              },
            },
          },
        },
      },
    },
  },
}
