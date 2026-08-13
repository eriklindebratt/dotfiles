---Shared detection of which JS/TS tooling a project actually uses.
---
---A project that uses a tool installs it, so looking for the executable is a
---more reliable signal than enumerating config file names -- and unlike a
---hand-maintained list of file names, it cannot drift out of date.
local M = {}

---Nearest ancestor directory whose `node_modules/.bin` holds an executable
---named `bin`.
---
---Package managers commonly hoist binaries to the workspace root while still
---leaving a `node_modules` directory inside each package, so this has to test
---for the executable itself rather than for the directory.
---@param bin string
---@param path string file or directory to search upward from
---@return string|nil dir directory containing `node_modules`, nil when not found
function M.find_local_bin(bin, path)
  if not path or path == "" then
    return nil
  end

  return vim.fs.root(path, function(name, dir)
    return name == "node_modules" and vim.fn.executable(vim.fs.joinpath(dir, name, ".bin", bin)) == 1
  end)
end

---`condition` callback for a `nvim-lint` linter, so a linter only runs in
---projects that install it. LazyVim calls this with `{ filename, dirname }`.
---@param bin string
---@return fun(ctx: { filename: string, dirname: string }): boolean
function M.has_local_bin(bin)
  return function(ctx)
    return M.find_local_bin(bin, ctx.filename) ~= nil
  end
end

return M
