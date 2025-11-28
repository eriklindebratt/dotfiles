return {
  "nvim-neotest/neotest",
  dependencies = { "nvim-neotest/nvim-nio", "marilari88/neotest-vitest" },
  opts = {
    -- Can be a list of adapters like what neotest expects,
    -- or a list of adapter names,
    -- or a table of adapter names, mapped to adapter configs.
    -- The adapter will then be automatically loaded with the config.
    adapters = {
      ["neotest-vitest"] = {
        -- dap_go_enabled = true,
      },
    },
  },
}
