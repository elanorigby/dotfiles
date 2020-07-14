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

now=$(date +"%m_%d_%Y")

# ----- ALIASES
alias notes='cd ~/notes/ && vim .'
alias newnote='cd ~/notes/ && vim new_$now.md'
alias la='ls -a'
alias ll='ls -al'
alias glog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias glat="git log --stat"
alias grim='git fetch && git rebase -i origin/master'
alias vimrc='vim ~/.vimrc'
alias bashrc='vim ~/.bashrc'
alias current='git rev-parse --abbrev-ref HEAD'

# ----- PATH JAZZ
export PATH=$PATH:$(go env GOPATH)/bin
export PATH=$HOME/.dotfiles/bin:$PATH
export PATH=$PATH:$HOME/.cargo/env
export PATH=$PATH:$HOME/projects/terraform/bin

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
chruby 2.6.2

# NVM setup
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Yarn setup
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
