""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"         __   _____ __  __ ___  ___                     " 
"  ------ \ \ / /_ _|  \/  | _ \/ __| ---------          "
" -------- \ V / | || |\/| |   / (__  --------------     "
"  -------- \_/ |___|_|  |_|_|_\\___| -----------------  " 
"                                                        "
"""""""""""""""" Nvim tweaks  """"""""""""""""""""""""""""""""""

:set noshowcmd noruler

"""""""""""""""" Nerdtree stuff  """"""""""""""""""""""""""""""""""

let mapleader = " "
map <Leader>n :NERDTreeToggle<CR>

let NERDTreeShowHidden=1


""""""""""""""""NORMAL MODE HACKS """"""""""""""""""""""""""""""""""

" enter adds blank line below cursor, does not enter insert mode
map <Enter> o<ESC>
" shift-enter adds blank line above cursor, does not enter insert
map <S-Enter> O<esc>

imap jk <ESC>

" deal with annoyance of accidental macros
" Q records macro now
nnoremap Q q
" just q does nothing
nnoremap q <Nop>

" shut up W
:command W w

" why suffer?
nnoremap ; :

" cnoremap :record @
" nnoremap @ <nop>

" copy path of file
command CopyPath let @*=expand("%")

" make vim shell in same env as bash
set shell=bash\ -l

" make delete act normal
set backspace=2

" use system clipboard
set clipboard=unnamed

" ! bundle exec rspec %
" run spec from in spec file
nnoremap ,. :!bundle exec rspec %<CR>

" NERDTreeFind shortcut
nmap ,m :NERDTreeFind<CR>

""""""""""""""""" PILBO PLUGGINS """"""""""""""""""""""""""""""""""""
" Vim Plug 
call plug#begin('~/.vim/pluggins') "

" go linting and stuff
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

" live markdown previw!
" Plug 'skywind3000/asyncrun.vim'

" syntax highlighting for python
" Plug '~/.vim/pluggins/python.vim'

" Terraform syntax
Plug 'hashivim/vim-terraform'

" Linting
Plug 'w0rp/ale'

Plug 'bling/vim-airline'
" Plug 'vim-airline/vim-airline-themes'

" toggle with space-n
Plug 'scrooloose/nerdtree'

" git - :Gstatus :Gdiff :Glog :Ggrep etc
Plug 'tpope/vim-fugitive'

" rails
" Plug 'tpope/vim-rails'

" surround (with {} as example surrounder)
" ysiw} - surround word {ysiw( for spaces)
" yss} - surround line
" cs({ - replace surroundings (old surround, new surround)
" ds{ - delete surroundings
" visual select then S{
" https://github.com/tpope/vim-surround
Plug 'tpope/vim-surround'

" percent takes you to matching end etc.
Plug 'tmhedberg/matchit'

" make chruby work with vim
Plug 'mikepjb/vim-chruby'

" fuzzy search in vim
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'
nnoremap <Leader>t :FZF<CR>

" draw ascii boxes
" space-d-i to start
" space-d-s to stop
" Plug 'vim-scripts/DrawIt'

call plug#end()

"""""""""""""""""""""""""""""""""""""""""""""""
" Remove trailing whitespace before save
" --------------------------------------------------
"
" Add filetypes to have vim auto-strip trailing whitespace, in some languages
" (like markdown) this is undesirable.

let stripEolFiletypes = [
\ "c",
\ "handlebars",
\ "html",
\ "html.handlebars",
\ "javascript",
\ "ruby",
\ "rust",
\ "yaml",
\]

execute "autocmd FileType " . join(stripEolFiletypes, ",") . " autocmd BufWritePre <buffer> :%s/\\s\\+$//e"

"""""""""""""""" RANDO """""""""""""""""""""""""""""""

nmap <c-p> :GFiles <CR>

set wildmenu wildmode=longest:full
set wildignorecase
set wildignore+=*.o,*.out,*.obj,.git,*.rbc,*.rbo,*.class,.svn,*.gem          
set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz                      
set wildignore+=*/vendor/gems/*,*/vendor/cache/*,*/.bundle/*,*/.sass-cache/* 
set wildignore+=*/node_modules/*
set wildignore+=*.swp,*~,._*

set complete=.,w,b,u,t
set noswapfile

""""""""""""""""" SYNTAX STUFF """"""""""""""""""""""""""""""""

" line length and indent (for python) (from hitchhiker's, adjusted to google style guide)
" google style: 80 lines, 4 space indent, 
syntax on           " turn on syntax highlighting
" set textwidth=80    " lines longer than 80 columns will be broken
set shiftwidth=2    " operation >> indents 2 columns; << unindents 2 columns
set tabstop=2       " a hard TAB displays as 2 columns
set expandtab       " insert spaces when hitting TABs
set softtabstop=2   " insert/delete 2 spaces when hitting a TAB/BACKSPACE
set shiftround      " round indent to multiple of 'shiftwidth'
set autoindent      " align the new line indent with the previous line
" set number relativenumber        " turn on line numbering 
set number
set encoding=utf-8  " does what it says on the tin


""""""""""""""""" COLORS """""""""""""""""""""""""""""""""""""""""""""
set background=light
set t_Co=256

" airline theme
" let g:airline_theme='badwolf'


"""""""""""""""""" THE END """""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
