local vim = vim
local api = vim.api
local lsp = vim.lsp

local M = {}

-- Selects an API function to show virtual text.
-- The `nvim_buf_set_virtual_text` will be deprecated in 0.6:
-- https://github.com/neovim/neovim/pull/1518
local set_virtual_text
if vim.api.nvim_call_function('exists', {'*nvim_buf_set_extmark'}) == 1 then
  set_virtual_text = function(buffer_number, ns, start_line, msg)
    if (type(msg[1]) ~= "string") or (msg[2] ~= "TypeAnnot") then
      return
    end
    api.nvim_buf_set_extmark(buffer_number, ns, start_line, 1, { virt_text = { msg }, hl_mode = 'combine' } )
  end
else
  set_virtual_text = function(buffer_number, ns, start_line, msg)
    api.nvim_buf_set_virtual_text(buffer_number, ns, start_line, {msg}, {})
  end
end

-- Plugin status
local is_enabled = true

-- Namespace for virtual text messages
local virtual_types_ns = api.nvim_create_namespace("virtual_types");

function M.enable()
  is_enabled = true
  M.annotate_types_async()
end

function M.disable()
  api.nvim_buf_clear_namespace(buffer_number, virtual_types_ns, 0, -1)
  is_enabled = false
end

function M.on_attach(client, _)
  if client == nil then
    return
  end
  if not client.supports_method('textDocument/codeLens') then
    local err = string.format(
      "virtual-types.nvim: %s does not support \"textDocument/codeLens\" command",
      client.name)
    api.nvim_command(string.format("echohl WarningMsg | echo '%s' | echohl None", err))
    return
  end

  -- Don't use schedule. It somewhat slower on startup.
  annotate_types()

  -- Setup autocmd
  api.nvim_exec([[
    augroup virtual_types_refresh
      autocmd! * <buffer>
      autocmd BufEnter,BufWinEnter,TabEnter,BufWrite <buffer> lua require'virtualtypes'.annotate_types_async()
      autocmd InsertLeave <buffer> lua require'virtualtypes'.annotate_types_async()
    augroup END]], '')
end

-- Async wrapper for annotate_types.
-- We need it since 'textDocument/codeLens' call can freeze UI for ~0.2s.
function M:annotate_types_async()
    cr = vim.schedule(annotate_types)
end

function annotate_types()
  if is_enabled == false then return end
  if vim.fn.getcmdwintype() == ':' then return end
  if #vim.lsp.buf_get_clients() == 0 then return end

  local buffer_number = api.nvim_get_current_buf()
  local parameter = lsp.util.make_position_params()
  local response = lsp.buf_request_sync(buffer_number, "textDocument/codeLens", parameter)

  -- Clear previous highlighting
  api.nvim_buf_clear_namespace(buffer_number, virtual_types_ns, 0, -1)

  if response then
    for _, v in ipairs(response) do
      if v == nil or v["result"] == nil then return end -- no response
      for _,vv in pairs(v["result"]) do
        if vv["range"] and vv["command"] then
          local start_line = -1
          for _,vvv in pairs(vv["range"]) do
            start_line = tonumber(vvv["line"])
          end
          for _,vvv in pairs(vv["command"]) do
            if vvv == nil or vvv == "" then
              goto skip_to_next
            end
            local msg = {vvv, "TypeAnnot"}
            set_virtual_text(buffer_number, virtual_types_ns, start_line, msg)
            ::skip_to_next::
          end
        end
      end
    end
  -- else
  --   api.nvim_command("echohl WarningMsg | echo 'VirtualTypes: No response' | echohl None")
  end
end

return M
