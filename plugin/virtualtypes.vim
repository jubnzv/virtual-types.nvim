if exists('g:virtualTypes_loaded') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

hi TypeAnnot guifg=#7c6f64

command! EnableVirtualTypes lua require'virtualtypes'.enable()
command! DisableVirtualTypes lua require'virtualtypes'.disable()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:virtualTypes_loaded = 1
