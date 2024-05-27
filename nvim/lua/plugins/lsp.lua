-- https://www.lazyvim.org/plugins/lsp

local function handle_maybe_deno_file(buffer, client)
  local buffer_has_denols_clients_active = next(LazyVim.lsp.get_clients({ bufnr = buffer, name = "denols" }))
  if not buffer_has_denols_clients_active then
    -- print("return 5")
    return
  end

  local buffer_file_path = vim.fn.fnamemodify(vim.fn.bufname(buffer), ":p")
  -- print("buffer_file_path: " .. vim.inspect(buffer_file_path))

  -- Check if current file matches `deno.enablePaths`
  local unique_deno_enable_paths = {}
  for _, unexpanded_path in ipairs(client.settings.deno.enablePaths) do
    -- An item in `deno.enablePaths` can use wildcard(s) and hence reference multiple files
    for _, path in ipairs(vim.fn.expand(unexpanded_path, nil, true)) do
      unique_deno_enable_paths[vim.fn.fnamemodify(path, ":p")] = true
    end
  end

  -- print("unique_deno_enable_paths: " .. vim.inspect(unique_deno_enable_paths))
  for path, _ in pairs(unique_deno_enable_paths) do
    -- local full_path = vim.fn.fnamemodify(path, ":p")
    -- local match = string.match(buffer_file_path, "%^" .. full_path) -- ~= nil
    local match = string.find(buffer_file_path, path, 1, true)
    -- print("path: " .. vim.inspect(full_path))
    -- print("should disable tsserver? " .. buffer_file_path .. " - match: " .. vim.inspect(match))
    -- print("match?: " .. vim.inspect(match))

    if match then
      vim.defer_fn(function()
        vim.lsp.buf_detach_client(buffer, client.id)
      end, 10)
    end
  end
