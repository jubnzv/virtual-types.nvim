## virtual-types.nvim

This plugin shows type annotations as virtual text.

Most of the credit goes to [jubnzv](https://www.github.com/jubnzv), who wrote
the initial version of the plugin
[here](https://www.github.com/jubnzv/virtual-types.nvim).

## Screenshot

<div style="text-align: center">

![screenshot](https://user-images.githubusercontent.com/48545987/220223116-5a0edc7c-ffbf-41e1-8666-fe223fb9d88b.png)

</div>

## Prerequisites

- [Neovim 0.8+](https://github.com/neovim/neovim/releases)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- A LSP server that supports the
  [textDocument/codeLens](https://microsoft.github.io/language-server-protocol/specification#textDocument_codeLens)
  request

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use("kylechui/virtual-types.nvim")
```

And add the following line in your LSP configuration:

```lua
require("lspconfig").ocamllsp.setup({
    on_attach = function(client)
        require("virtualtypes").on_attach(client)
    end,
})
```
