local Util = require("lazyvim.util")

return {
  "nvim-telescope/telescope.nvim",
  keys = {
    { "<leader>/", false }, -- disable the keymap to grep files (we use the same mapping elsewhere)
    { "<C-p>", Util.telescope("files"), desc = "Find Files (root dir)" },
  },
}
