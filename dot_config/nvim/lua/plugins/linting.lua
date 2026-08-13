local js = require("util.js-tooling")

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
      -- `condition` is a LazyVim addition to nvim-lint. Without it these run
      -- everywhere: eslint would be started in projects that have no eslint,
      -- and stylelint exits 78 with a stack trace when it finds no config.
      -- A project that uses a tool installs it, so look for the executable
      -- rather than guessing at config file names.
      eslint = { condition = js.has_local_bin("eslint") },
      stylelint = { condition = js.has_local_bin("stylelint") },

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
