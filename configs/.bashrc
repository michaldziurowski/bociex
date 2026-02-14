# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

alias l='ls'
alias ll='ls'
alias la='ls -a'
alias v='nvim'

function gimme-aws-creds() {
        docker run --rm \
                --user $(id -u):$(id -g) \
                --network host \
                --volume ${HOME}/.okta_aws_login_config:/.okta_aws_login_config \
                --volume ${HOME}/.aws/credentials:/.aws/credentials \
                -it devopsinfra/docker-okta-aws-sso:latest "$@"
}

export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"

export PATH="$PATH:$(go env GOPATH)/bin"

export PATH="$HOME/.local/bin:$PATH"

export AWS_REGION=eu-west-1

eval "$(direnv hook bash)"
