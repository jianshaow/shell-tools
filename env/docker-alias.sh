#!/bin/bash

alias dc='docker compose'
alias di='docker images'
alias dp='docker ps'

if [ -f /usr/share/bash-completion/completions/docker ]; then
    . /usr/share/bash-completion/completions/docker
    complete -o default -F _docker dc
fi
