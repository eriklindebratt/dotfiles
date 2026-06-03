-- Extend what's set in `lazyvim.plugins.extras.lang.typescript`
return {
  "mfussenegger/nvim-dap",
  opts = function()
    local dap = require("dap")
    ---Prompt for optionally using a custom port. `nil` will result in default port being used.
    ---@return string|nil
    local get_port = function()
      local port = vim.fn.input({
        prompt = "Custom port (<Enter> for default): ",
      })
      if tonumber(port) == nil then
        return nil
      end
      if string.match(port, "[^%d]") then
        vim.notify("Invalid port `" .. port .. "`. Will use default.", vim.log.levels.WARN)
        return nil
      end
      return port
    end
    ---@param config Configuration
    local is_attach_config = function(config)
      return string.find(string.lower(config.name), "attach")
    end
    for _, language in ipairs({ "typescript", "javascript" }) do
      if dap.configurations[language] then
        -- Sort configurations to get the ones named "*attach*" on top
        table.sort(dap.configurations[language], function(a)
          if is_attach_config(a) then
            return true
          else
            return false
          end
        end)

        for config_idx, lang_config in ipairs(dap.configurations[language]) do
          -- Add `port` option to configurations named "*attach*"
          if is_attach_config(lang_config) and dap.configurations[language][config_idx].port == nil then
            dap.configurations[language][config_idx].port = get_port
          end
        end
      end
    end
  end,
}
