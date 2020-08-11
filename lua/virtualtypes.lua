local vim = vim
local api = vim.api
local lsp = vim.lsp

local M = {}

-- Plugin status
local is_enabled = true

-- Namespace for virtual text messages
local virtual_types_ns = api.nvim_create_namespace("virtual_types");

function M.enable()
  is_enabled = true
  M.annotate_types()
end

function M.disable()
  api.nvim_buf_clear_namespace(buffer_number, virtual_types_ns, 0, -1)
  is_enabled = false
end

function M:on_attach(_, _)
  M.annotate_types()

  -- Setup autocmd
  api.nvim_exec([[
    augroup virtual_types_refresh
      autocmd! * <buffer>
      autocmd BufEnter,BufWinEnter,TabEnter,BufWrite <buffer> lua require'virtualtypes'.annotate_types()
      autocmd InsertLeave <buffer> lua require'virtualtypes'.annotate_types()
    augroup END]], '')
end

function M:annotate_types()
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
      for _,vv in pairs(v["result"]) do
        local start_line = -1
        for _,vvv in pairs(vv["range"]) do
          start_line = tonumber(vvv["line"])
        end
        for _,vvv in pairs(vv["command"]) do
          if vvv == nil or vvv == "" then
            goto skip_to_next
          end
          local msg = {}
          msg[1] = vvv
          msg[2] = "TypeAnnot"
          api.nvim_buf_set_virtual_text(buffer_number, virtual_types_ns, start_line, {msg}, {})
          ::skip_to_next::
        end
      end
    end
  else
    api.nvim_command("echohl WarningMsg | echo 'No response' | echohl None")
  end
end

return M
