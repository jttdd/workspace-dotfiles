" Plugins using vim-plug
call plug#begin()

" Git
Plug 'sindrets/diffview.nvim'

" completion (blink.cmp)
Plug 'Saghen/blink.cmp', { 'tag': 'v1.*' }
Plug 'neovim/nvim-lspconfig'
Plug 'ray-x/lsp_signature.nvim'

"rust
Plug 'rust-lang/rust.vim'
" go
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries', 'for': 'go' }
" java
Plug 'mfussenegger/nvim-jdtls'

" color schemes
Plug 'chriskempson/base16-vim'

" cool status bar
" tmux status bar integration
Plug 'edkolev/tmuxline.vim'

" tpope
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'

" FZF
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Always cd to root git dir of current buffer
" Plug 'airblade/vim-rooter'

" File Explorer
Plug 'preservim/nerdtree'

" Markdown
Plug 'img-paste-devs/img-paste.vim'

" OSC52 clipboard support for remote/tmux
Plug 'ojroques/vim-oscyank'

call plug#end()

" Fish doesn't play all that well with others
set shell=/bin/bash

" https://github.com/chriskempson/base16-vim
set termguicolors
colorscheme base16-ashes

function! DotfilesApplyThemeHighlights() abort
  " Base16 Ashes makes comments too close to the background for long editing sessions.
  highlight Comment guifg=#a7adba ctermfg=145
  highlight SpecialComment guifg=#b7beca ctermfg=146
endfunction

" Give blink docs a softer pastel surface without changing the main theme.
function! DotfilesApplyBlinkHighlights() abort
  highlight BlinkCmpDoc guifg=#d8dee9 guibg=#2b303b ctermfg=253 ctermbg=236
  highlight BlinkCmpDocBorder guifg=#a3be8c guibg=#2b303b ctermfg=151 ctermbg=236
  highlight BlinkCmpDocSeparator guifg=#8fbcbb guibg=#2b303b ctermfg=109 ctermbg=236
  highlight BlinkCmpKind guifg=#b48ead ctermfg=139
  highlight BlinkCmpKindFunction guifg=#88c0d0 ctermfg=110
  highlight BlinkCmpKindMethod guifg=#81a1c1 ctermfg=109
  highlight BlinkCmpKindClass guifg=#a3be8c ctermfg=151
  highlight BlinkCmpKindInterface guifg=#8fbcbb ctermfg=109
  highlight BlinkCmpLabelDetail guifg=#ebcb8b ctermfg=223
  highlight BlinkCmpLabelDescription guifg=#d8dee9 ctermfg=253
endfunction

augroup dotfiles_blink_highlights
  autocmd!
  autocmd ColorScheme * call DotfilesApplyThemeHighlights()
  autocmd ColorScheme * call DotfilesApplyBlinkHighlights()
augroup END

call DotfilesApplyThemeHighlights()
call DotfilesApplyBlinkHighlights()

highlight StatuslineGitBranch guifg=LightGreen
" full file path on status line
set statusline+=%F\ %#StatuslineGitBranch#%{FugitiveHead()}%*
set statusline+=%{luaeval('_G.dotfiles_lsp_statusline()')}

lua << END
vim.lsp.log_level = vim.log.levels.ERROR
local lspconfig_util = require("lspconfig.util")

local lsp_statusline = ""

function _G.dotfiles_lsp_statusline()
  if lsp_statusline == "" then
    return ""
  end
  return " " .. lsp_statusline
end

local default_progress_handler = vim.lsp.handlers["$/progress"]

vim.lsp.handlers["$/progress"] = function(err, result, ctx, config)
  if default_progress_handler then
    default_progress_handler(err, result, ctx, config)
  end

  local value = result and result.value
  if type(value) ~= "table" then
    return
  end

  local parts = {}
  if type(value.title) == "string" and value.title ~= "" then
    table.insert(parts, value.title)
  end
  if type(value.message) == "string" and value.message ~= "" then
    table.insert(parts, value.message)
  end
  if type(value.percentage) == "number" then
    table.insert(parts, string.format("%d%%", value.percentage))
  end

  if value.kind == "end" then
    lsp_statusline = ""
  else
    lsp_statusline = table.concat(parts, " ")
  end

  vim.cmd("redrawstatus")
end