end

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
        "typescript-language-server",
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
  {
    "neovim/nvim-lspconfig",
    event = "LazyFile",
    dependencies = {
      { "folke/neoconf.nvim", cmd = "Neoconf", config = false, dependencies = { "nvim-lspconfig" } },
      { "folke/neodev.nvim", opts = {} },
      "mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    ---@class PluginLspOpts
    opts = {
      -- options for vim.diagnostic.config()
      ---@type vim.diagnostic.Opts
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
          -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
          -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
          -- prefix = "icons",
        },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
            [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
            [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
            [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
          },
        },
      },
      -- Enable this to enable the builtin LSP inlay hints on Neovim >= 0.10.0
      -- Be aware that you also will need to properly configure your LSP server to
      -- provide the inlay hints.
      inlay_hints = {
        enabled = true,
      },
      -- Enable this to enable the builtin LSP code lenses on Neovim >= 0.10.0
      -- Be aware that you also will need to properly configure your LSP server to
      -- provide the code lenses.
      codelens = {
        enabled = false,
      },
      -- Enable lsp cursor word highlighting
      document_highlight = {
        enabled = true,
      },
      -- add any global capabilities here
      capabilities = {},
      -- options for vim.lsp.buf.format
      -- `bufnr` and `filter` is handled by the LazyVim formatter,
      -- but can be also overridden when specified
      format = {
        formatting_options = nil,
        timeout_ms = nil,
      },
      -- LSP Server Settings
      ---@type lspconfig.options
      servers = {
        lua_ls = {
          -- mason = false, -- set to false if you don't want this server to be installed with mason
          -- Use this to add any additional keymaps
          -- for specific lsp servers
          ---@type LazyKeysSpec[]
          -- keys = {},
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              codeLens = {
                enable = true,
              },
              completion = {
                callSnippet = "Replace",
              },
              doc = {
                privateName = { "^_" },
              },
              hint = {
                enable = true,
                setType = false,
                paramType = true,
                paramName = "Disable",
                semicolon = "Disable",
                arrayIndex = "Disable",
              },
            },
          },
        },
      },
      -- you can do any additional lsp server setup here
      -- return true if you don't want this server to be setup with lspconfig
      ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
      setup = {
        -- example to setup with typescript.nvim
        -- tsserver = function(_, opts)
        --   require("typescript").setup({ server = opts })
        --   return true
        -- end,
        -- Specify * to use this function as a fallback for any server
        -- ["*"] = function(server, opts) end,
      },
    },
    ---@param opts PluginLspOpts
    config = function(_, opts)
      if LazyVim.has("neoconf.nvim") then
        require("neoconf").setup(LazyVim.opts("neoconf.nvim"))
      end

      -- setup autoformat
      LazyVim.format.register(LazyVim.lsp.formatter())

      -- setup keymaps
      LazyVim.lsp.on_attach(function(client, buffer)
        require("lazyvim.plugins.lsp.keymaps").on_attach(client, buffer)
      end)

      LazyVim.lsp.setup()
      LazyVim.lsp.on_dynamic_capability(require("lazyvim.plugins.lsp.keymaps").on_attach)

      LazyVim.lsp.words.setup(opts.document_highlight)

      -- diagnostics signs
      if vim.fn.has("nvim-0.10.0") == 0 then
        if type(opts.diagnostics.signs) ~= "boolean" then
          for severity, icon in pairs(opts.diagnostics.signs.text) do
            local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
            name = "DiagnosticSign" .. name
            vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
          end
        end
      end

      if vim.fn.has("nvim-0.10") == 1 then
        -- inlay hints
        if opts.inlay_hints.enabled then
          LazyVim.lsp.on_supports_method("textDocument/inlayHint", function(client, buffer)
            if vim.api.nvim_buf_is_valid(buffer) and vim.bo[buffer].buftype == "" then
              LazyVim.toggle.inlay_hints(buffer, true)
            end
          end)
        end

        -- code lens
        if opts.codelens.enabled and vim.lsp.codelens then
          LazyVim.lsp.on_supports_method("textDocument/codeLens", function(client, buffer)
            vim.lsp.codelens.refresh()
            vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
              buffer = buffer,
              callback = vim.lsp.codelens.refresh,
            })
          end)
        end
      end

      if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
        opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") == 0 and "●"
          or function(diagnostic)
            local icons = require("lazyvim.config").icons.diagnostics
            for d, icon in pairs(icons) do
              if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
                return icon
              end
            end
          end
      end

      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

      local servers = opts.servers
      local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      local capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        has_cmp and cmp_nvim_lsp.default_capabilities() or {},
        opts.capabilities or {}
      )

      local function setup(server)
        local server_opts = vim.tbl_deep_extend("force", {
          capabilities = vim.deepcopy(capabilities),
        }, servers[server] or {})

        if opts.setup[server] then
          if opts.setup[server](server, server_opts) then
            return
          end
        elseif opts.setup["*"] then
          if opts.setup["*"](server, server_opts) then
            return
          end
        end
        require("lspconfig")[server].setup(server_opts)
      end

      -- get all the servers that are available through mason-lspconfig
      local have_mason, mlsp = pcall(require, "mason-lspconfig")
      local all_mslp_servers = {}
      if have_mason then
        all_mslp_servers = vim.tbl_keys(require("mason-lspconfig.mappings.server").lspconfig_to_package)
      end

      local ensure_installed = {} ---@type string[]
      for server, server_opts in pairs(servers) do
        if server_opts then
          server_opts = server_opts == true and {} or server_opts
          -- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
          if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
            setup(server)
          elseif server_opts.enabled ~= false then
            ensure_installed[#ensure_installed + 1] = server
          end
        end
      end

      if have_mason then
        mlsp.setup({
          ensure_installed = vim.tbl_deep_extend(
            "force",
            ensure_installed,
            LazyVim.opts("mason-lspconfig.nvim").ensure_installed or {}
          ),
          handlers = { setup },
        })
      end

      if LazyVim.lsp.get_config("denols") and LazyVim.lsp.get_config("tsserver") then
        local is_deno = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")
        LazyVim.lsp.disable("tsserver", function(root_dir, config)
          -- print("CONFIG: " .. vim.inspect(config))
          config.single_file_support = true
          return is_deno(root_dir)
        end)
        LazyVim.lsp.disable("denols", function(root_dir, config)
          if is_deno(root_dir) then
            -- Matched Deno using root pattern - just allow that and stop further execution
            return false
          end

          -- Returning `true` here seems to disable the LSP client completely, so `deno.enablePaths` will have no effect.
          -- If we instead set the denols settings to have `deno.enable = false`, denols can still be used if `deno.enablePaths` is set and matches the current file path.
          config.settings.deno.enable = false
          return false
        end)

        vim.api.nvim_create_autocmd({ "BufEnter" }, {
          callback = function(ev)
            -- if not vim.api.nvim_buf_is_valid(ev.) or vim.bo[buffer].buftype ~= "" then
            -- return
            -- end
          end,
        })

        LazyVim.lsp.on_attach(function(client, buffer)
          -- print("on_attach - client:" .. client.name)
          if not vim.api.nvim_buf_is_valid(buffer) or vim.bo[buffer].buftype ~= "" then
            -- print("return 2")
            return
          end

          if not client.settings.deno or not client.settings.deno.enablePaths then
            -- print("return 3")
            return
          end

          if client.name ~= "tsserver" then
            -- print("return 4 " .. client.name)
            return
          end

          -- print(vim.inspect(client))

          -- local buffer_has_denols_clients_active = next(LazyVim.lsp.get_clients({ bufnr = buffer, name = "denols" }))
          -- if not buffer_has_denols_clients_active then
          --   -- print("return 5")
          --   return
          -- end
          --
          -- local buffer_file_path = vim.fn.fnamemodify(vim.fn.bufname(buffer), ":p")
          -- -- print("buffer_file_path: " .. vim.inspect(buffer_file_path))
          --
          -- -- Check if current file matches `deno.enablePaths`
          -- local unique_deno_enable_paths = {}
          -- for _, unexpanded_path in ipairs(client.settings.deno.enablePaths) do
          --   -- An item in `deno.enablePaths` can use wildcard(s) and hence reference multiple files
          --   for _, path in ipairs(vim.fn.expand(unexpanded_path, nil, true)) do
          --     unique_deno_enable_paths[vim.fn.fnamemodify(path, ":p")] = true
          --   end
          -- end
          --
          -- -- print("unique_deno_enable_paths: " .. vim.inspect(unique_deno_enable_paths))
          -- for path, _ in pairs(unique_deno_enable_paths) do
          --   -- local full_path = vim.fn.fnamemodify(path, ":p")
          --   -- local match = string.match(buffer_file_path, "%^" .. full_path) -- ~= nil
          --   local match = string.find(buffer_file_path, path, 1, true)
          --   -- print("path: " .. vim.inspect(full_path))
          --   -- print("should disable tsserver? " .. buffer_file_path .. " - match: " .. vim.inspect(match))
          --   -- print("match?: " .. vim.inspect(match))
          --
          --   if match then
          --     vim.defer_fn(function()
          --       vim.lsp.buf_detach_client(buffer, client.id)
          --     end, 10)
          --   end
          -- end
          handle_maybe_deno_file(buffer, client)
        end)
      end
    end,
  },
}
