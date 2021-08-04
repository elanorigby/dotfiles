# ----- SOURCE STUFF

if [ -f /usr/local/share/chruby/chruby.sh ]; then
source /usr/local/share/chruby/chruby.sh
fi

if [ -f /usr/local/share/chruby/auto.sh ]; then
source /usr/local/share/chruby/auto.sh
fi

if [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

if [ -f ~/.dotfiles/bash/workrc ]; then
    source ~/.dotfiles/bash/workrc
fi

if [ -f ~/.dotfiles/bash/prompt ]; then
    source ~/.dotfiles/bash/prompt
fi

# Vim mode in the command line
# set -o vi

now=$(date +"%m_%d_%Y")

# Better auto complete
# more like worse lol
# bind 'set show-all-if-ambiguous on'
# bind 'TAB:menu-complete'

# ----- ALIASES
alias notes='cd ~/notes/ && vim .'
alias newnote='cd ~/notes/ && vim new_$now.md'
alias la='ls -a'
alias ll='ls -al'
alias vimrc='vim ~/.vimrc'
alias bashrc='vim ~/.bashrc'
alias fy='fzf | yank'

# --- git aliases
alias current='git rev-parse --abbrev-ref HEAD'
alias glog="git log --graph --stat --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias grim='git fetch && git rebase -i origin/master'
alias grimain='git fetch && git rebase -i origin/main'
alias gitl='git log --oneline -5'

# ----- PATH JAZZ
# export PATH=$PATH:$(go env GOPATH)/bin
export PATH=$HOME/.dotfiles/bin:$PATH
export PATH=$PATH:$HOME/.cargo/env
export PATH=$PATH:$HOME/projects/terraform/bin
export PATH=$PATH:/Applications/Postgres.app/Contents/Versions/11/bin
export PATH=$PATH:$HOME/bin
# export GOPATH="$HOME/go"

# pyenv setup
export PATH="/Users/bigmac/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# ----- BEHAVIOR MODS

# mapping to have [Tab] and [Shift]+[Tab] to cycle through all the possible completions:
# "\t": menu-complete
# "\e[Z": menu-complete-backward


#------ DIRENV SHELL HOOK

#_direnv_hook() {
#  local previous_exit_status=$?;
#  eval "$("/usr/local/bin/direnv" export bash)";
#  return $previous_exit_status;
#};
#if ! [[ "${PROMPT_COMMAND:-}" =~ _direnv_hook ]]; then
#  PROMPT_COMMAND="_direnv_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
#fi

# ---- Work around MacOSX high sierra security shit for multithreading
#https://stackoverflow.com/questions/50168647/multiprocessing-causes-python-to-crash-and-gives-an-error-may-have-been-in-progr
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# NVM setup
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Yarn setup
# export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

_direnv_hook() {
  local previous_exit_status=$?;
  trap -- '' SIGINT;
  eval "$("/usr/local/bin/direnv" export bash)";
  trap - SIGINT;
  return $previous_exit_status;
};
if ! [[ "${PROMPT_COMMAND:-}" =~ _direnv_hook ]]; then
  PROMPT_COMMAND="_direnv_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
fi