require('blink.cmp').setup({
  keymap = {
    preset = 'none',
    ['<Tab>'] = { 'show', 'select_next', 'fallback' },
    ['<S-Tab>'] = { 'select_prev', 'fallback' },
    ['<Down>'] = { 'select_next', 'fallback' },
    ['<Up>'] = { 'select_prev', 'fallback' },
    ['<CR>'] = { 'select_and_accept', 'fallback' },
    ['<C-Space>'] = { 'show', 'fallback' },
    ['<C-e>'] = { 'hide', 'fallback' },
    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
  },
  sources = {
    default = { 'lsp', 'path', 'buffer' },
  },
  completion = {
    documentation = {
      auto_show = true,
      treesitter_highlighting = false,
      window = { border = 'rounded' },
    },
    list = {
      selection = {
        preselect = true,
        auto_insert = false,
      },
    },
  },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

-- Set blink.cmp capabilities for all LSP servers
vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities({}, true),
})

local on_attach = function(client, bufnr)

   -- Get signatures (and _only_ signatures) when in argument lists.
  require "lsp_signature".on_attach({
    doc_lines = 0,
    handler_opts = {
      border = "none"
    },
  })

  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(opt, value)
    vim.api.nvim_set_option_value(opt, value, { buf = bufnr })
  end

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>a', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
  buf_set_keymap('n', '<C-p>', '<cmd>lua vim.diagnostic.jump({count = -1})<CR>', opts)
  buf_set_keymap('n', '<C-n>', '<cmd>lua vim.diagnostic.jump({count = 1})<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
  -- buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  buf_set_keymap('n', '<space>h', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)


  -- Forward to other plugins
  -- require'completion'.on_attach(client)
end

_G.dotfiles_lsp_on_attach = on_attach

local function git_root()
  local ok, out = pcall(vim.fn.systemlist, "git rev-parse --show-toplevel")
  if not ok or vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
    return nil
  end
  return out[1]
end

local function copy_path_range(start_line, end_line)
  local abs = vim.fn.expand("%:p")
  local root = git_root()
  local rel = abs

  if root and abs:sub(1, #root) == root then
    rel = abs:sub(#root + 2) -- strip "<root>/"
  else
    rel = vim.fn.expand("%:.") -- relative to cwd as fallback
  end

  local result = string.format("@%s#L%d-%d", rel, start_line, end_line)

  -- Copy to system clipboard (OSC52 handled by clipboard provider)
  vim.fn.setreg("+", result)
  vim.notify(string.format("Copied: %s", result), vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("CopyPathRange", function(opts)
  local s, e = opts.line1, opts.line2
  if s > e then s, e = e, s end
  copy_path_range(s, e)
end, { range = true, desc = "Copy file path with line range" })


vim.keymap.set("v", "<C-l>", [[:CopyPathRange<CR>]], { desc = "Copy file path with line range" })

local root_dir = vim.fn.getcwd()

local function rust_root_dir(bufnr, on_dir)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local root = lspconfig_util.root_pattern("rust-project.json")(fname)
    or lspconfig_util.find_git_ancestor(fname)
    or lspconfig_util.root_pattern("Cargo.toml")(fname)
  on_dir(root)
end

-- Configure rust_analyzer using new vim.lsp.config API
vim.lsp.config('rust_analyzer', {
  cmd = { 'lspmux', 'client', '--server-path', 'rust-analyzer' },
  filetypes = { 'rust' },
  root_dir = rust_root_dir,
  on_attach = on_attach,
  settings = {
    ["rust-analyzer"] = {
      check = {
        command = "clippy",
      },
      cargo = {
        targetDir = true,
        cfgs = { "test" },
      },
      -- files = {
      --   excludeDirs = {
      --     "node_modules",
      --     "vendor",
      --     "bazel-*",
      --     "bazel-bin",
      --     "bazel-out",
      --     "bazel-testlogs",
      --     ".git",
      --   },
      -- },
    }
  }
})

-- Enable rust_analyzer
vim.lsp.enable('rust_analyzer')

-- custom for libstreaming go bindings
local include_path = root_dir .. "/include"

-- Configure gopls using new vim.lsp.config API
vim.lsp.config('gopls', {
    cmd = { "dd-gopls" },
    cmd_env = {
      CGO_ENABLED = "1",
      CGO_CFLAGS = "-I" .. include_path,
      CC = "/usr/bin/clang",
      GOPLS_DISABLE_MODULE_LOADS = "1",
    },
    filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
    root_markers = { 'go.work', 'go.mod', '.git' },
    on_attach = on_attach,
    settings = {
      gopls = {
        directoryFilters = {
          "-**/node_modules",
          "-**/vendor",
          "-**/bazel-*",
          "-**/bazel-bin",
          "-**/bazel-out",
          "-**/bazel-testlogs",
          "-**/.git",
        },
        analyses = {
          unusedparams = false,
          shadow = false,
          nilness = false,
        },
        staticcheck = false,
      },
    }
  })

-- Enable gopls
vim.lsp.enable('gopls')


vim.diagnostic.config({
  virtual_text = true,   -- show diagnostics inline
  signs = true,          -- show signs in the sign column
  underline = true,      -- underline problematic code
  update_in_insert = false,
  severity_sort = true,
})

END

set timeoutlen=1000 ttimeoutlen=0

set hidden
set cmdheight=2

" Sane splits
set splitright
set splitbelow

autocmd BufReadPost *.rs setlocal filetype=rust

set ffs=unix

" make highlight matching brackets easier to read
hi MatchParen cterm=none ctermbg=LightRed ctermfg=black guibg=#FFB3B3 guifg=#000000

" make visual selection background light orange
hi Visual cterm=none ctermbg=223 ctermfg=black guibg=#FFD8A8 guifg=#000000

" make pop up menu easier to read
hi Pmenu ctermbg=black ctermfg=white guibg=#2C2C2C guifg=#FFFFFF
hi PmenuSel ctermbg=blue ctermfg=white guibg=#005FFF guifg=#FFFFFF


" show whitespace
set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<

" fzf
set rtp+=~/.fzf

" spellchecker
set spell

" Set <Leader> to space for easier key combinations
let mapleader = "\<Space>"

" Save with ctrl + s
nnoremap <C-s> :w<CR>
nnoremap <Leader>v :vsplit<CR>

" copy/paste to system clipboard with leader
vmap <Leader>y "+y
vmap <Leader>d "+d
nmap <Leader>p "+p
nmap <Leader>P "+P
vmap <Leader>p "+p
vmap <Leader>P "+P

nnoremap <Leader>d :DiffviewOpen<CR>

" Use system clipboard
set clipboard=unnamedplus

" toggle between show whitepace
" nmap <Leader>l :set list!<CR>

" Use rg for file name search
let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --glob "!.git"'
nnoremap <Leader>n :FZF<CR>
nnoremap <Leader>m :Files `git rev-parse --show-toplevel`<CR>

function! s:files_git_root()
  let l:root = trim(system('git rev-parse --show-toplevel 2>/dev/null'))
  if empty(l:root)
    let l:root = getcwd()
  endif
  execute 'Files ' . fnameescape(l:root)
endfunction

function! s:add_repo_candidates(candidates, repo, anchor) abort
  " Derive sibling repo paths from an anchor repo/worktree path.
  if empty(a:anchor)
    return
  endif
  let l:repo_name = fnamemodify(a:anchor, ':t')
  let l:parent = fnamemodify(a:anchor, ':h')
  let l:suffix = matchstr(l:repo_name, '-\d\+$')

  if l:repo_name =~# '^' . a:repo . '\%(-\d\+\)\?$'
    call add(a:candidates, a:anchor)
  endif
  if !empty(l:suffix)
    call add(a:candidates, l:parent . '/' . a:repo . l:suffix)
  endif
  call add(a:candidates, l:parent . '/' . a:repo)
endfunction

function! s:repo_anchor(path) abort
  " Find the nearest dd-source/logs-backend repo folder in a path chain.
  let l:dir = a:path
  while l:dir !=# '/' && !empty(l:dir)
    let l:base = fnamemodify(l:dir, ':t')
    if l:base =~# '^\%(dd-source\|logs-backend\)\%(-\d\+\)\?$'
      return l:dir
    endif
    let l:next = fnamemodify(l:dir, ':h')
    if l:next ==# l:dir
      break
    endif
    let l:dir = l:next
  endwhile
  return ''
endfunction

function! s:repo_suffix(path) abort
  " Prefer the anchored repo name so numbered worktrees still resolve from subdirs.
  let l:anchor = <SID>repo_anchor(a:path)
  let l:name = empty(l:anchor) ? fnamemodify(a:path, ':t') : fnamemodify(l:anchor, ':t')
  return matchstr(l:name, '-\d\+$')
endfunction

function! s:repo_root(repo) abort
  " Resolve preferred repo root across dd worktrees and canonical clones.
  let l:candidates = []
  let l:cwd_anchor = <SID>repo_anchor(getcwd())

  " Prefer /dd checkouts first so local worktrees win over symlinked canonical paths.
  let l:cwd_suffix = <SID>repo_suffix(getcwd())
  if !empty(l:cwd_suffix)
    call add(l:candidates, expand('~/dd/' . a:repo . l:cwd_suffix))
  endif

  let l:git_root = trim(system('git rev-parse --show-toplevel 2>/dev/null'))
  let l:git_suffix = <SID>repo_suffix(l:git_root)
  if !empty(l:git_suffix)
    call add(l:candidates, expand('~/dd/' . a:repo . l:git_suffix))
  endif
  call add(l:candidates, expand('~/dd/' . a:repo))
  " Then try sibling repos relative to cwd/git anchors, plus global fallbacks.
  call <SID>add_repo_candidates(l:candidates, a:repo, l:cwd_anchor)
  call <SID>add_repo_candidates(l:candidates, a:repo, l:git_root)

  if exists('$DATADOG_ROOT') && !empty($DATADOG_ROOT)
    call add(l:candidates, $DATADOG_ROOT . '/' . a:repo)
  endif
  call add(l:candidates, expand('~/go/src/github.com/DataDog/' . a:repo))

  let l:seen = {}
  for l:path in l:candidates
    if empty(l:path) || has_key(l:seen, l:path)
      continue
    endif
    let l:seen[l:path] = 1
    if isdirectory(l:path)
      return l:path
    endif
  endfor

  if !empty(l:git_root)
    return l:git_root
  endif
  return getcwd()
endfunction

function! s:streaming_search_spec() abort
  let l:anchor = <SID>repo_anchor(getcwd())
  let l:repo_name = empty(l:anchor) ? '' : fnamemodify(l:anchor, ':t')

  if l:repo_name =~# '^logs-backend\%(-\d\+\)\?$'
    return {
          \ 'root': <SID>repo_root('logs-backend'),
          \ 'paths': 'domains/streaming/apps/streaming-assigner domains/streaming/libs/streaming-assigner domains/streaming/libs/streaming-assigner-commons domains/streaming/libs/streaming-assigner-grpc-client',
          \ 'prompt': 'streaming contents> ',
          \ 'files_prompt': 'streaming files> ',
          \ }
  endif

  return {
        \ 'root': <SID>repo_root('dd-source'),
        \ 'paths': 'domains/streaming libs/rust/observability domains/kafka',
        \ 'prompt': 'streaming contents> ',
        \ 'files_prompt': 'streaming files> ',
        \ }
endfunction

nnoremap <leader>r :call <SID>files_git_root()<CR>

" Global file content search
nnoremap <C-f> :Rg<CR>

function! s:rg_streaming()
  let l:spec = <SID>streaming_search_spec()
  call fzf#vim#grep(
        \ 'rg --column --line-number --no-heading --color=always --smart-case -- "" ' . l:spec.paths,
        \ 1,
        \ fzf#vim#with_preview({'dir': l:spec.root, 'options': ['--prompt', l:spec.prompt]}),
        \ 0)
endfunction

nnoremap <leader>f :call <SID>rg_streaming()<CR>

function! s:files_streaming()
  let l:spec = <SID>streaming_search_spec()
  let l:source_cmd = 'rg --files --hidden --glob "!.git" ' . l:spec.paths
  call fzf#run(fzf#wrap({
        \ 'source': l:source_cmd,
        \ 'dir': l:spec.root,
        \ 'options': ['--prompt', l:spec.files_prompt, '--preview', 'bat --color=always --style=numbers --line-range=:500 {}']
        \ }))
