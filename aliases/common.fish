# alias executable
alias vi='vim'
alias vim='nvim'
alias tf='tail -F'
alias g='git'

# git
alias ga='git add'
alias gb='git branch'
# Shows branches with descriptions
alias gbl='bash $HOME/code/rcfiles/scripts/git-branch-list.sh'
alias gbu='git branch -u'
alias gco='git checkout'
function gcb
  git checkout -b jeff.lai/$argv
  git branch --edit-description
end
alias gcam='ga -A && git commit -a -m'
alias gca!='ga -A && git commit -a --amend --no-edit'

# git add all files from git status that matches the regex
function gadd
    git status --short | grep -i $1 | cut -d " " -f 3 | xargs git add
end

# shorthand for git push --set-upstream <remote> <branch_name>
function gpush
    set branch (git branch | grep \* | cut -d ' ' -f2)
    git push --set-upstream origin $branch
end

# Convert git https url to ssh url to use ssh key on clone operations
function gclone
   set repo (echo "$argv[1]" | sed "s/https:\/\//ssh:\/\/git\@/g")
   git clone $repo $argv[2]
end

# ls related
alias l='ls -l'
alias ll='ls -l'
alias la='ls -la'
alias lt='ls -lt'
alias ltr='ls -ltr'
alias ltra='ls -ltra'

#alias ls="ls --color=auto"
# Mac
alias lsg='ls -G'

# generates current timestamp in YYYYMMDDHHMMSS format
alias timestamp='date +%Y%m%d%H%M%S'

# turns a UUID string to mysql binary uuid you can put in a sql query
# asdf123-123-123-123 => 0xasdf123123123123
function uuid-mysql
  echo $argv | tr -d '-' | sed 's/^/0x/'
end

# kubectl
alias k='kubectl'

# ripgrep - glob on file path as well
# NOTE - this doesn't really work if there are whitespaces in the paths
function rgfiles
  set path $argv[1]
  set content $argv[2]
  rg --files | rg "$path" | xargs rg "$content"
end

# cd to git root
alias cdroot='cd (git rev-parse --show-toplevel)'
