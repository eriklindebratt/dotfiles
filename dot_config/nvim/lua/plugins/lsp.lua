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
    local expanded_paths = vim.fn.expand(unexpanded_path, nil, true)
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
    -- Both paths are absolute, so anchor at the start rather than matching the
    -- enable path anywhere in the filename.
    if vim.startswith(file_path, path) then
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
      -- A server's `setup` handler is a single slot (LazyVim's lsp/init.lua does
      -- `opts.setup[server] or opts.setup["*"]`), so overriding `setup.vtsls`
      -- below would silently drop LazyVim's typescript-extra handler. Capture it
      -- here so we can compose with it instead of clobbering it.
      local lazyvim_vtsls_setup = opts.setup and opts.setup.vtsls

      return vim.tbl_deep_extend("force", opts, {
        inlay_hints = {
          enabled = false,
        },
        servers = {
          -- Declared on the server (not via `setup.eslint`) so it merges with
          -- LazyVim's eslint extra instead of clobbering the extra's
          -- `setup.eslint`, which registers eslint as a format-on-save source.
          -- Very much based on https://github.com/neovim/nvim-lspconfig/blob/07f4e93de92e8d4ea7ab99602e3a8c9ac0fb778a/lsp/eslint.lua#L89
          eslint = {
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
              if is_deno_enabled_file(vim.api.nvim_buf_get_name(bufnr)) then
                return
              end

              -- We fallback to the current working directory if no project root is found
              local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

              on_dir(project_root)
            end,
          },
        },
        setup = {
          vtsls = function(server, sopts)
            if not (vim.lsp.config.denols and vim.lsp.config.vtsls) then
              return
            end

            -- Capture the *stock* root resolution for both servers before the
            -- extra wraps them, so our override delegates to the real defaults
            -- rather than the extra's deno.json-marker wrapper.
            local stock = {}
            for _, name in ipairs({ "denols", "vtsls" }) do
              stock[name] = {
                markers = vim.lsp.config[name].root_markers,
                root_dir = vim.lsp.config[name].root_dir,
              }
            end

            -- Run the extra's setup for its side effects: the
            -- `_typescript.moveToFileRefactoring` command handler ("Move to file"
            -- code action) and the TypeScript -> JavaScript settings copy. It
            -- also installs its own deno.json-marker root split, which we
            -- overwrite below.
            if lazyvim_vtsls_setup then
              lazyvim_vtsls_setup(server, sopts)
            end

            -- Override root resolution with our neoconf `deno.enablePaths` aware
            -- version (handles deno files inside an npm monorepo without their
            -- own deno.json, and gates which server attaches).
            ---@param name string
            local resolve = function(name)
              local markers, root_dir = stock[name].markers, stock[name].root_dir
              vim.lsp.config(name, {
                root_dir = function(bufnr, on_dir)
                  local is_deno = is_deno_enabled_file(vim.api.nvim_buf_get_name(bufnr))

                  if name == "denols" then
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

                  if name == "vtsls" then
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
