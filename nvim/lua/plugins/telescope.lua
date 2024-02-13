local Util = require("lazyvim.util")

-- https://github.com/nvim-telescope/telescope.nvim/issues/2014#issuecomment-1873547633
vim.api.nvim_create_autocmd("FileType", {
  pattern = "TelescopeResults",
  callback = function(ctx)
    vim.api.nvim_buf_call(ctx.buf, function()
      vim.fn.matchadd("TelescopeParent", "\t\t.*$")
      vim.api.nvim_set_hl(0, "TelescopeParent", { link = "Comment" })
    end)
  end,
})

-- https://github.com/nvim-telescope/telescope.nvim/issues/2014#issuecomment-1873547633
local function filename_first(_, path)
  local tail = vim.fs.basename(path)
  local parent = vim.fs.dirname(path)
  if parent == "." then
    return tail
  end
  return string.format("%s\t\t%s", tail, parent)
end

return {
  "nvim-telescope/telescope.nvim",
  opts = {
    defaults = {
      path_display = filename_first,
      dynamic_preview_title = true,
      layout_config = {
        width = 0.9,
        preview_width = 0.4,
      },
    },
    pickers = {
      find_files = {
        hidden = true,
      },
    },
  },
  keys = {
    { "<leader>/", false }, -- disable the keymap to grep files (we use the same mapping elsewhere)
    {
      "<C-p>",
      Util.telescope("files"),
      desc = "Find Files (root dir)",
    },
  },
}