endfunction

" Keybinding: <leader>fs
nnoremap <leader>F :call <SID>files_streaming()<CR>

" fzf-powered cd. either from cwd
command! -nargs=0 FZFCD call fzf#run({
  \ 'source': 'find . -type d',
  \ 'sink':   'cd',
  \ 'options': '--prompt "cd> "'
  \ })

lua << END
function _G.dotfiles_current_buffer_bazel_root()
  local path = vim.fn.expand('%:p:h')
  if path == '' then
    path = vim.fn.getcwd()
  end

  while path and path ~= '' do
    if vim.uv.fs_stat(path .. '/BUILD.bazel') or vim.uv.fs_stat(path .. '/BUILD') then
      return path
    end

    local parent = vim.fs.dirname(path)
    if not parent or parent == path then
      break
    end
    path = parent
  end

  return nil
end
END

nnoremap <leader>c :Cdbazelroot<CR>

" Cd to git root
command! Cdroot lua local bufdir = vim.fn.expand('%:p:h'); local cmd = bufdir ~= '' and ('git -C ' .. vim.fn.shellescape(bufdir) .. ' rev-parse --show-toplevel') or 'git rev-parse --show-toplevel'; local result = vim.fn.systemlist(cmd); if vim.v.shell_error == 0 and result[1] and result[1] ~= '' then vim.cmd('cd ' .. vim.fn.fnameescape(result[1])) else vim.notify('Not in a git repository', vim.log.levels.ERROR) end
" Cd to cargo root
command! Cdcargoroot lua local root=vim.fs.dirname(vim.fs.find('Cargo.toml',{path=vim.api.nvim_buf_get_name(0),upward=true})[1]); if root then vim.cmd('lcd '..vim.fn.fnameescape(root)) else vim.notify('Not in a cargo project', vim.log.levels.ERROR) end
command! Cdbazelroot lua local root=_G.dotfiles_current_buffer_bazel_root(); if root then vim.cmd('lcd '..vim.fn.fnameescape(root)) else vim.notify('No BUILD.bazel found upward from current buffer', vim.log.levels.ERROR) end

