return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      -- `lazyvim.plugins.extras.linting.eslint` doesn't seem to run on `.html` files
      -- even though docs for eslint lsp claim it should be enabled by default.
      -- Falling back to command-line linting for those for now.
      html = { "eslint" },

      css = { "stylelint" },
      scss = { "stylelint" },
      sass = { "stylelint" },
      less = { "stylelint" },

      sh = { "shellcheck" },
      bash = { "shellcheck" },
      zsh = { "shellcheck" },
      fish = { "shellcheck" },

      terraform = { "tflint" },
    },

    linters = {
      shellcheck = {
        cmd = "shellcheck",
        args = {
          "--format",
          "json",
          "-o",
          "all",
          "-",
        },
      },
    },
  },
}
