return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        -- When Vim is opened from a directory, netrw will be opened.
        -- Setting `replace_netrw = false` will ensure that the Snacks filetree
        -- is _not_ opened when NeoVim is opened from a directory.
        replace_netrw = false,
      },
      picker = {
        sources = {
          explorer = {
            hidden = true, -- show hidden files
            ignored = true, -- show files ignored by VCS
            win = {
              list = {
                keys = {
                  ["<c-t>"] = { "edit_tab", mode = { "i", "n" } }, -- default keybinding is to open terminal, remap to open in new tab
                  ["<c-c>"] = false,
                },
              },
            },
          },
        },
      },
    },
  },
}
