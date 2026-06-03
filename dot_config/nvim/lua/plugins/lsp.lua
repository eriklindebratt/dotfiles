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
    commit = "8055131", -- https://github.com/neovim/nvim-lspconfig/issues/4216
    opts = function(_, opts)
      return vim.tbl_deep_extend("force", opts, {
        inlay_hints = {
          enabled = false,
        },
        setup = {
          vtsls = function(_, opts)
            if vim.lsp.config.denols and vim.lsp.config.vtsls then
              ---@param server string
              local resolve = function(server)
                local markers, root_dir = vim.lsp.config[server].root_markers, vim.lsp.config[server].root_dir
                vim.lsp.config(server, {
                  root_dir = function(bufnr, on_dir)
                    local is_deno = is_deno_enabled_file(vim.api.nvim_buf_get_name(bufnr))

                    if server == "denols" then
                      if not is_deno then
                        return nil
                      end
                      if root_dir then
                        return root_dir(bufnr, on_dir)
                      elseif type(markers) == "table" then
                        local root = vim.fs.root(bufnr, markers)
                        return root and on_dir(root)
                      end
                    end

                    if server == "vtsls" then
                      if is_deno then
                        return nil
                      end
                      local root = vim.fs.root(bufnr, { "package.json", "tsconfig.json", ".git" })
                      return root and on_dir(root)
                    end
                  end,
                })
              end
              resolve("denols")
              resolve("vtsls")
            end
          end,
          -- Very much based on https://github.com/neovim/nvim-lspconfig/blob/07f4e93de92e8d4ea7ab99602e3a8c9ac0fb778a/lsp/eslint.lua#L89
          eslint = function(_, opts)
            vim.lsp.config("eslint", {
              root_dir = function(bufnr, on_dir)
                -- The project root is where the LSP can be started from
                -- As stated in the documentation above, this LSP supports monorepos and simple projects.
                -- We select then from the project root, which is identified by the presence of a package
                -- manager lock file.
                local root_markers = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
                -- Give the root markers equal priority by wrapping them in a table
                root_markers = vim.fn.has("nvim-0.11.3") == 1 and { root_markers, { ".git" } }
                  or vim.list_extend(root_markers, { ".git" })

                -- exclude deno
                -- if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
                if is_deno_enabled_file(vim.api.nvim_buf_get_name(bufnr)) then
                  return
                end

                -- We fallback to the current working directory if no project root is found
                local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

                on_dir(project_root)
              end,
            })
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
          "copilot-language-server",
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
