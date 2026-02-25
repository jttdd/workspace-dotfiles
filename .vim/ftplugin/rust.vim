set autowrite

let g:rustfmt_command = "rustup run rustfmt -- --edition=2024"
let g:rustfmt_autosave = 1
let g:rustfmt_emit_files = 1
let g:rustfmt_fail_silently = 1

hi CursorLine   cterm=NONE ctermbg=darkblue ctermfg=white guibg=darkred guifg=white

" Helps reading docs
nnoremap <Leader>l :set cursorline!<CR>
