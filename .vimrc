" Plugins using vim-plug
call plug#begin()

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
let base16colorspace=256
colorscheme base16-ashes

highlight StatuslineGitBranch guifg=LightGreen
" full file path on status line
set statusline+=%F\ %#StatuslineGitBranch#%{FugitiveHead()}%*

lua << END
vim.lsp.log_level = vim.log.levels.ERROR

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
    documentation = { auto_show = true },
    list = {
      selection = {
        preselect = false,
        auto_insert = true,
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

-- Configure rust_analyzer using new vim.lsp.config API
vim.lsp.config('rust_analyzer', {
  cmd = { 'lspmux' },
  filetypes = { 'rust' },
  root_markers = {
    'rust-project.json',
    'WORKSPACE.bazel',
    'WORKSPACE',
    '.git',
    'Cargo.toml',
  },
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


local function java_root_dir(bufname)
  local path = bufname ~= "" and bufname or vim.api.nvim_buf_get_name(0)
  return vim.fs.root(path, { "BUILD.bazel", ".git", "mvnw", "gradlew" })
end

local function bazel_workspace(dir)
  return vim.fs.root(dir, { "WORKSPACE", "WORKSPACE.bazel" })
end

local function run_systemlist(cmd, cwd)
  local wrapped = cmd
  if cwd and cwd ~= "" then
    wrapped = "cd " .. vim.fn.shellescape(cwd) .. " && " .. cmd
  end
  local out = vim.fn.systemlist(wrapped)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out
end

local function find_bazel_target(package_dir, workspace_root)
  local rel = package_dir:sub(#workspace_root + 2)
  local lines = run_systemlist(
    "bzl query " .. vim.fn.shellescape("//" .. rel .. ":all") .. " --output=label_kind",
    workspace_root
  )
  if not lines then
    return nil
  end

  local function pick(preferred)
    for _, line in ipairs(lines) do
      local kind, label = line:match("^(%S+)%s+rule%s+(%S+)$")
      if kind and label and not kind:match("^_") and not label:match("%.classpath$") and preferred(kind) then
        return label
      end
    end
    return nil
  end

  return pick(function(kind) return kind:match("java_library$") end)
      or pick(function(kind) return kind:match("java") ~= nil end)
end

local function classpath_jars(workspace_root, target)
  local cp_target = target .. ".classpath"
  if not run_systemlist("bzl build " .. vim.fn.shellescape(cp_target), workspace_root) then
    return nil
  end

  local cp_files = run_systemlist(
    "bzl cquery " .. vim.fn.shellescape(cp_target) .. " --output=files",
    workspace_root
  )
  if not cp_files then
    return nil
  end

  local cp_rel = nil
  for _, line in ipairs(cp_files) do
    if line:match("^bazel%-bin/.+%.classpath$") or line:match("^bazel%-out/.+%.classpath$") then
      cp_rel = line
      break
    end
  end
  if not cp_rel then
    return nil
  end

  local ok, entries = pcall(vim.fn.readfile, workspace_root .. "/" .. cp_rel)
  if not ok then
    return nil
  end

  local jars = {}
  for _, entry in ipairs(entries) do
    if entry ~= "" then
      local abs
      if vim.startswith(entry, "../maven/") then
        abs = workspace_root .. "/bazel-bin/external/" .. entry:sub(4)
      else
        abs = workspace_root .. "/bazel-bin/" .. entry
      end
      if vim.fn.filereadable(abs) == 1 then
        table.insert(jars, abs)
      end
    end
  end
  return jars
end

local function write_if_changed(path, lines)
  local current = nil
  local ok, existing = pcall(vim.fn.readfile, path)
  if ok then
    current = table.concat(existing, "\n")
  end
  local desired = table.concat(lines, "\n")
  if current ~= desired then
    vim.fn.writefile(lines, path)
    return true
  end
  return false
end

local function write_eclipse_files(root_dir, jars)
  local project_name = vim.fn.fnamemodify(root_dir, ":t")
  local project_changed = write_if_changed(root_dir .. "/.project", {
    '<?xml version="1.0" encoding="UTF-8"?>',
    "<projectDescription>",
    "  <name>" .. project_name .. "</name>",
    "  <buildSpec><buildCommand>",
    "    <name>org.eclipse.jdt.core.javabuilder</name>",
    "  </buildCommand></buildSpec>",
    "  <natures><nature>org.eclipse.jdt.core.javanature</nature></natures>",
    "</projectDescription>",
  })

  local cp = { '<?xml version="1.0" encoding="UTF-8"?>', "<classpath>" }
  for _, rel in ipairs({ "src/main/java", "src/test/java", "src/benchmark/java" }) do
    if vim.fn.isdirectory(root_dir .. "/" .. rel) == 1 then
      table.insert(cp, '  <classpathentry kind="src" path="' .. rel .. '"/>')
    end
  end
  table.insert(cp, '  <classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>')
  for _, jar in ipairs(jars or {}) do
    table.insert(cp, '  <classpathentry kind="lib" path="' .. jar .. '"/>')
  end
  table.insert(cp, '  <classpathentry kind="output" path=".jdtls-bin"/>')
  table.insert(cp, "</classpath>")

  local classpath_changed = write_if_changed(root_dir .. "/.classpath", cp)
  return project_changed or classpath_changed
end

local function refresh_bazel_classpath(root_dir)
  local workspace_root = bazel_workspace(root_dir)
  if not workspace_root then
    return false
  end
  local target = find_bazel_target(root_dir, workspace_root)
  if not target then
    return false
  end
  local jars = classpath_jars(workspace_root, target)
  if not jars or #jars == 0 then
    return false
  end
  return write_eclipse_files(root_dir, jars)
end

local function restart_jdtls(cfg)
  for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
    client:stop()
  end
  vim.defer_fn(function()
    local ok, jdtls = pcall(require, "jdtls")
    if ok then
      jdtls.start_or_attach(cfg)
    end
  end, 500)
end

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "java",
--   callback = function(args)
--     local ok, jdtls = pcall(require, "jdtls")
--     if not ok then
--       vim.notify("nvim-jdtls is not installed", vim.log.levels.WARN)
--       return
--     end
--
--     local root = java_root_dir(vim.api.nvim_buf_get_name(args.buf))
--     if not root then
--       vim.notify("jdtls: could not detect project root", vim.log.levels.WARN)
--       return
--     end
--
--     local project_name = root:gsub("[/\\]", "-")
--     local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. project_name
--     local cfg = {
--       cmd = { "jdtls", "-data", workspace_dir },
--       root_dir = root,
--       on_attach = on_attach,
--       init_options = { bundles = {} },
--     }
--
--     jdtls.start_or_attach(cfg)
--
--     if refresh_bazel_classpath(root) then
--       vim.notify("[jdtls] wrote Eclipse classpath at " .. root .. ", restarting...", vim.log.levels.INFO)
--       restart_jdtls(cfg)
--     end
--   end,
-- })

pcall(vim.api.nvim_del_user_command, "JdtlsRefreshClasspath")
vim.api.nvim_create_user_command("JdtlsRefreshClasspath", function()
  local root = java_root_dir(vim.api.nvim_buf_get_name(0))
  if not root then
    return
  end
  refresh_bazel_classpath(root)

  local project_name = root:gsub("[/\\]", "-")
  local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. project_name
  restart_jdtls({
    cmd = { "jdtls", "-data", workspace_dir },
    root_dir = root,
    on_attach = on_attach,
    init_options = { bundles = {} },
  })
end, {})

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

" copy/paste to system clipboard with leader
vmap <Leader>y "+y
vmap <Leader>d "+d
nmap <Leader>p "+p
nmap <Leader>P "+P
vmap <Leader>p "+p
vmap <Leader>P "+P

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

function! s:repo_root(repo) abort
  " Resolve preferred repo root across dd worktrees and canonical clones.
  let l:candidates = []
  let l:cwd_anchor = <SID>repo_anchor(getcwd())

  " Prefer /dd checkouts first so local worktrees win over symlinked canonical paths.
  let l:cwd_tail = matchstr(getcwd(), '\v(dd-source|logs-backend)(-\d+)?$')
  let l:cwd_suffix = matchstr(l:cwd_tail, '-\d\+$')
  if !empty(l:cwd_suffix)
    call add(l:candidates, expand('~/dd/' . a:repo . l:cwd_suffix))
  endif
  call add(l:candidates, expand('~/dd/' . a:repo))

  let l:git_root = trim(system('git rev-parse --show-toplevel 2>/dev/null'))
  let l:git_suffix = matchstr(fnamemodify(l:git_root, ':t'), '-\d\+$')
  if !empty(l:git_suffix)
    call add(l:candidates, expand('~/dd/' . a:repo . l:git_suffix))
  endif
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
          \ 'prompt': 'assigner> ',
          \ 'files_prompt': 'assigner files> ',
          \ }
  endif

  return {
        \ 'root': <SID>repo_root('dd-source'),
        \ 'paths': 'domains/streaming libs/rust/observability domains/kafka',
        \ 'prompt': 'streaming> ',
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

nnoremap <leader>c :Cdbazelroot<CR>

" Cd to git root
command! Cdroot lua local bufdir = vim.fn.expand('%:p:h'); local cmd = bufdir ~= '' and ('git -C ' .. vim.fn.shellescape(bufdir) .. ' rev-parse --show-toplevel') or 'git rev-parse --show-toplevel'; local result = vim.fn.systemlist(cmd); if vim.v.shell_error == 0 and result[1] and result[1] ~= '' then vim.cmd('cd ' .. vim.fn.fnameescape(result[1])) else vim.notify('Not in a git repository', vim.log.levels.ERROR) end
" Cd to cargo root
command! Cdcargoroot lua local root=vim.fs.dirname(vim.fs.find('Cargo.toml',{path=vim.api.nvim_buf_get_name(0),upward=true})[1]); if root then vim.cmd('lcd '..vim.fn.fnameescape(root)) else vim.notify('Not in a cargo project', vim.log.levels.ERROR) end
command! Cdbazelroot lua local buf=vim.api.nvim_buf_get_name(0); local path=buf ~= '' and vim.fn.fnamemodify(buf,':p:h') or vim.fn.getcwd(); local builds=vim.fs.find('BUILD.bazel',{path=path,upward=true,limit=16}); if #builds == 0 then vim.notify('No BUILD.bazel found upward from current buffer', vim.log.levels.ERROR); return end; local idx=(#builds >= 2) and 2 or 1; local root=vim.fs.dirname(builds[idx]); vim.cmd('lcd '..vim.fn.fnameescape(root))

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
nnoremap <leader>d i<C-R>=strftime("## %Y-%m-%d %H:%M")<CR><CR><esc>

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

" Toggle File Explorer on Ctrl-g
nnoremap <C-g> :call NERDTreeToggleAndRefresh()<CR>

" Refresh file list every time its opened
function! NERDTreeToggleAndRefresh()
  :NERDTreeToggle
  if g:NERDTree.IsOpen()
    :NERDTreeRefreshRoot
  endif
endfunction

" find file in dir tree
nnoremap <leader>g :NERDTreeFind<CR>
let NERDTreeShowHidden=1

" Sort purely alphabetically, no dir/file grouping
let g:NERDTreeSortOrder = ['\/$', '*']

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