" Open last buffer with space space
nnoremap <Leader><Leader> :b#<CR>

" Previous buffer
nnoremap <Leader>i :bp<CR>
" Next buffer
nnoremap <Leader>o :bn<CR>
" Show buffers
nmap <leader>; :Buffers<CR>
" List buffers
nnoremap <leader>; :Buffers<CR>

" Clear search highlight
nnoremap <C-h> :noh<CR>

" Go to start of outer {
nnoremap <C-l> [{

" When you insert a { and hit Enter,
" it inserts the closing bracket and places the cursor on a new line between the pair
" inoremap {<CR> {<CR>}<C-o>O

" Mis-caps
map :Q :q
map :W :w
map :Wq :wq

" Yank/Paste to a buffer. Useful for replacing multiple places
vmap Y "ay
nmap P "ap

" Necesary  for lots of cool vim things
set nocompatible

" Insert markdown heading with current datetime
nnoremap <leader>t i<C-R>=strftime("## %Y-%m-%d %H:%M")<CR><CR><esc>

" Open current file in github
nmap <Leader>gh :GBrowse<CR>
nnoremap <Leader>b :GBrowse!<CR>
xnoremap <Leader>b :GBrowse!<CR>

" This shows what you are typing as a command.
set showcmd

set shell=/usr/bin/fish

" Needed for Syntax Highlighting and stuff
filetype on " turn on file type detection
filetype plugin on
syntax enable
syntax on
set foldmethod=indent
set foldlevelstart=99
set foldnestmax=10
nnoremap - za

" search visual selection with //
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>

" Who wants an 8 character tab?  Not me!
set tabstop=2
set softtabstop=2
set shiftwidth=2
" Get rid of tabs altogether and replace with spaces
set expandtab
" 2 space indent for js, mark max column length
autocmd FileType javascript setlocal shiftwidth=2 softtabstop=2 tabstop=2 colorcolumn=120
" remove trailing whitespace on :w
autocmd BufWritePre * %s/\s\+$//e

" Automatically save file on :make
set autowrite

" Automatically read file with updates
set autoread
" More aggressive auto-reload for external file changes (e.g., from agents)
augroup AutoReload
  autocmd!
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI,WinEnter * :silent! checktime
  autocmd FileChangedShellPost * echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None
augroup END
" Check for file changes every 500ms when idle (more responsive for agent edits)
set updatetime=500

" Cool tab completion stuff
set wildmenu
set wildmode=list:longest,full

" Let backspace delete autoindents, eol (\n\r), and text that was inserted
" before the start of the INSERT mode session
set backspace=indent,eol,start

" Set relative line numbers and show the absolute current line number
set relativenumber
set number

" Incremental searching is sexy
set incsearch

" Highlight things that we find with the search
set hlsearch

" case insensitive search by default, switch to case sensitive by using
" capital letters
set ignorecase
set smartcase

" Always keep the cursor vertically centered
set scrolloff=999

" show the cursor position all the time
set ruler

" Automatically write when switching buffers
set confirm

" Do not redraw screen in the middle of a macro. Makes them complete faster.
set lazyredraw

" Persistent undo, even if you close and reopen Vim.
set undodir=$HOME/.vim/undo
set undofile

" Auto cd to current dir of file
let g:rooter_change_directory_for_non_project_files = 'current'

" No swap files
set noswapfile

" Restore cursor position to where it was before
augroup JumpCursorOnEdit
   au!
   autocmd BufReadPost *
            \ if expand("<afile>:p:h") !=? $TEMP |
            \   if line("'\"") > 1 && line("'\"") <= line("$") |
            \     let JumpCursorOnEdit_foo = line("'\"") |
            \     let b:doopenfold = 1 |
            \     if (foldlevel(JumpCursorOnEdit_foo) > foldlevel(JumpCursorOnEdit_foo - 1)) |
            \        let JumpCursorOnEdit_foo = JumpCursorOnEdit_foo - 1 |
            \        let b:doopenfold = 2 |
            \     endif |
            \     exe JumpCursorOnEdit_foo |
            \   endif |
            \ endif
   " Need to postpone using "zv" until after reading the modelines.
   autocmd BufWinEnter *
            \ if exists("b:doopenfold") |
            \   exe "normal zv" |
            \   if(b:doopenfold > 1) |
            \       exe  "+".1 |
            \   endif |
            \   unlet b:doopenfold |
            \ endif
augroup END

command! -range=% HexRust <line1>,<line2>s/\v<([0-9A-Fa-f]{2})>/0x\1/g

" Auto save whenever text is changed
" autocmd TextChanged,TextChangedI <buffer> silent write

" Toggle File Explorer on Ctrl-g rooted at the current buffer's Bazel root
nnoremap <C-g> :call NERDTreeToggleBazelRoot()<CR>

" Refresh file list every time its opened
function! NERDTreeToggleBazelRoot()
  let l:root = luaeval('_G.dotfiles_current_buffer_bazel_root()')
  if empty(l:root)
    echoerr 'No BUILD.bazel found upward from current buffer'
    return
  endif

  if g:NERDTree.IsOpen()
    let l:tree = g:NERDTree.ForCurrentTab()
    if !empty(l:tree) && l:tree.getRoot().path.str() ==# l:root
      NERDTreeClose
      return
    endif
  endif

  execute 'NERDTree' fnameescape(l:root)
endfunction

" find file in dir tree
nnoremap <leader>g :NERDTreeFind<CR>
let NERDTreeShowHidden=1

" Sort purely alphabetically, with files and directories interleaved by name
let g:NERDTreeSortOrder = []

" File explorer tree list view
let g:netrw_liststyle = 3
" Remove netrw banner
let g:netrw_banner = 0
" Open files in new tab
let g:netrw_browse_split = 3
" Width of explorer in terms of page percentage
let g:netrw_winsize = 25

" Allow JSX in normal JS files
let g:jsx_ext_required = 0

" FIXME: Format json with :FormatJson
com! -range FormatJson <line1>,<line2>!python3 -m json.tool

" Replace selection with base64 decoded string
:vnoremap <leader>64 c<c-r>=system('base64 --decode', @")<cr><esc>

" project level vimrc files: https://www.alexeyshmalko.com/2014/using-vim-as-c-cpp-ide/
set exrc
set secure

" https://github.com/img-paste-devs/img-paste.base16-vim
autocmd FileType markdown nmap <buffer><silent> <leader>p :call mdip#MarkdownClipboardImage()<CR>

" Open markdown files with VSCode.
autocmd BufEnter *.md exe 'noremap <leader>m :!code %:p<CR>'


" Copy the git commit hash in the fugitive commit diff buffer
command! GDiffCommit execute {
       \ 'let l:sha = matchstr(expand(''%:t''), ''\v[0-9a-f]{7,40}'')' .
       \ '| if empty(l:sha) | echoerr "No commit hash found" | else | let @+ = l:sha | echo "Copied " . l:sha | endif'


" -------------------------------------------------------------------------------------------------
" end coc.nvim default settings
" -------------------------------------------------------------------------------------------------

" For reference: sub to strip trailing whitespace
" % -> do on whole file
" s -> substution
" \s -> matches whitespace
" \+ -> matches 1 or more characters
" $ -> matches end of line
" e -> suppress error messages (no matches)
" :%s/\s\+$//e

" For reference: delete all blank lines
" :g -> global command (on whole file)
" ^ -> matches beginning of line
" $ -> matches end of line
" d -> delete all matches
" :g/^$/d
