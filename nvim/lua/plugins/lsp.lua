-- https://www.lazyvim.org/plugins/lsp

return {
  {
    "williamboman/mason.nvim",

    opts = function(_, opts)
      local ensure_installed = {
        -- NOTE: Remember to add languages in `treesitter.lua` as necesssary
        "lua-language-server",
        "bash-language-server",
        "black",
        "dockerfile-language-server",
        "gopls",
        "graphql-language-service-cli",
        "html-lsp",
        "json-lsp",
        "nginx-language-server",
        "prettierd",
        "pyright",
        "tailwindcss-language-server",
        "typescript-language-server",
        "sqlls",
        -- see lazy.lua for LazyVim extras
      }

      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, ensure_installed)
    end,
  },
}
