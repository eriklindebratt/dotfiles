return {
  -- NOTE: Remember to add language servers in `lsp.lua` as necesssary
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "astro",
        "bash",
        "c",
        "comment",
        "css",
        "csv",
        "dart",
        "diff",
        "dockerfile",
        "elixir",
        "embedded_template",
        "erlang",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "graphql",
        "hcl",
        "html",
        "htmldjango",
        "http",
        "javascript",
        "jsdoc",
        "json",
        "json5",
        "lua",
        "markdown",
        "markdown_inline",
        "objc",
        "passwd",
        "python",
        "regex",
        "ruby",
        "sql",
        "svelte",
        "swift",
        "terraform",
        "todotxt",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      })

      --[[
      Since treesitter currently lacks support for `zsh` filetypes, use `bash` parser.
      More info:
      - https://github.com/nvim-treesitter/nvim-treesitter/issues/2282
      - https://github.com/nvim-treesitter/nvim-treesitter/issues/655#issuecomment-1470096879
      --]]
      vim.treesitter.language.register("bash", "zsh")
    end,
  },
}
