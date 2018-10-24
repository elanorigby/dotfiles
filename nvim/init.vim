set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

" this is a neovim thing that Oni uses

" from default recommends at
" https://github.com/onivim/oni/wiki/How-To:-Minimal-Oni-Configuration"
"set nocompatible
"filetype off "
"set number
"set noswapfile
"set smartcase
"
"
"
"" Turn off statusbar, because it is externalized
"set noshowmode
"set noruler
"set laststatus=0
"set noshowcmd
"
"" enable GUI mouse behavior
"set mouse=a
"
"
"" ------ my stuff
"
"" enter adds blank line below cursor, does not enter insert mode
"" map <Enter> o<ESC>
"" shift-enter adds blank line below cursor, does not enter insert
"map <S-Enter> O<ESC>
"
"imap jk <ESC>
"
"set tabstop=2
"
