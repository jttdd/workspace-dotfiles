set autowrite

let g:rustfmt_command = "rustfmt"
let g:rustfmt_options = "--config edition=2024"
let g:rustfmt_autosave = 1
let g:rustfmt_emit_files = 1
let g:rustfmt_fail_silently = 0

setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab

hi CursorLine   cterm=NONE ctermbg=darkblue ctermfg=white guibg=darkred guifg=white

" Helps reading docs
nnoremap <Leader>l :set cursorline!<CR>
