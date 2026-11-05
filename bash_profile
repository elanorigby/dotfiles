export PATH="/usr/local/bin:$PATH"

if [ -f ~/.bashrc ]; then                                                            
 source ~/.bashrc                                                                
fi 
source ~/.bashrc

if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
fi

#for poetry
export PATH="$HOME/.local/bin:$PATH"

# source ~/.dbt-completion.bash
# export PATH="/usr/local/opt/node@12/bin:$PATH"
# . "$HOME/.cargo/env"

# Created by `pipx` on 2021-12-29 16:25:25
export PATH="$PATH:/Users/bigmac/.local/bin"

eval "$(/opt/homebrew/bin/brew shellenv)"

# added by Snowflake SnowSQL installer v1.2
export PATH=/Applications/SnowSQL.app/Contents/MacOS:$PATH


# added for SnowCD
export PATH=/opt/snowflake/snowcd:$PATH

# dotnet (installed via Homebrew)
export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"

# added by Snowflake SnowflakeCLI installer v1.0
export PATH=/Applications/SnowflakeCLI.app/Contents/MacOS/:$PATH

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

