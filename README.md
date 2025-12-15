# Let The Organisation Begin

### Featuring:
- Dotbot https://git.io/dotbot
- Vim
    - Vim Plug https://github.com/junegunn/vim-plug
    - python.vim (syntax highlighting) http://www.vim.org/scripts/script.php?script_id=790
    - Airline (status bar) https://github.com/vim-airline/vim-airline
    - Tmuxline (status bar) https://vimawesome.com/plugin/tmuxline-vim
- Tmux
    - Tmux Plugin Manager https://github.com/tmux-plugins/tpm
    - Tmux Resurrect https://github.com/tmux-plugins/tmux-resurrect
    - Tmux Continuum https://github.com/tmux-plugins/tmux-continuum



### Set it up
1) Recommend manually creating `~/.dotfiles` and cloning into it because git will put it in a non-dot file automatically. If you care.

`git clone <url of repo> ~/.dotfiles`

2) run `./install` from within `~/.dotfiles`. This will take care of symlinking your
dot files to where ever you specified (probably the home folder).


#### Tmux
Install tmux `brew install tmux` if you haven't installed it yet.
run `$ tmux source ~/.tmux.conf`

#### Vim
run `:PlugInstall in vim`


### Initial Dotbot setup

in case I ever have to start from scratch again

1) create the directory in which you would like to store your dot files
for example: `mkdir ~/.dotfiles`

2) move your dot files into that folder EXCLUDING the dot

`mv ~/.vimrc ~/.dotfiles/vimrc`

3) cd into `~/.dotfiles` and do the git init and submodule stuff as instructed in
the Dotbot readme

4) edit your `install.conf.yaml` as instructed in the readme

5) run `./install` from within `~/.dotfiles`. This will take care of symlinking your
dot files to where ever you specified (probably the home folder).

