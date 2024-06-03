local function get_abs_deno_enable_paths()
  ---@type string[]
  local deno_enable_paths = require("neoconf").get("vscode.deno.enablePaths")

  if not deno_enable_paths then
    return {}
  end

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
  -- print("deno enable paths absolute: " .. vim.inspect(get_abs_deno_enable_paths()))
  for _, path in ipairs(get_abs_deno_enable_paths()) do
    local match = string.find(file_path, path, 1, true)
    -- print("file_path: " .. vim.inspect(file_path))
    -- print("path: " .. vim.inspect(path))
    -- print("match: " .. vim.inspect(match))

    if match then
      return true
    end
  end

  return false
end

-- return {}

-- lspconfig
return {
  "neovim/nvim-lspconfig",
  ---@class PluginLspOpts
  opts = function(_, opts)
    return vim.tbl_deep_extend("force", opts, {
      inlay_hints = {
        enabled = false,
      },
      setup = {
        vtsls = function(_, opts)
          opts.single_file_support = false
          opts.root_dir = function(filename, bufnr)
            if is_deno_enabled_file(filename) then
              return nil
            end
            return require("lspconfig.util").root_pattern("package.json")(filename)
          end
        end,
      },
    })
  end,
}
