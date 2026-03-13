local M = {}

function M.append_keys(config, keys)
  if not keys or #keys == 0 then
    return
  end

  config.keys = config.keys or {}

  for _, key in ipairs(keys) do
    table.insert(config.keys, key)
  end
end

return M
