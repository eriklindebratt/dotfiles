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
      erlfmt = {
        command = "rebar3",
        args = { "fmt", "$FILENAME" },
        stdin = false,
      },
    },
  },
}
