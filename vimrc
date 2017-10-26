
"         __   _____ __  __ ___  ___ 
"  ------ \ \ / /_ _|  \/  | _ \/ __| ---------
" -------- \ V / | || |\/| |   / (__  --------------
"  -------- \_/ |___|_|  |_|_|_\\___| -----------------
                             

""""""""""""""""" PILBO PLUGGINS """"""""""""""""""""""""""""""""""""
" Vim Plug 
call plug#begin('~/.vim/pluggins')

" syntax highlighting for python
Plug '~/.vim/pluggins/python.vim'

" status bar
Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'


call plug#end()

"""""""""""""""" NORMAL MODE HACKS """"""""""""""""""""""""""""""""""

" enter adds blank line below cursor, does not enter insert mode
map <Enter> o<ESC>
" shift-enter adds blank line above cursor, does not enter insert
map <S-Enter> O<esc>


""""""""""""""""" PYTHON SYNTAX STUFF """"""""""""""""""""""""""""""""

" line length and indent (for python) (from hitchhiker's, adjusted to google style guide)
" google style: 80 lines, 4 space indent, 
syntax on           " turn on syntax highlighting
set textwidth=80    " lines longer than 80 columns will be broken
set shiftwidth=4    " operation >> indents 4 columns; << unindents 4 columns
set tabstop=4       " a hard TAB displays as 4 columns
set expandtab       " insert spaces when hitting TABs
set softtabstop=4   " insert/delete 4 spaces when hitting a TAB/BACKSPACE
set shiftround      " round indent to multiple of 'shiftwidth'
set autoindent      " align the new line indent with the previous line
set number          " turn on line numbering - maybe make this .py specific?
set encoding=utf-8  " does what it says on the tin


""""""""""""""""" COLORS """""""""""""""""""""""""""""""""""""""""""""
set background=dark
set t_Co=256

" airline theme
let g:airline_theme='badwolf'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
