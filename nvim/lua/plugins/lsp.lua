---@return string[]
local function get_abs_deno_enable_paths()
  ---@type string[]
  local deno_enable_paths = {}
  vim.list_extend(deno_enable_paths, require("neoconf").get("vscode.deno.enablePaths") or {})
  vim.list_extend(deno_enable_paths, (require("neoconf").get("lspconfig.denols") or {})["deno.enablePaths"] or {})

  local unique_deno_enable_paths = {}
  for _, unexpanded_path in ipairs(deno_enable_paths) do
    -- An item in `deno.enablePaths` can use wildcard(s) and hence reference multiple files
    ---@type string[]
    expanded_paths = vim.fn.expand(unexpanded_path, nil, true)
    for _, path in ipairs(expanded_paths) do
      unique_deno_enable_paths[vim.fn.fnamemodify(path, ":p")] = true
    end
  end

  return vim.tbl_keys(unique_deno_enable_paths)
end

---@param filename string
local function is_deno_enabled_file(filename)
  local file_path = vim.fn.fnamemodify(filename, ":p")
  for _, path in ipairs(get_abs_deno_enable_paths()) do
    local match = string.find(file_path, path, 1, true)

    if match then
      return true
    end
  end

  return false
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      return vim.tbl_deep_extend("force", opts, {
        -- inlay_hints = {
        --   enabled = false,
        -- },
        setup = {
          vtsls = function(_, opts)
            if vim.lsp.config.denols and vim.lsp.config.vtsls then
              ---@param server string
              local resolve = function(server)
                local markers, root_dir = vim.lsp.config[server].root_markers, vim.lsp.config[server].root_dir
                vim.lsp.config(server, {
                  root_dir = function(bufnr, on_dir)
                    local is_deno = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" }) ~= nil
                      and is_deno_enabled_file(vim.api.nvim_buf_get_name(bufnr))
                    if is_deno == (server == "denols") then
                      if root_dir then
                        return root_dir(bufnr, on_dir)
                      elseif type(markers) == "table" then
                        local root = vim.fs.root(bufnr, markers)
                        return root and on_dir(root)
                      end
                    end
                  end,
                })
              end
              resolve("denols")
              resolve("vtsls")
            end
          end,
        },
      })
    end,
  },

  {
    {
      "mason-org/mason.nvim",
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

        vim.list_extend(opts.ensure_installed, ensure_installed or {})
      end,
    },
  },
}
