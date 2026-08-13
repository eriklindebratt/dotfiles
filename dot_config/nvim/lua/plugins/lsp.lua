-- Moved to `util/deno.lua` so `plugins/formatting.lua` can use the same answer:
-- a file deno owns is also a file deno formats.
local deno = require("util.deno")

local get_abs_deno_enable_paths = deno.get_abs_enable_paths
local is_deno_enabled_file = deno.is_enabled_file

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- A server's `setup` handler is a single slot (LazyVim's lsp/init.lua does
      -- `opts.setup[server] or opts.setup["*"]`), so overriding `setup.vtsls`
      -- below would silently drop LazyVim's typescript-extra handler. Capture it
      -- here so we can compose with it instead of clobbering it.
      local lazyvim_vtsls_setup = opts.setup and opts.setup.vtsls

      -- Upstream's eslint `root_dir` already refuses to start unless the buffer
      -- has an eslint config above it, `package.json#eslintConfig` included, so
      -- eslint stays out of projects that do not use it. Reuse it and add only
      -- the part it lacks: upstream skips a project whenever any deno config
      -- sits above the buffer, which is wrong where deno owns a few scripts and
      -- something else owns the rest.
      local upstream_eslint_root_dir = vim.lsp.config.eslint and vim.lsp.config.eslint.root_dir

      -- LazyVim's oxc extra decides whether oxlint should start and where its
      -- config lives. Reuse that and only move the directory we hand over.
      local lazyvim_oxlint_root_dir = opts.servers and opts.servers.oxlint and opts.servers.oxlint.root_dir

      local servers = {
        oxlint = {
          root_dir = lazyvim_oxlint_root_dir and function(bufnr, on_dir)
            lazyvim_oxlint_root_dir(bufnr, function(config_dir)
              -- lspconfig looks for `oxlint` and `tsgolint` in
              -- `<root_dir>/node_modules/.bin` and checks that one directory
              -- only. Start the server where the binary actually is, otherwise
              -- it quietly falls back to a globally installed oxlint on a
              -- different version than the project pins. Nested config files
              -- are still read per file, so per-package rules still apply.
              on_dir(require("util.js-tooling").find_local_bin("oxlint", vim.api.nvim_buf_get_name(bufnr)) or config_dir)
            end)
          end or nil,

          settings = {
            -- lspconfig turns this on by itself only when `tsgolint` is on the
            -- path AND `.oxlintrc.json` contains "typescript", so a project
            -- configured through `oxlint.config.ts` can never trigger that.
            -- Say it outright so the editor reports what the project's own
            -- type-aware lint run reports. lspconfig only fills this in when it
            -- is nil, so it will not fight us.
            typeAware = true,
          },
        },
      }

      if upstream_eslint_root_dir then
        -- lspconfig's own `on_attach` is what creates `LspEslintFixAll`, so call
        -- it rather than replacing it.
        local upstream_eslint_on_attach = vim.lsp.config.eslint.on_attach

        servers.eslint = {
          root_dir = function(bufnr, on_dir)
            if is_deno_enabled_file(vim.api.nvim_buf_get_name(bufnr)) then
              return
            end
            return upstream_eslint_root_dir(bufnr, on_dir)
          end,

          on_attach = function(client, bufnr)
            if upstream_eslint_on_attach then
              upstream_eslint_on_attach(client, bufnr)
            end

            -- This is what actually fixes lint errors on save. `applyAllFixes`
            -- is a command rather than a formatter, so it runs whatever else is
            -- formatting the buffer, and it still works with
            -- `lazyvim_eslint_auto_format` turned off in `config/options.lua`.
            -- See there for why relying on eslint as a formatter did not work.
            -- Applying fixes this way is what nvim-lspconfig's docs suggest.
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              command = "LspEslintFixAll",
            })
          end,
        }
      end

      return vim.tbl_deep_extend("force", opts, {
        inlay_hints = {
          enabled = false,
        },
        servers = servers,
        setup = {
          vtsls = function(server, sopts)
            -- Run the extra's setup for its side effects: the
            -- `_typescript.moveToFileRefactoring` command handler ("Move to file"
            -- code action) and the TypeScript -> JavaScript settings copy.
            if lazyvim_vtsls_setup then
              lazyvim_vtsls_setup(server, sopts)
            end

            if not (vim.lsp.config.denols and vim.lsp.config.vtsls) then
              return
            end

            -- denols is NOT passive for files outside enablePaths — it actively
            -- produces errors. root_dir must gate per-file to keep it and vtsls
            -- mutually exclusive.
            vim.lsp.config("denols", {
              root_dir = function(bufnr, on_dir)
                local file_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
                local enable_paths = get_abs_deno_enable_paths()

                if #enable_paths > 0 then
                  -- enablePaths is sole truth: only attach to files in those paths.
                  -- Fall back to cwd since the user has explicitly opted in.
                  for _, path in ipairs(enable_paths) do
                    if vim.startswith(file_path, path) then
                      local root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" })
                        or vim.fs.root(bufnr, { ".git" })
                        or vim.uv.cwd()
                      return on_dir(root)
                    end
                  end
                  return nil
                end

                if require("neoconf").get("vscode.deno.enable") then
                  local root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" })
                    or vim.fs.root(bufnr, { ".git" })
                    or vim.uv.cwd()
                  return on_dir(root)
                end

                -- No explicit config: require a deno config file, no cwd fallback.
                local root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" })
                return root and on_dir(root)
              end,
            })

            -- vtsls is the critical gate: skip any file that denols should own.
            -- Priority: enablePaths (sole truth when set) → deno.enable → deno config file.
            vim.lsp.config("vtsls", {
              root_dir = function(bufnr, on_dir)
                local file_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
                local enable_paths = get_abs_deno_enable_paths()

                if #enable_paths > 0 then
                  for _, path in ipairs(enable_paths) do
                    if vim.startswith(file_path, path) then
                      return nil
                    end
                  end
                elseif require("neoconf").get("vscode.deno.enable") then
                  return nil
                elseif vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
                  return nil
                end

                local root = vim.fs.root(bufnr, { "package.json", "tsconfig.json", ".git" })
                return root and on_dir(root)
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
          "oxlint",
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
