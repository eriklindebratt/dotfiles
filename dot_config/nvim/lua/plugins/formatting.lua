local deno_fmt_builtin = require("conform.formatters.deno_fmt")

local function isTemporaryFile(filename)
  if not filename or filename == "" then
    return false
  end
  local tmp = vim.env.TMPDIR or "/tmp"
  -- Resolve symlinks (e.g. macOS /var -> /private/var) so the prefix check matches
  -- the realpath Neovim reports for the buffer, then ensure exactly one trailing slash
  local tempDir = (vim.uv.fs_realpath(tmp) or tmp):gsub("/+$", "") .. "/"
  return vim.startswith(filename, tempDir)
end

return {
  "stevearc/conform.nvim",
  optional = true,
  opts = {
    formatters_by_ft = {
      ["javascript"] = { "deno_fmt" },
      ["javascriptreact"] = { "deno_fmt" },
      ["typescript"] = { "deno_fmt" },
      ["typescriptreact"] = { "deno_fmt" },
      ["vue"] = { "deno_fmt" },
      ["css"] = { "deno_fmt" },
      ["scss"] = { "deno_fmt" },
      ["less"] = { "deno_fmt" },
      ["html"] = { "deno_fmt" },
      ["json"] = { "deno_fmt" },
      ["jsonc"] = { "deno_fmt" },
      ["yaml"] = { "deno_fmt" },
      ["markdown"] = { "deno_fmt" },
      ["markdown.mdx"] = { "deno_fmt" },
      ["graphql"] = { "deno_fmt" },
      ["handlebars"] = { "deno_fmt" },
      ["lua"] = { "stylua" },
      ["python"] = { "autopep8" },
      ["erlang"] = { "erlfmt" },
    },
    formatters = {
      deno_fmt = {
        args = function(self, ctx)
          local args = deno_fmt_builtin.args(self, ctx)
          if vim.bo[ctx.buf].filetype:match("markdown") and isTemporaryFile(ctx.filename) then
            table.insert(args, "--options-prose-wrap=preserve")
          end
          return args
        end,
      },
      erlfmt = {
        command = "rebar3",
        args = { "fmt", "$FILENAME" },
        stdin = false,
      },
    },
  },
}
