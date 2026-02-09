" c++ syntax highlighting
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1

" autoformat on save
" autocmd BufWritePost <buffer> :ClangFormat

" TODO: linting https://chmanie.com/post/2020/07/17/modern-c-development-in-neovim/
" " linting
" let g:syntastic_cpp_checkers = ['cpplint']
" let g:syntastic_c_checkers = ['cpplint']
" let g:syntastic_cpp_cpplint_exec = 'cpplint'
" " The following two lines are optional. Configure it to your liking!
" let g:syntastic_check_on_open = 1
" let g:syntastic_check_on_wq = 0
