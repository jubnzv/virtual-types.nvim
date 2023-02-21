-- See the Microsoft LSP Documentation for more information on textDocument/codeLens:
-- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_codeLens

-- Position in a text document expressed as zero-based line and zero-based character offset.
---@class position
---@field character integer Character offset on a line in a document (zero-based).
---@field line integer Line position in a document (zero-based).

-- A range in a text document expressed as (zero-based) start and end positions.
---@class range
---@field start position The range's start position.
---@field end position The range's end position.

-- Represents a reference to a command.
---@class command
---@field command string The identifier of the actual command handler.
---@field title string Title of the command, like `save`.

-- A code lens represents a command that should be shown along with source text.
---@class code_lens
---@field command command? The command this code lens represents.
---@field range range The range in which this code lens is valid. Should only span a single line.

---@alias result code_lens[]

---@class response
---@field result result?

-- Plugin namespace for virtual type annotations.
local virtual_types_ns = vim.api.nvim_create_namespace("virtual_types")

-- Current plugin status.
local is_enabled = true

local M = {}

-- Clears the current buffer of virtual text.
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

-- Enables the plugin.
M.enable = function()
  is_enabled = true
  M.annotate_types_async()
end

-- Disables the plugin.
M.disable = function()
  is_enabled = false
  M.clear_namespace()
end

-- Adds type annotations (via textDocument/codeLens requests) to the buffer.
local annotate_types = function()
  if not is_enabled or #vim.lsp.get_active_clients() == 0 then
    return
  end
  -- Clear the buffer, otherwise duplicate annotations will get written
  M.clear_namespace()

  local parameters = vim.lsp.util.make_position_params(0, nil) ---@diagnostic disable-line:param-type-mismatch
  local responses = vim.lsp.buf_request_sync(0, "textDocument/codeLens", parameters) --[[ @as response[] ]]
  -- Set the virtual text for all valid code lens requests
  if responses then
    for _, response in pairs(responses) do
      if response and response.result then
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
end

-- Async wrapper for annotate_types, since 'textDocument/codeLens' call can freeze UI for ~0.2s.
M.annotate_types_async = function()
  vim.schedule(annotate_types)
end

-- Starts the plugin on the current buffer.
M.on_attach = function(client, _)
  if not client.supports_method("textDocument/codeLens") then
    local err = string.format('virtual-types.nvim: %s does not support "textDocument/codeLens" request.', client.name)
    vim.notify_once(err, vim.log.levels.WARN)
    return
  end

  -- perf: Don't use the async version, since it's slower on startup
  annotate_types()

  -- Setup autocommand to refresh the type annotations on certain events
  local virtual_types_augroup = vim.api.nvim_create_augroup("virtual_types_refresh", {})
  vim.api.nvim_create_autocmd({
    "BufEnter",
    "InsertLeave",
    "TextChanged",
  }, {
    buffer = 0,
    callback = M.annotate_types_async,
    group = virtual_types_augroup,
  })
end

return M
