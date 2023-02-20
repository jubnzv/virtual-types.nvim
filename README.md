## virtual-types.nvim

This plugin shows type annotations as virtual text.

## Screenshot

![screenshot](./screenshot.png)

## Prerequisites

- [Neovim 0.8+](https://github.com/neovim/neovim/releases)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) plugin
- A LSP server that supports the
  [textDocument/codeLens](https://microsoft.github.io/language-server-protocol/specification#textDocument_codeLens)
  request

## Installation

Install with plugin manager:

```
Plug 'jubnzv/virtual-types.nvim'
```

And add the following line in your LSP configuration:

```
lua require'nvim_lsp'.ocamllsp.setup{on_attach=require'virtualtypes'.on_attach}
```
