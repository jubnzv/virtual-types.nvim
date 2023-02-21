-- Type annotation for the response of a LSP textDocument/codeLens request, more information can be found here:
-- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_codeLens
---@class position
---@field character integer
---@field line integer

---@class range
---@field start position
---@field end position

---@class command
---@field command string
---@field title string

---@class code_lens
---@field command command
---@field range range

---@alias result code_lens[]

---@class response
---@field result result?

-- Namespace for virtual text messages
local virtual_types_ns = vim.api.nvim_create_namespace("virtual_types")

-- Plugin status
local is_enabled = true

local M = {}

-- Clears the buffer of virtual text.
M.clear_namespace = function()
  vim.api.nvim_buf_clear_namespace(0, virtual_types_ns, 0, -1)
end

-- Writes virtual text to the current buffer.
---@param start_line integer The line number where the annotation should be written.
---@param annotation string The contents of the annotation.
M.set_virtual_text = function(start_line, annotation)
  vim.api.nvim_buf_set_extmark(0, virtual_types_ns, start_line, 1, {
    virt_text = { { annotation, "TypeAnnot" } },
    hl_mode = "combine",
  })
end

M.enable = function()
  is_enabled = true
  M.annotate_types_async()
end

M.disable = function()
  M.clear_namespace()
  is_enabled = false
end

local annotate_types = function()
  if is_enabled == false or vim.fn.getcmdwintype() == ":" or #vim.lsp.get_active_clients() == 0 then
    return
  end
  local parameter = vim.lsp.util.make_position_params(0, nil) ---@diagnostic disable-line
  local responses = vim.lsp.buf_request_sync(0, "textDocument/codeLens", parameter)
  ---@cast responses response[]

  vim.pretty_print(responses)

  M.clear_namespace()
  if responses then
    for _, response in pairs(responses) do
      if response == nil or response.result == nil then
        return
      end
      for _, code_lens in pairs(response.result) do
        if code_lens.range and code_lens.command then
          local start_line = code_lens.range["end"].line
          local annotation = code_lens.command.title
          M.set_virtual_text(start_line, annotation)
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

  -- Setup autocommand to refresh the type annotations
  local virtual_types_augroup = vim.api.nvim_create_augroup("virtual_types_refresh", {})
  vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufWinEnter",
    "BufWrite",
    "CursorMoved",
    "InsertLeave",
    "TabEnter",
  }, {
    buffer = 0,
    callback = M.annotate_types_async,
    group = virtual_types_augroup,
  })
end

return M
