local conform_util = require("conform.util")
local deno_fmt_builtin = require("conform.formatters.deno_fmt")
local oxfmt_builtin = require("conform.formatters.oxfmt")

-- Passed to oxfmt with `-c` for buffers whose prose must be left alone.
-- Deliberately not named `.oxfmtrc.json`, so oxfmt never finds it on its own; it
-- only applies where we pass it explicitly.
local prose_preserve_config = vim.fs.joinpath(vim.fn.stdpath("config"), "oxfmt-prose-preserve.json")

local function is_temporary_file(filename)
  if not filename or filename == "" then
    return false
  end
  local tmp = vim.env.TMPDIR or "/tmp"
  -- Resolve symlinks (e.g. macOS /var -> /private/var) so the prefix check matches
  -- the realpath Neovim reports for the buffer, then ensure exactly one trailing slash
  local temp_dir = (vim.uv.fs_realpath(tmp) or tmp):gsub("/+$", "") .. "/"
  return vim.startswith(filename, temp_dir)
end

-- A project can name the formatter for a language in `.vscode/settings.json`,
-- which neoconf reads for us. That file is committed and shared with other
-- editors, so saying it outright there beats working it out from config files.
-- The value is a VS Code extension id, so we translate.
local vscode_formatters = {
  ["biomejs.biome"] = "biome-check",
  ["denoland.vscode-deno"] = "deno_fmt",
  ["esbenp.prettier-vscode"] = "prettier",
  ["oxc.oxc-vscode"] = "oxfmt",
}

---Get the formatter defined in VS Code settings file for this buffer's language, if any.
---
---Only a per-language block counts, such as `{"[typescript]": {...}}`. The
---project-wide `editor.defaultFormatter` is ignored on purpose: it means "use
---this extension for whatever it can handle", which says nothing about the
---language in front of us. A project that formats its TypeScript with oxfmt
---would otherwise send its Lua there too.
---@param bufnr integer
---@return string|nil
local function get_formatter_from_vscode_settings(bufnr)
  local ok, neoconf = pcall(require, "neoconf")
  if not ok then
    return nil
  end

  local vscode = neoconf.get("vscode", nil, { buffer = bufnr }) or {}
  -- neoconf does not split dotted keys inside per-language blocks, so the inner
  -- key has to be read as written.
  local language_block = vscode["[" .. vim.bo[bufnr].filetype .. "]"] or {}
  local extension_id = language_block["editor.defaultFormatter"]

  return extension_id and vscode_formatters[extension_id] or nil
end

-- Tried in order, and the first one that is available wins. Available means its
-- command exists and it found the config file it requires, so a formatter that
-- fails once it is running does not hand over to the next one.
--
-- The order matters. prettier only counts as found when a project has
-- `.prettierrc` or `package.json#prettier`, which means it really does use
-- prettier. oxfmt also counts `vite.config.ts` as one of its own config files,
-- and projects have that for unrelated reasons. Checking the reliable signs
-- first means that unreliable one never decides anything, so conform's own
-- formatter definitions can stay as they are.
--
-- oxfmt comes last and never has to find a config file. It is what runs when
-- there is no project at all, such as scratch files and commit messages. It
-- reads its own config file wherever it sits in this list, so putting it earlier
-- would make no difference.
--
-- Formatters are left in for filetypes they cannot handle yet, so they start
-- working by themselves once support lands. oxfmt on astro is the current
-- example: it fails with a clear message, which is easy to notice and act on.
local all_formatters = { "prettier", "biome-check", "deno_fmt", "oxfmt" }

-- biome is the exception. On a filetype it does not support it exits 0 and hands
-- back the file untouched, so it would be picked, quietly do nothing, and the
-- rest of the list would never be reached. Nothing would tell you.
local without_biome = { "prettier", "deno_fmt", "oxfmt" }

