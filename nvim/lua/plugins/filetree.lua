return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    -- opts will be merged with the parent spec
    opts = {
      event_handlers = {
        {
          event = "file_opened",
          handler = function()
            require("neo-tree.command").execute({ action = "close" })
          end,
        },
      },
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
        },

        -- This will use the OS level file watchers to detect changes
        -- instead of relying on nvim autocmd events.
        use_libuv_file_watcher = true,

        window = {
          mappings = {
            ["o"] = "open",
          },
        },
      },
      buffers = {
        window = {
          mappings = {
            ["o"] = "open",
          },
        },
      },
    },
    -- Give `init` an empty function, disabling the default behavior of
    -- Neo-tree opening up when Neovim opened with a directory as argument
    init = function() end,
  },
}
