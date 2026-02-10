#!/bin/bash

# List all git branchs in repo with their descriptions 
branches=$(git for-each-ref --format='%(refname)' refs/heads/ | sed 's|refs/heads/||')
for b in $branches; do
desc=$(git config branch.$b.description)
if [[ $b == $(git rev-parse --abbrev-ref HEAD) ]]; then
   b="* \033[0;32m$b\033[0m"
else
   b="  $b"
fi

if [ -n "$desc" ]; then
    b="$b -"
fi
echo -e "$b \033[0;36m$desc\033[0m"
done
