return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = {
            hidden = true, -- show hidden files
          },
        },
      },
    },
    keys = {
      { "<c-p>", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
    },
  },
}
