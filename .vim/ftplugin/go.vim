au FileType go set noexpandtab
au FileType go set shiftwidth=4
au FileType go set softtabstop=4
au FileType go set tabstop=4

"let g:go_auto_sameids = 1
let g:go_highlight_diagnostic_errors = 0

" disable vim-go :GoDef short cut (gd)
" this is handled by LanguageClient [LC]
let g:go_def_mapping_enabled = 0

" let g:go_fmt_command = "goimports"
nnoremap <Leader>l :GoImports<CR>

nnoremap <Leader>b :GoBuild<CR>

" go to next error in quickfix list
nnoremap <C-j> :cn<CR>
" go to previous error in quickfix list
nnoremap <C-k> :cp<CR>

" toggle between code/test file
nnoremap <C-x> :GoAlternate<CR>

" Search vendored files (OXIO only)
command! -bang VendorFiles call fzf#vim#files('src/vendor', <bang>0)
