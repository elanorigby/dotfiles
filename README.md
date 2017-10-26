# Let The Organisation Begin

### Featuring:
Dotbot
Vim
- Vim Plug
- python.vim (syntax highlighting)


### TODO:
figure out how to elegantly resolve differences between my mac's bashrc and
bash_profile and my linux machines'. 


#### How to Set up with Dotbot

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

