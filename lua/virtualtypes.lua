local api = vim.api
local lsp = vim.lsp

local M = {}

-- Namespace for virtual text messages
local virtual_types_ns = api.nvim_create_namespace("virtual_types")

-- Plugin status
local is_enabled = true

-- Clears the buffer of virtual text.
M.clear_namespace = function()
  vim.api.nvim_buf_clear_namespace(0, virtual_types_ns, 0, -1)
end

-- Writes virtual text to the current buffer.
---@param start_line integer The line number where the message should start.
M.set_virtual_text = function(start_line, msg)
  if type(msg[1]) ~= "string" or msg[2] ~= "TypeAnnot" then
    return
  end
  api.nvim_buf_set_extmark(0, virtual_types_ns, start_line, 1, {
    virt_text = { msg },
    hl_mode = "combine",
  })
end

function M.enable()
  is_enabled = true
  M.annotate_types_async()
end

function M.disable()
  M.clear_namespace()
  is_enabled = false
end

local annotate_types = function()
  if is_enabled == false or vim.fn.getcmdwintype() == ":" or #vim.lsp.get_active_clients() == 0 then
    return
  end

  local parameter = lsp.util.make_position_params(0, nil)
  local response = lsp.buf_request_sync(0, "textDocument/codeLens", parameter)

  M.clear_namespace()

  if response then
    for _, v in pairs(response) do
      if v == nil or v["result"] == nil then
        return
      end -- no response
      for _, vv in pairs(v["result"]) do
        if vv["range"] and vv["command"] then
          local start_line = -1
          for _, vvv in pairs(vv["range"]) do
            start_line = tonumber(vvv["line"])
          end
          for _, vvv in pairs(vv["command"]) do
            if vvv == nil or vvv == "" then
              goto skip_to_next
            end
            local msg = { vvv, "TypeAnnot" }
            M.set_virtual_text(start_line, msg)
            ::skip_to_next::
          end
        end
      end
    end
  end
end

-- Async wrapper for annotate_types.
-- We need it since 'textDocument/codeLens' call can freeze UI for ~0.2s.
function M.annotate_types_async()
  vim.schedule(annotate_types)
end

function M.on_attach(client, _)
  if not client.supports_method("textDocument/codeLens") then
    local err = string.format('virtual-types.nvim: %s does not support "textDocument/codeLens" command', client.name)
    vim.notify_once(err, vim.log.levels.WARN)
    return
  end

  -- Don't use schedule. It somewhat slower on startup.
  annotate_types()

  -- Setup autocmd
  local virtual_types_augroup = vim.api.nvim_create_augroup("virtual_types_refresh", {})
  vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufWinEnter",
    "BufWrite",
    "InsertLeave",
    "TabEnter",
  }, {
    buffer = 0,
    callback = M.annotate_types_async,
    group = virtual_types_augroup,
  })
end

return M
