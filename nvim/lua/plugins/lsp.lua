-- https://www.lazyvim.org/plugins/lsp

return {
  {
    "williamboman/mason.nvim",

    opts = function(_, opts)
      local ensure_installed = {
        -- NOTE: Remember to add languages in `treesitter.lua` as necesssary
        "bash-language-server",
        "black",
        "css-lsp",
        "css-variables-language-server",
        "deno",
        "dockerfile-language-server",
        "eslint-lsp",
        "gopls",
        "graphql-language-service-cli",
        "html-lsp",
        "json-lsp",
        "lua-language-server",
        "nginx-language-server",
        "prettier",
        "pyright",
        "tailwindcss-language-server",
        "tflint",
        "vtsls",
        "shellcheck",
        "stylelint",
        "svelte-language-server",
        "sqlls",
        -- see lazy.lua for LazyVim extras
      }

      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, ensure_installed)
    end,
  },
}
