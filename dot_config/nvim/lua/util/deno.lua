---Which files a project has handed over to Deno.
---
---`deno.enablePaths` lets a project use Deno for a few scripts while the rest of
---it uses something else. It decides both which language server attaches
---(`plugins/lsp.lua`) and which formatter runs (`plugins/formatting.lua`), so it
---lives here rather than in either of them.
local M = {}

---@param bufnr? integer buffer to read project settings for, defaults to current
---@return string[]
function M.get_abs_enable_paths(bufnr)
  local scope = { buffer = bufnr }

  ---@type string[]
  local deno_enable_paths = {}
  vim.list_extend(deno_enable_paths, require("neoconf").get("vscode.deno.enablePaths", nil, scope) or {})
  vim.list_extend(
    deno_enable_paths,
    (require("neoconf").get("lspconfig.denols", nil, scope) or {})["deno.enablePaths"] or {}
  )

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
---@param bufnr? integer buffer to read project settings for, defaults to current
---@return boolean
function M.is_enabled_file(filename, bufnr)
  if not filename or filename == "" then
    return false
  end

  local file_path = vim.fn.fnamemodify(filename, ":p")
  for _, path in ipairs(M.get_abs_enable_paths(bufnr)) do
    -- Both paths are absolute, so anchor at the start rather than matching the
    -- enable path anywhere in the filename.
    if vim.startswith(file_path, path) then
      return true
    end
  end

  return false
end

return M
