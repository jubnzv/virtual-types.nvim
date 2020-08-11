## virtual-types.nvim
This plugin shows type annotations for OCaml functions in virtual text, using built-in LSP client.

## Screenshot
![screenshot](./screenshot.png)

## Prerequisites
* Neovim nightly
* [nvim-lsp](https://github.com/neovim/nvim-lsp) plugin
* [ocaml-lsp](https://github.com/ocaml/ocaml-lsp) language server

## Installation

Install with your plugin manager:

```
Plug 'nvim-lua/diagnostic-nvim'
```

And add the following line in your LSP configuration:
```
lua require'nvim_lsp'.ocamllsp.setup{on_attach=require'virtualtypes'.on_attach}
```