local formatters_for_filetype = {
  ["astro"] = all_formatters,
  ["css"] = all_formatters,
  ["erlang"] = { "erlfmt" },
  ["graphql"] = all_formatters,
  ["handlebars"] = without_biome,
  ["html"] = without_biome,
  ["javascript"] = all_formatters,
  ["javascriptreact"] = all_formatters,
  ["json"] = all_formatters,
  ["jsonc"] = all_formatters,
  ["less"] = without_biome,
  ["lua"] = { "stylua" },
  ["markdown"] = without_biome,
  ["markdown.mdx"] = without_biome,
  ["python"] = { "autopep8" },
  ["scss"] = all_formatters,
  ["svelte"] = all_formatters,
  ["typescript"] = all_formatters,
  ["typescriptreact"] = all_formatters,
  ["vue"] = all_formatters,
  ["yaml"] = without_biome,
}

---Use the formatter the project named for this language, or fall back to trying
---the list in order.
---@param formatters string[]
---@return fun(bufnr: integer): string[]
local function resolve_formatter(formatters)
  return function(bufnr)
    -- `deno.enablePaths` names the individual files a project has handed to
    -- deno, so deno formats them. This is more specific than a per-language
    -- choice, so it is checked first. Note that a project can still run prettier
    -- over these files in CI, in which case the two disagree.
    if require("util.deno").is_enabled_file(vim.api.nvim_buf_get_name(bufnr), bufnr) then
      return { "deno_fmt", stop_after_first = true }
    end

    local from_vscode_settings = get_formatter_from_vscode_settings(bufnr)
    if from_vscode_settings then
      return { from_vscode_settings, stop_after_first = true }
    end

    local ordered = vim.deepcopy(formatters)
    ordered.stop_after_first = true
    return ordered
  end
end

return {
  "stevearc/conform.nvim",
  optional = true,
  ---@param opts conform.setupOpts
  opts = function(_, opts)
    opts.formatters_by_ft = opts.formatters_by_ft or {}

    -- Set from an `opts` function rather than a table so this runs after the
    -- language extras have added their own entries. They do
    -- `table.insert(opts.formatters_by_ft[ft], ...)`, which would fail against a
    -- function value if they ran after us.
    for ft, formatters in pairs(formatters_for_filetype) do
      opts.formatters_by_ft[ft] = resolve_formatter(formatters)
    end

    opts.formatters = vim.tbl_deep_extend("force", opts.formatters or {}, {
      -- `require_cwd` is off by default, so without it the first formatter in a
      -- list would run in every project and the rest would never be reached. The
      -- oxc extra already sets it for `biome-check`.
      prettier = { require_cwd = true },

      deno_fmt = {
        -- conform's deno_fmt has no `cwd` of its own, so there is nothing for
        -- `require_cwd` to check until we give it one.
        require_cwd = true,
        cwd = conform_util.root_file({ "deno.json", "deno.jsonc" }),

        -- conform reads `condition`, but its own deno_fmt spells the same check
        -- `cond`, so the check never runs. Point the right key at upstream's
        -- function rather than restating which filetypes deno can format.
        -- Without this, deno_fmt would take filetypes deno cannot handle, and
        -- since the first available formatter wins, nothing else would get a go.
        condition = deno_fmt_builtin.cond,

        args = function(self, ctx)
          local args = deno_fmt_builtin.args(self, ctx)
          if vim.bo[ctx.buf].filetype:match("markdown") and is_temporary_file(ctx.filename) then
            table.insert(args, "--options-prose-wrap=preserve")
          end
          return args
        end,
      },

      oxfmt = {
        args = function(self, ctx)
          local args = vim.deepcopy(oxfmt_builtin.args)
          -- oxfmt looks for its config by searching upwards from its working
          -- directory, so a scratch file edited while the editor sits inside a
          -- project picks up that project's `proseWrap`. Give it a config that
          -- leaves prose alone instead. `--disable-nested-config` does not help:
          -- it only stops the search downwards, not upwards.
          if vim.bo[ctx.buf].filetype:match("markdown") and is_temporary_file(ctx.filename) then
            return vim.list_extend({ "-c", prose_preserve_config }, args)
          end
          return args
        end,
      },

      erlfmt = {
        command = "rebar3",
        args = { "fmt", "$FILENAME" },
        stdin = false,
      },
    })
  end,
}
