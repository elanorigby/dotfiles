# Let The Organisation Begin

### Featuring:
- Dotbot https://git.io/dotbot
- Vim
    - Vim Plug https://github.com/junegunn/vim-plug
    - python.vim (syntax highlighting) http://www.vim.org/scripts/script.php?script_id=790
    - Airline (status bar) https://github.com/vim-airline/vim-airline
    - Tmuxline (status bar) https://vimawesome.com/plugin/tmuxline-vim


#### TODO:
figure out how to elegantly resolve differences between my mac's bashrc and
bash_profile and my linux machines'. 


### How to Set up with Dotbot

1) create the directory in which you would like to store your dot files
for example: mkdir ~/.dotfiles

2) move your dot files into that folder EXCLUDING the dot
mv ~/.vimrc ~/.dotfiles/vimrc

3) cd into ~/.dotfiles and do the git init and submodule stuff as instructed in
the Dotbot readme

4) edit your install.conf.yaml as instructed in the readme

5) run ./install from within ~/.dotfiles. This will take care of symlinking your
dot files to where ever you specified (probably the home folder).

6) git. commit. that shit.


### Set up Dotbot sync with remote repo

1) create the directory in which you would like to store your dot files and
clone your remote dotfile repo into it

`git clone <url of repo> ~/.dotfiles`

2) run ./install from within ~/.dotfiles. This will take care of symlinking your dot files to where ever you specified (probably the home folder).

#### Tmux
run `$ tmux source ~/.tmux.conf`

#### Vim
run `:PlugInstall in vim`


